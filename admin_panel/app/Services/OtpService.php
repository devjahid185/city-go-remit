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
    public const WALLET_WITHDRAWAL = 'wallet_withdrawal';
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

        $mail = $this->mailContent($purpose, $payload);
        $subject = $mail['subject'];

        if (in_array($purpose, [self::MOBILE_RECHARGE, self::BILL_PAYMENT, self::BANK_TRANSFER, self::WALLET_WITHDRAWAL, self::DRIVE_OFFER], true)) {
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
                'wallet_provider' => $payload['wallet_provider'] ?? null,
                'wallet_number' => $payload['wallet_number'] ?? null,
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
            'heading' => $mail['heading'],
            'intro' => $mail['intro'],
            'accent' => $mail['accent'],
            'badge' => $mail['badge'],
            'details' => $mail['details'],
            'footerNote' => $mail['footerNote'],
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

    private function mailContent(string $purpose, array $payload): array
    {
        return match ($purpose) {
            self::REGISTER => [
                'subject' => 'Verify your City Go Remit account',
                'heading' => 'Verify your new account',
                'intro' => 'Use this one-time password to complete your City Go Remit account registration.',
                'accent' => '#00503a',
                'badge' => 'Account Verification',
                'details' => [],
                'footerNote' => 'If you did not request a new account, you can safely ignore this email.',
            ],
            self::PASSWORD_RESET => [
                'subject' => 'Reset your City Go Remit password',
                'heading' => 'Reset your password safely',
                'intro' => 'Use this one-time password to reset your City Go Remit account password.',
                'accent' => '#7c2d12',
                'badge' => 'Password Reset',
                'details' => [],
                'footerNote' => 'If you did not request a password reset, please keep your account secure and ignore this email.',
            ],
            self::MOBILE_RECHARGE => [
                'subject' => 'Confirm your mobile recharge',
                'heading' => 'Confirm mobile recharge',
                'intro' => 'Use this OTP to approve your mobile recharge request.',
                'accent' => '#0f766e',
                'badge' => 'Recharge Confirmation',
                'details' => $this->details([
                    'Operator' => $payload['operator'] ?? null,
                    'Mobile Number' => $payload['mobile_number'] ?? null,
                    'Amount' => $this->money($payload['amount'] ?? null),
                    'Charge' => $this->money($payload['charge'] ?? null),
                    'Total' => $this->money($payload['total_amount'] ?? $payload['amount'] ?? null),
                ]),
                'footerNote' => 'If you did not start this recharge, do not share this code with anyone.',
            ],
            self::BILL_PAYMENT => [
                'subject' => 'Confirm your bill payment',
                'heading' => 'Confirm bill payment',
                'intro' => 'Use this OTP to approve your bill payment request.',
                'accent' => '#1d4ed8',
                'badge' => 'Bill Payment Confirmation',
                'details' => $this->details([
                    'Provider' => $payload['provider'] ?? null,
                    'Bill Type' => $payload['bill_type'] ?? null,
                    'Account Number' => $payload['account_number'] ?? null,
                    'Billing Period' => $payload['billing_period'] ?? null,
                    'Amount' => $this->money($payload['amount'] ?? null),
                    'Total' => $this->money($payload['total_amount'] ?? $payload['amount'] ?? null),
                ]),
                'footerNote' => 'If you did not start this bill payment, do not share this code with anyone.',
            ],
            self::BANK_TRANSFER => [
                'subject' => 'Confirm your bank transfer',
                'heading' => 'Confirm bank transfer',
                'intro' => 'Use this OTP to approve your bank transfer request.',
                'accent' => '#4338ca',
                'badge' => 'Bank Transfer Confirmation',
                'details' => $this->details([
                    'Bank' => $payload['bank_name'] ?? null,
                    'Account Name' => $payload['account_name'] ?? null,
                    'Account Number' => $payload['account_number'] ?? null,
                    'Amount' => $this->money($payload['amount'] ?? null),
                    'Charge' => $this->money($payload['charge'] ?? null),
                    'Total' => $this->money($payload['total_amount'] ?? $payload['amount'] ?? null),
                ]),
                'footerNote' => 'If you did not start this bank transfer, do not share this code with anyone.',
            ],
            self::WALLET_WITHDRAWAL => [
                'subject' => 'Confirm your wallet withdrawal',
                'heading' => 'Confirm wallet withdrawal',
                'intro' => 'Use this OTP to approve your wallet withdrawal request.',
                'accent' => '#be123c',
                'badge' => 'Wallet Withdrawal Confirmation',
                'details' => $this->details([
                    'Wallet' => $payload['wallet_provider'] ?? null,
                    'Wallet Number' => $payload['wallet_number'] ?? null,
                    'Amount' => $this->money($payload['amount'] ?? null),
                    'Charge' => $this->money($payload['charge'] ?? null),
                    'Total' => $this->money($payload['total_amount'] ?? $payload['amount'] ?? null),
                ]),
                'footerNote' => 'If you did not start this wallet withdrawal, do not share this code with anyone.',
            ],
            self::DRIVE_OFFER => [
                'subject' => 'Confirm your internet offer',
                'heading' => 'Confirm internet offer purchase',
                'intro' => 'Use this OTP to approve your internet offer purchase.',
                'accent' => '#0369a1',
                'badge' => 'Internet Offer Confirmation',
                'details' => $this->details([
                    'Offer' => $payload['offer_title'] ?? null,
                    'Operator' => $payload['operator'] ?? null,
                    'Mobile Number' => $payload['mobile_number'] ?? null,
                    'Package Price' => $this->money($payload['price'] ?? null),
                    'Service Charge' => $this->money($payload['service_charge'] ?? null),
                    'Total' => $this->money($payload['total_amount'] ?? $payload['price'] ?? null),
                ]),
                'footerNote' => 'If you did not start this internet offer purchase, do not share this code with anyone.',
            ],
            default => [
                'subject' => 'Your City Go Remit verification code',
                'heading' => 'Confirm your request',
                'intro' => 'Use this one-time password to continue your request.',
                'accent' => '#00503a',
                'badge' => 'Security Verification',
                'details' => [],
                'footerNote' => 'If you did not request this code, you can safely ignore this email.',
            ],
        };
    }

    private function details(array $items): array
    {
        return collect($items)
            ->filter(fn ($value) => $value !== null && trim((string) $value) !== '')
            ->all();
    }

    private function money(mixed $amount): ?string
    {
        if ($amount === null || $amount === '') {
            return null;
        }

        return 'BDT '.number_format((float) $amount, 2);
    }
}
