<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankTransfer;
use App\Models\OtpVerification;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class BankTransferController extends Controller
{
    public function requestOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedTransferData($request);
        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $data['charge'] = $this->calculateCharge((float) $data['amount']);
        $data['total_amount'] = (float) $data['amount'] + $data['charge'];

        if ((float) $user->balance < (float) $data['total_amount']) {
            return response()->json([
                'message' => 'Insufficient balance for this bank transfer.',
                'balance' => $user->balance,
                'required_amount' => $data['total_amount'],
            ], 422);
        }

        $otpService->issue($user->email, OtpService::BANK_TRANSFER, $data);

        return response()->json([
            'message' => 'A bank transfer confirmation OTP has been sent to your email.',
            'charge' => $data['charge'],
            'total_amount' => $data['total_amount'],
        ]);
    }

    public function confirm(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedTransferData($request);
        $otpData = $request->validate(['otp' => ['required', 'digits:6']]);

        $verification = $otpService->verify($data['email'], OtpService::BANK_TRANSFER, $otpData['otp']);

        if (! $verification) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $payload = $verification->payload ?? [];
        foreach (['bank_name', 'account_name', 'account_number', 'amount'] as $field) {
            if ((string) ($payload[$field] ?? '') !== (string) ($data[$field] ?? '')) {
                return response()->json(['message' => 'Bank transfer details do not match the OTP request.'], 422);
            }
        }

        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $transfer = DB::transaction(function () use ($payload, $user): BankTransfer {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (! $lockedUser || (float) $lockedUser->balance < (float) $payload['total_amount']) {
                throw ValidationException::withMessages([
                    'balance' => 'Insufficient balance for this bank transfer.',
                ]);
            }

            $lockedUser->decrement('balance', (float) $payload['total_amount']);

            return BankTransfer::query()->create([
                ...$payload,
                'user_id' => $lockedUser->id,
                'email' => $lockedUser->email,
                'transaction_id' => 'BT'.now()->format('ymdHis').Str::upper(Str::random(6)),
                'status' => 'pending',
                'debited_at' => now(),
            ]);
        });

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Bank transfer request submitted successfully and is waiting for admin processing.',
            'bank_transfer' => $this->payload($transfer),
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        $items = BankTransfer::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(30)
            ->get()
            ->map(fn (BankTransfer $transfer): array => $this->payload($transfer));

        return response()->json([
            'message' => 'Bank transfer history loaded.',
            'bank_transfers' => $items,
        ]);
    }

    private function validatedTransferData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'bank_name' => ['required', Rule::in($this->banks())],
            'branch_name' => ['nullable', 'string', 'max:120'],
            'account_name' => ['required', 'string', 'max:120'],
            'account_number' => ['required', 'string', 'min:6', 'max:30'],
            'routing_number' => ['nullable', 'string', 'max:20'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:100', 'max:500000'],
        ]);
    }

    private function activeUser(string $email): ?User
    {
        return User::query()
            ->where('email', $email)
            ->where('status', 'active')
            ->first();
    }

    private function calculateCharge(float $amount): float
    {
        return min(round($amount * 0.005, 2), 50);
    }

    private function payload(BankTransfer $transfer): array
    {
        return [
            'transaction_id' => $transfer->transaction_id,
            'bank_name' => $transfer->bank_name,
            'branch_name' => $transfer->branch_name,
            'account_name' => $transfer->account_name,
            'account_number' => $transfer->account_number,
            'routing_number' => $transfer->routing_number,
            'contact_number' => $transfer->contact_number,
            'amount' => $transfer->amount,
            'charge' => $transfer->charge,
            'total_amount' => $transfer->total_amount,
            'status' => $transfer->status,
            'processed_at' => $transfer->processed_at?->toISOString(),
        ];
    }

    private function banks(): array
    {
        return [
            'AB Bank',
            'Agrani Bank',
            'Al-Arafah Islami Bank',
            'Bangladesh Commerce Bank',
            'Bangladesh Development Bank',
            'Bangladesh Krishi Bank',
            'Bank Asia',
            'BASIC Bank',
            'Bengal Commercial Bank',
            'Bank Alfalah',
            'BRAC Bank',
            'Citizens Bank',
            'City Bank',
            'Commercial Bank of Ceylon',
            'Community Bank Bangladesh',
            'Dhaka Bank',
            'Dutch-Bangla Bank',
            'Eastern Bank',
            'EXIM Bank',
            'First Security Islami Bank',
            'Habib Bank',
            'ICB Islamic Bank',
            'IFIC Bank',
            'Islami Bank Bangladesh',
            'Jamuna Bank',
            'Janata Bank',
            'Meghna Bank',
            'Mercantile Bank',
            'Midland Bank',
            'Modhumoti Bank',
            'Mutual Trust Bank',
            'National Bank',
            'National Bank of Pakistan',
            'NCC Bank',
            'NRB Bank',
            'NRB Commercial Bank',
            'NRB Global Bank',
            'One Bank',
            'Padma Bank',
            'Premier Bank',
            'Prime Bank',
            'Probashi Kallyan Bank',
            'Pubali Bank',
            'Rajshahi Krishi Unnayan Bank',
            'Rupali Bank',
            'Shahjalal Islami Bank',
            'Shimanto Bank',
            'Social Islami Bank',
            'Sonali Bank',
            'South Bangla Agriculture and Commerce Bank',
            'Southeast Bank',
            'Standard Bank',
            'Standard Chartered Bank',
            'State Bank of India',
            'The Hongkong and Shanghai Banking Corporation',
            'Trust Bank',
            'UCB',
            'Union Bank',
            'Uttara Bank',
            'Woori Bank',
        ];
    }
}
