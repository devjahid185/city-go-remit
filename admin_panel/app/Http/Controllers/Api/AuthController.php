<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceLoginLog;
use App\Models\OtpVerification;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'platform' => ['nullable', 'string', 'max:40'],
            'location' => ['nullable', 'string', 'max:120'],
        ]);

        $user = User::query()
            ->where('email', $credentials['email'])
            ->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            return response()->json([
                'message' => 'Invalid email or password.',
            ], 422);
        }

        if ($user->isBanned()) {
            return response()->json([
                'message' => 'Your account has been banned. Please contact support.',
                'account_banned' => true,
            ], 403);
        }

        if ($user->status !== 'active') {
            return response()->json([
                'message' => 'Your account is not active yet.',
            ], 403);
        }

        $user->forceFill([
            'last_seen_at' => now(),
        ])->save();

        DeviceLoginLog::query()->create([
            'user_id' => $user->id,
            'email' => $user->email,
            'device_name' => $credentials['device_name'] ?? null,
            'platform' => $credentials['platform'] ?? null,
            'ip_address' => $request->ip(),
            'location' => $credentials['location'] ?? null,
            'logged_in_at' => now(),
        ]);

        return response()->json([
            'message' => 'Login successful.',
            'user' => $this->userPayload($user),
        ]);
    }

    public function profile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::query()
            ->where('email', $data['email'])
            ->first();

        if (! $user) {
            return response()->json([
                'message' => 'User account was not found.',
            ], 404);
        }

        if ($user->isBanned()) {
            return response()->json([
                'message' => 'Your account has been banned. Please contact support.',
                'account_banned' => true,
            ], 403);
        }

        return response()->json([
            'message' => 'Profile loaded successfully.',
            'user' => $this->userPayload($user),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_email' => ['required', 'email'],
            'email' => ['required', 'email', 'max:255'],
            'first_name' => ['nullable', 'string', 'max:100'],
            'last_name' => ['nullable', 'string', 'max:100'],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'father_name' => ['nullable', 'string', 'max:255'],
            'mother_name' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
            'country_name' => ['nullable', 'string', 'max:120'],
            'country_code' => ['nullable', 'string', 'max:12'],
            'country_flag' => ['nullable', 'string', 'max:12'],
            'government_document_name' => ['nullable', 'string', 'max:255'],
            'government_document' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf,webp', 'max:5120'],
        ]);

        $user = User::query()->where('email', $data['current_email'])->first();

        if (! $user) {
            return response()->json([
                'message' => 'User account was not found.',
            ], 404);
        }

        if ($user->isBanned()) {
            return response()->json([
                'message' => 'Your account has been banned. Please contact support.',
                'account_banned' => true,
            ], 403);
        }

        if (User::query()
            ->where('email', $data['email'])
            ->whereKeyNot($user->id)
            ->exists()) {
            return response()->json([
                'message' => 'This email is already used by another account.',
            ], 422);
        }

        $documentPath = $request->hasFile('government_document')
            ? $request->file('government_document')->store('kyc-documents', 'public')
            : null;

        $firstName = trim((string) ($data['first_name'] ?? ''));
        $lastName = trim((string) ($data['last_name'] ?? ''));
        $name = trim($firstName.' '.$lastName) ?: $user->name;

        $payload = [
            'name' => $name,
            'first_name' => $firstName ?: null,
            'last_name' => $lastName ?: null,
            'date_of_birth' => $data['date_of_birth'] ?? null,
            'father_name' => $data['father_name'] ?? null,
            'mother_name' => $data['mother_name'] ?? null,
            'email' => strtolower($data['email']),
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'country_name' => $data['country_name'] ?? null,
            'country_code' => $data['country_code'] ?? null,
            'country_flag' => $data['country_flag'] ?? null,
            'government_document_name' => $data['government_document_name'] ?? $user->government_document_name,
        ];

        if ($documentPath) {
            $payload['government_document_path'] = $documentPath;
            $payload['government_document_name'] = $request->file('government_document')?->getClientOriginalName()
                ?: $payload['government_document_name'];
        }

        $user->forceFill($payload)->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    public function googleLogin(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'platform' => ['nullable', 'string', 'max:40'],
            'location' => ['nullable', 'string', 'max:120'],
        ]);

        $googleUser = $this->verifiedGoogleUser($data['id_token']);

        if (! $googleUser) {
            return response()->json([
                'message' => 'Google sign-in could not be verified.',
            ], 422);
        }

        $user = User::query()
            ->where('email', $googleUser['email'])
            ->orWhere('google_id', $googleUser['google_id'])
            ->first();

        if ($user?->isBanned()) {
            return response()->json([
                'message' => 'Your account has been banned. Please contact support.',
                'account_banned' => true,
            ], 403);
        }

        if ($user && $user->status !== 'active') {
            return response()->json([
                'message' => 'Your account is not active yet.',
            ], 403);
        }

        if (! $user) {
            $user = User::query()->create([
                'name' => $googleUser['name'],
                'first_name' => $googleUser['first_name'],
                'last_name' => $googleUser['last_name'],
                'email' => $googleUser['email'],
                'google_id' => $googleUser['google_id'],
                'google_avatar' => $googleUser['avatar'],
                'auth_provider' => 'google',
                'password' => Hash::make(Str::password(32)),
                'is_admin' => false,
                'status' => 'active',
                'referral_code' => $this->newReferralCode(),
                'last_seen_at' => now(),
                'email_verified_at' => now(),
            ]);
        } else {
            $user->forceFill([
                'google_id' => $user->google_id ?: $googleUser['google_id'],
                'google_avatar' => $googleUser['avatar'] ?: $user->google_avatar,
                'auth_provider' => $user->auth_provider === 'email' ? 'google' : $user->auth_provider,
                'email_verified_at' => $user->email_verified_at ?: now(),
                'last_seen_at' => now(),
            ])->save();
        }

        $this->logDeviceLogin($user, $request, $data);

        return response()->json([
            'message' => 'Google login successful.',
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    public function forgotPassword(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        if (User::query()->where('email', $data['email'])->exists()) {
            $otpService->issue($data['email'], OtpService::PASSWORD_RESET);
        }

        return response()->json([
            'message' => 'If this email exists, an OTP has been sent.',
        ]);
    }

    public function resetPasswordWithOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'digits:6'],
            'password' => ['required', 'string', 'confirmed'],
        ]);

        $verification = $otpService->verify($data['email'], OtpService::PASSWORD_RESET, $data['otp']);

        if (! $verification) {
            return response()->json([
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user) {
            return response()->json([
                'message' => 'Invalid or expired OTP.',
            ], 422);
        }

        $user->forceFill([
            'password' => Hash::make($data['password']),
            'status' => 'active',
        ])->save();

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Password reset successfully.',
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'confirmed'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $user->forceFill([
            'password' => Hash::make($data['password']),
        ])->save();

        return response()->json([
            'message' => 'Password changed successfully.',
        ]);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'date_of_birth' => $user->date_of_birth?->format('Y-m-d'),
            'father_name' => $user->father_name,
            'mother_name' => $user->mother_name,
            'email' => $user->email,
            'phone' => $user->phone,
            'address' => $user->address,
            'country_name' => $user->country_name,
            'country_code' => $user->country_code,
            'country_flag' => $user->country_flag,
            'government_document_name' => $user->government_document_name,
            'government_document_uploaded' => $user->government_document_path !== null,
            'auth_provider' => $user->auth_provider,
            'google_avatar' => $user->google_avatar,
            'status' => $user->status,
            'chat_banned' => $user->isChatBanned(),
            'ban_reason' => $user->ban_reason,
            'balance' => $user->balance,
            'referral_code' => $user->referral_code,
            'referral_bonus_earned' => $user->referral_bonus_earned,
        ];
    }

    private function verifiedGoogleUser(string $idToken): ?array
    {
        try {
            $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $idToken,
            ]);
        } catch (\Throwable) {
            return null;
        }

        if (! $response->ok()) {
            return null;
        }

        $payload = $response->json();
        $email = strtolower((string) ($payload['email'] ?? ''));
        $googleId = (string) ($payload['sub'] ?? '');
        $configuredClientId = config('services.google.client_id');

        if (! $configuredClientId) {
            return null;
        }

        if (! filter_var($email, FILTER_VALIDATE_EMAIL) || $googleId === '') {
            return null;
        }

        if (($payload['email_verified'] ?? null) !== 'true' && ($payload['email_verified'] ?? null) !== true) {
            return null;
        }

        if (($payload['aud'] ?? null) !== $configuredClientId) {
            return null;
        }

        $name = trim((string) ($payload['name'] ?? ''));
        $firstName = trim((string) ($payload['given_name'] ?? ''));
        $lastName = trim((string) ($payload['family_name'] ?? ''));

        if ($name === '') {
            $name = trim($firstName.' '.$lastName) ?: Str::before($email, '@');
        }

        return [
            'google_id' => $googleId,
            'email' => $email,
            'name' => $name,
            'first_name' => $firstName ?: Str::before($name, ' '),
            'last_name' => $lastName,
            'avatar' => (string) ($payload['picture'] ?? ''),
        ];
    }

    private function logDeviceLogin(User $user, Request $request, array $data): void
    {
        DeviceLoginLog::query()->create([
            'user_id' => $user->id,
            'email' => $user->email,
            'device_name' => $data['device_name'] ?? null,
            'platform' => $data['platform'] ?? null,
            'ip_address' => $request->ip(),
            'location' => $data['location'] ?? null,
            'logged_in_at' => now(),
        ]);
    }

    private function newReferralCode(): string
    {
        do {
            $code = 'CGR'.Str::upper(Str::random(8));
        } while (User::query()->where('referral_code', $code)->exists());

        return $code;
    }
}
