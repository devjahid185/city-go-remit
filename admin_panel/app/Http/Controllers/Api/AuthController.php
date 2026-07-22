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

        return response()->json([
            'message' => 'Profile loaded successfully.',
            'user' => $this->userPayload($user),
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
            'email' => $user->email,
            'phone' => $user->phone,
            'address' => $user->address,
            'status' => $user->status,
            'balance' => $user->balance,
            'referral_code' => $user->referral_code,
            'referral_bonus_earned' => $user->referral_bonus_earned,
        ];
    }
}
