<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BillPayment;
use App\Models\OtpVerification;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class BillPaymentController extends Controller
{
    public function requestOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedBillData($request);
        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $data['charge'] = $this->calculateCharge($data['category'], (float) $data['amount']);
        $data['total_amount'] = (float) $data['amount'] + $data['charge'];

        if ((float) $user->balance < (float) $data['total_amount']) {
            return response()->json([
                'message' => 'Insufficient balance for this bill payment.',
                'balance' => $user->balance,
                'required_amount' => $data['total_amount'],
            ], 422);
        }

        $otpService->issue($user->email, OtpService::BILL_PAYMENT, $data);

        return response()->json([
            'message' => 'A bill payment confirmation OTP has been sent to your email.',
            'charge' => $data['charge'],
            'total_amount' => $data['total_amount'],
        ]);
    }

    public function confirm(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedBillData($request);
        $otpData = $request->validate(['otp' => ['required', 'digits:6']]);

        $verification = $otpService->verify($data['email'], OtpService::BILL_PAYMENT, $otpData['otp']);

        if (! $verification) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $payload = $verification->payload ?? [];
        foreach (['category', 'provider', 'account_number', 'amount'] as $field) {
            if ((string) ($payload[$field] ?? '') !== (string) ($data[$field] ?? '')) {
                return response()->json(['message' => 'Bill details do not match the OTP request.'], 422);
            }
        }

        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $bill = DB::transaction(function () use ($payload, $user): BillPayment {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (! $lockedUser || (float) $lockedUser->balance < (float) $payload['total_amount']) {
                abort(response()->json([
                    'message' => 'Insufficient balance for this bill payment.',
                    'balance' => $lockedUser?->balance ?? 0,
                    'required_amount' => $payload['total_amount'],
                ], 422));
            }

            $lockedUser->decrement('balance', (float) $payload['total_amount']);

            return BillPayment::query()->create([
                ...$payload,
                'user_id' => $lockedUser->id,
                'email' => $lockedUser->email,
                'transaction_id' => 'BP'.now()->format('ymdHis').Str::upper(Str::random(6)),
                'status' => 'pending',
                'debited_at' => now(),
            ]);
        });

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Bill payment request submitted successfully and is waiting for admin approval.',
            'bill_payment' => $this->payload($bill),
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        $items = BillPayment::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(30)
            ->get()
            ->map(fn (BillPayment $bill): array => $this->payload($bill));

        return response()->json([
            'message' => 'Bill payment history loaded.',
            'bill_payments' => $items,
        ]);
    }

    private function validatedBillData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'category' => ['required', Rule::in($this->categories())],
            'provider' => ['required', 'string', 'max:120'],
            'bill_type' => ['nullable', 'string', 'max:80'],
            'account_number' => ['required', 'string', 'max:80'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'billing_period' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:10', 'max:500000'],
        ]);
    }

    private function activeUser(string $email): ?User
    {
        return User::query()
            ->where('email', $email)
            ->where('status', 'active')
            ->first();
    }

    private function calculateCharge(string $category, float $amount): float
    {
        if (in_array($category, ['internet', 'tv', 'education', 'donation'], true)) {
            return 0;
        }

        return min(round($amount * 0.01, 2), 30);
    }

    private function categories(): array
    {
        return ['electricity', 'gas', 'water', 'internet', 'telephone', 'tv', 'credit_card', 'education', 'insurance', 'government', 'loan', 'donation'];
    }

    private function payload(BillPayment $bill): array
    {
        return [
            'transaction_id' => $bill->transaction_id,
            'category' => $bill->category,
            'provider' => $bill->provider,
            'bill_type' => $bill->bill_type,
            'account_number' => $bill->account_number,
            'amount' => $bill->amount,
            'charge' => $bill->charge,
            'total_amount' => $bill->total_amount,
            'status' => $bill->status,
            'processed_at' => $bill->processed_at?->toISOString(),
        ];
    }
}
