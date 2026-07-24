<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OtpVerification;
use App\Models\User;
use App\Models\WalletWithdrawal;
use App\Services\AppServiceSettings;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class WalletWithdrawalController extends Controller
{
    public function requestOtp(Request $request, OtpService $otpService, AppServiceSettings $settings): JsonResponse
    {
        $data = $this->validatedWithdrawalData($request);

        if ($settings->maintenanceEnabled()) {
            return response()->json(['message' => 'City Go Remit is under maintenance. Please try again later.'], 503);
        }

        if (! $settings->serviceEnabled(AppServiceSettings::WALLET_WITHDRAWAL)) {
            return response()->json(['message' => 'Wallet withdrawal is temporarily unavailable.'], 422);
        }

        if ($message = $settings->amountLimitMessage(AppServiceSettings::WALLET_WITHDRAWAL, (float) $data['amount'])) {
            return response()->json(['message' => $message], 422);
        }

        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $data['charge'] = $settings->charge(AppServiceSettings::WALLET_WITHDRAWAL);
        $data['total_amount'] = (float) $data['amount'] + $data['charge'];

        if ((float) $user->balance < (float) $data['total_amount']) {
            return response()->json([
                'message' => 'Insufficient balance for this wallet withdrawal.',
                'balance' => $user->balance,
                'required_amount' => $data['total_amount'],
            ], 422);
        }

        $otpService->issue($user->email, OtpService::WALLET_WITHDRAWAL, $data);

        return response()->json([
            'message' => 'A wallet withdrawal confirmation OTP has been sent to your email.',
            'charge' => $data['charge'],
            'total_amount' => $data['total_amount'],
        ]);
    }

    public function confirm(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedWithdrawalData($request);
        $otpData = $request->validate(['otp' => ['required', 'digits:6']]);

        $verification = $otpService->verify($data['email'], OtpService::WALLET_WITHDRAWAL, $otpData['otp']);

        if (! $verification) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $payload = $verification->payload ?? [];
        foreach (['wallet_provider', 'wallet_number', 'amount'] as $field) {
            if ((string) ($payload[$field] ?? '') !== (string) ($data[$field] ?? '')) {
                return response()->json(['message' => 'Wallet withdrawal details do not match the OTP request.'], 422);
            }
        }

        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $withdrawal = DB::transaction(function () use ($payload, $user): WalletWithdrawal {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (! $lockedUser || (float) $lockedUser->balance < (float) $payload['total_amount']) {
                throw ValidationException::withMessages([
                    'balance' => 'Insufficient balance for this wallet withdrawal.',
                ]);
            }

            $lockedUser->decrement('balance', (float) $payload['total_amount']);

            return WalletWithdrawal::query()->create([
                ...$payload,
                'user_id' => $lockedUser->id,
                'email' => $lockedUser->email,
                'transaction_id' => 'WW'.now()->format('ymdHis').Str::upper(Str::random(6)),
                'status' => 'pending',
                'debited_at' => now(),
            ]);
        });

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Wallet withdrawal request submitted successfully and is waiting for admin processing.',
            'wallet_withdrawal' => $this->payload($withdrawal),
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        $items = WalletWithdrawal::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(30)
            ->get()
            ->map(fn (WalletWithdrawal $withdrawal): array => $this->payload($withdrawal));

        return response()->json([
            'message' => 'Wallet withdrawal history loaded.',
            'wallet_withdrawals' => $items,
        ]);
    }

    private function validatedWithdrawalData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'wallet_provider' => ['required', Rule::in($this->providers())],
            'wallet_number' => ['required', 'regex:/^01[0-9]{9}$/'],
            'account_name' => ['nullable', 'string', 'max:120'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:0.01', 'max:999999999'],
        ]);
    }

    private function activeUser(string $email): ?User
    {
        return User::query()
            ->where('email', $email)
            ->where('status', 'active')
            ->first();
    }

    private function payload(WalletWithdrawal $withdrawal): array
    {
        return [
            'transaction_id' => $withdrawal->transaction_id,
            'wallet_provider' => $withdrawal->wallet_provider,
            'wallet_number' => $withdrawal->wallet_number,
            'account_name' => $withdrawal->account_name,
            'contact_number' => $withdrawal->contact_number,
            'amount' => $withdrawal->amount,
            'charge' => $withdrawal->charge,
            'total_amount' => $withdrawal->total_amount,
            'status' => $withdrawal->status,
            'processed_at' => $withdrawal->processed_at?->toISOString(),
        ];
    }

    private function providers(): array
    {
        return ['bKash', 'Nagad', 'Rocket'];
    }
}
