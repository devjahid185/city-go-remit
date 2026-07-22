<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OtpVerification;
use App\Models\MobileRecharge;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class MobileRechargeController extends Controller
{
    public function requestOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedRechargeData($request);

        $user = User::query()
            ->where('email', $data['email'])
            ->where('status', 'active')
            ->first();

        if (! $user) {
            return response()->json([
                'message' => 'Active user account was not found.',
            ], 422);
        }

        if ((float) $user->balance < (float) $data['amount']) {
            return response()->json([
                'message' => 'Insufficient balance for this recharge.',
                'balance' => $user->balance,
                'required_amount' => $data['amount'],
            ], 422);
        }

        $otpService->issue($user->email, OtpService::MOBILE_RECHARGE, $data);

        return response()->json([
            'message' => 'A recharge confirmation OTP has been sent to your email.',
        ]);
    }

    public function confirm(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedRechargeData($request);
        $otpData = $request->validate([
            'otp' => ['required', 'digits:6'],
        ]);

        $verification = $otpService->verify($data['email'], OtpService::MOBILE_RECHARGE, $otpData['otp']);

        if (! $verification) {
            return response()->json([
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        $payload = $verification->payload ?? [];

        if (
            ($payload['mobile_number'] ?? null) !== $data['mobile_number'] ||
            ($payload['operator'] ?? null) !== $data['operator'] ||
            (string) ($payload['amount'] ?? '') !== (string) $data['amount']
        ) {
            return response()->json([
                'message' => 'Recharge details do not match the OTP request.',
            ], 422);
        }

        $user = User::query()
            ->where('email', $data['email'])
            ->where('status', 'active')
            ->first();

        if (! $user) {
            return response()->json([
                'message' => 'Active user account was not found.',
            ], 422);
        }

        $recharge = DB::transaction(function () use ($user, $data): MobileRecharge {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (! $lockedUser || (float) $lockedUser->balance < (float) $data['amount']) {
                abort(response()->json([
                    'message' => 'Insufficient balance for this recharge.',
                    'balance' => $lockedUser?->balance ?? 0,
                    'required_amount' => $data['amount'],
                ], 422));
            }

            $lockedUser->decrement('balance', (float) $data['amount']);

            return MobileRecharge::query()->create([
                'user_id' => $lockedUser->id,
                'email' => $lockedUser->email,
                'mobile_number' => $data['mobile_number'],
                'operator' => $data['operator'],
                'amount' => $data['amount'],
                'transaction_id' => 'MR'.now()->format('ymdHis').Str::upper(Str::random(6)),
                'status' => 'pending',
                'debited_at' => now(),
                'processed_at' => null,
            ]);
        });

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Mobile recharge request submitted successfully and is waiting for admin approval.',
            'recharge' => [
                'transaction_id' => $recharge->transaction_id,
                'mobile_number' => $recharge->mobile_number,
                'operator' => $recharge->operator,
                'amount' => $recharge->amount,
                'status' => $recharge->status,
                'processed_at' => $recharge->processed_at?->toISOString(),
            ],
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $items = MobileRecharge::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(20)
            ->get()
            ->map(fn (MobileRecharge $recharge): array => [
                'transaction_id' => $recharge->transaction_id,
                'mobile_number' => $recharge->mobile_number,
                'operator' => $recharge->operator,
                'amount' => $recharge->amount,
                'status' => $recharge->status,
                'processed_at' => $recharge->processed_at?->toISOString(),
            ]);

        return response()->json([
            'message' => 'Recharge history loaded.',
            'recharges' => $items,
        ]);
    }

    private function validatedRechargeData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'mobile_number' => ['required', 'digits:11'],
            'operator' => ['required', 'string', Rule::in(['Grameenphone', 'Robi', 'Banglalink', 'Airtel', 'Teletalk'])],
            'amount' => ['required', 'numeric', 'min:10', 'max:50000'],
        ]);
    }
}
