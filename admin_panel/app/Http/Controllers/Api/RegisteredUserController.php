<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\AppSetting;
use App\Models\OtpVerification;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class RegisteredUserController extends Controller
{
    public function __invoke(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:30'],
            'password' => ['required', 'string', 'confirmed'],
            'address' => ['nullable', 'string', 'max:255'],
            'referral_code' => ['nullable', 'string', 'max:30'],
        ]);

        $referrer = $this->referrer($data['referral_code'] ?? null);
        $otpService->issue($data['email'], OtpService::REGISTER, [
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'password' => Hash::make($data['password']),
            'is_admin' => false,
            'status' => 'active',
            'referral_code' => $this->newReferralCode(),
            'referred_by_user_id' => $referrer?->id,
        ]);

        return response()->json([
            'message' => 'OTP sent to your email. Verify OTP to create account.',
            'email' => $data['email'],
        ]);
    }

    public function kycRegister(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'first_name' => ['required', 'string', 'max:100'],
            'last_name' => ['required', 'string', 'max:100'],
            'date_of_birth' => ['required', 'date', 'before:today'],
            'father_name' => ['required', 'string', 'max:255'],
            'mother_name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
            'country_name' => ['required', 'string', 'max:120'],
            'country_code' => ['required', 'string', 'max:12'],
            'country_flag' => ['nullable', 'string', 'max:12'],
            'government_document_name' => ['required_without:government_document', 'nullable', 'string', 'max:255'],
            'government_document' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf,webp', 'max:5120'],
            'password' => ['required', 'string', 'confirmed'],
            'source' => ['nullable', Rule::in(['google', 'email'])],
            'referral_code' => ['nullable', 'string', 'max:30'],
        ]);

        $documentPath = $request->hasFile('government_document')
            ? $request->file('government_document')->store('kyc-documents', 'public')
            : null;

        $referrer = $this->referrer($data['referral_code'] ?? null);
        $user = User::query()->create([
            'name' => trim($data['first_name'].' '.$data['last_name']),
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'date_of_birth' => $data['date_of_birth'],
            'father_name' => $data['father_name'],
            'mother_name' => $data['mother_name'],
            'email' => $data['email'],
            'phone' => $data['country_code'].$data['phone'],
            'address' => $data['address'] ?? null,
            'country_name' => $data['country_name'],
            'country_code' => $data['country_code'],
            'country_flag' => $data['country_flag'] ?? null,
            'government_document_name' => $data['government_document_name']
                ?? $request->file('government_document')?->getClientOriginalName(),
            'government_document_path' => $documentPath,
            'password' => Hash::make($data['password']),
            'is_admin' => false,
            'status' => 'active',
            'referral_code' => $this->newReferralCode(),
            'referred_by_user_id' => $referrer?->id,
            'last_seen_at' => now(),
            'email_verified_at' => now(),
        ]);

        $this->applyReferralBonus($user, $referrer);
        $user = $user->fresh();

        Mail::send('emails.registration-success', [
            'user' => $user,
        ], function ($message) use ($user): void {
            $message->to($user->email)->subject('Welcome to City Go Remit');
        });

        return response()->json([
            'message' => 'Congratulations! Your account has been created successfully.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,
                'country_name' => $user->country_name,
                'country_code' => $user->country_code,
                'country_flag' => $user->country_flag,
                'status' => $user->status,
                'balance' => $user->balance,
                'referral_code' => $user->referral_code,
                'referral_bonus_earned' => $user->referral_bonus_earned,
            ],
        ], 201);
    }

    public function verifyOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'digits:6'],
        ]);

        if (User::query()->where('email', $data['email'])->exists()) {
            return response()->json([
                'message' => 'An account already exists with this email.',
            ], 422);
        }

        $verification = $otpService->verify($data['email'], OtpService::REGISTER, $data['otp']);

        if (! $verification) {
            return response()->json([
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        $payload = $verification->payload ?? [];

        $user = User::query()->create([
            ...$payload,
            'last_seen_at' => now(),
            'email_verified_at' => now(),
        ]);

        $this->applyReferralBonus($user, $user->referredBy);
        $user = $user->fresh();

        OtpVerification::query()->whereKey($verification->id)->delete();

        Mail::send('emails.registration-success', [
            'user' => $user,
        ], function ($message) use ($user): void {
            $message->to($user->email)->subject('Welcome to City Go Remit');
        });

        return response()->json([
            'message' => 'Account verified and created successfully.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'address' => $user->address,
                'status' => $user->status,
                'balance' => $user->balance,
                'referral_code' => $user->referral_code,
            ],
        ], 201);
    }

    private function referrer(?string $code): ?User
    {
        if (! $code || AppSetting::value('referral_enabled', '1') !== '1') {
            return null;
        }

        return User::query()->where('referral_code', Str::upper(trim($code)))->where('is_admin', false)->first();
    }

    private function newReferralCode(): string
    {
        do {
            $code = 'CGR'.Str::upper(Str::random(8));
        } while (User::query()->where('referral_code', $code)->exists());

        return $code;
    }

    private function applyReferralBonus(User $user, ?User $referrer): void
    {
        if (! $referrer || AppSetting::value('referral_enabled', '1') !== '1') {
            return;
        }

        $referrerBonus = (float) AppSetting::value('referral_referrer_bonus', 25);
        $newUserBonus = (float) AppSetting::value('referral_new_user_bonus', 10);

        if ($newUserBonus > 0) {
            $user->increment('balance', $newUserBonus);
            $user->increment('referral_bonus_earned', $newUserBonus);
            AppNotification::query()->create([
                'user_id' => $user->id,
                'email' => $user->email,
                'title' => 'Referral Bonus Added',
                'body' => 'Welcome bonus BDT '.number_format($newUserBonus, 2).' has been added to your wallet.',
                'type' => 'referral',
                'data' => ['amount' => $newUserBonus],
            ]);
        }

        if ($referrerBonus > 0) {
            $referrer->increment('balance', $referrerBonus);
            $referrer->increment('referral_bonus_earned', $referrerBonus);
            AppNotification::query()->create([
                'user_id' => $referrer->id,
                'email' => $referrer->email,
                'title' => 'Referral Reward Added',
                'body' => 'You earned BDT '.number_format($referrerBonus, 2).' for inviting '.$user->name.'.',
                'type' => 'referral',
                'data' => ['amount' => $referrerBonus, 'referred_user_id' => $user->id],
            ]);
        }
    }
}
