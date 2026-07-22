<?php

namespace App\Services;

use App\Models\OtpVerification;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    public const REGISTER = 'register';
    public const PASSWORD_RESET = 'password_reset';
    public const MOBILE_RECHARGE = 'mobile_recharge';
    public const BILL_PAYMENT = 'bill_payment';
    public const BANK_TRANSFER = 'bank_transfer';
    public const DRIVE_OFFER = 'drive_offer';

    public function issue(string $email, string $purpose, array $payload = []): void
    {
        $code = (string) random_int(100000, 999999);

        OtpVerification::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->delete();

        OtpVerification::query()->create([
            'email' => $email,
            'purpose' => $purpose,
            'code_hash' => Hash::make($code),
            'payload' => $payload,
            'expires_at' => now()->addMinutes(10),
        ]);

        $subject = match ($purpose) {
            self::REGISTER => 'Your account verification OTP',
            self::MOBILE_RECHARGE => 'Confirm your mobile recharge',
            self::BILL_PAYMENT => 'Confirm your bill payment',
            self::BANK_TRANSFER => 'Confirm your bank transfer',
            self::DRIVE_OFFER => 'Confirm your internet offer',
            default => 'Your password reset OTP',
        };

        if (in_array($purpose, [self::MOBILE_RECHARGE, self::BILL_PAYMENT, self::BANK_TRANSFER, self::DRIVE_OFFER], true)) {
            Log::info('Transaction OTP issued.', [
                'email' => $email,
                'purpose' => $purpose,
                'otp' => $code,
                'mobile_number' => $payload['mobile_number'] ?? null,
                'operator' => $payload['operator'] ?? null,
                'category' => $payload['category'] ?? null,
                'provider' => $payload['provider'] ?? null,
                'account_number' => $payload['account_number'] ?? null,
                'bank_name' => $payload['bank_name'] ?? null,
                'offer_title' => $payload['offer_title'] ?? null,
                'amount' => $payload['amount'] ?? null,
                'total_amount' => $payload['total_amount'] ?? null,
            ]);
        }

        Mail::send('emails.otp', [
            'code' => $code,
            'purpose' => $purpose,
            'title' => $subject,
            'expiresIn' => '10 minutes',
        ], function ($message) use ($email, $subject): void {
            $message->to($email)->subject($subject);
        });
    }

    public function verify(string $email, string $purpose, string $code): ?OtpVerification
    {
        $verification = OtpVerification::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->latest()
            ->first();

        if (! $verification || $verification->expires_at->isPast()) {
            return null;
        }

        if (! Hash::check($code, $verification->code_hash)) {
            return null;
        }

        $verification->forceFill([
            'verified_at' => now(),
        ])->save();

        return $verification;
    }
}
