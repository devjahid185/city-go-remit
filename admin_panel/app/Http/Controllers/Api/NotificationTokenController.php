<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FirebaseDeviceToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', Rule::in(['android', 'ios', 'web', 'unknown'])],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        $deviceToken = FirebaseDeviceToken::query()->updateOrCreate([
            'token' => $data['token'],
        ], [
            'user_id' => $user?->id,
            'email' => $data['email'],
            'platform' => $data['platform'] ?? 'unknown',
            'device_name' => $data['device_name'] ?? null,
            'is_active' => true,
            'last_used_at' => now(),
        ]);

        return response()->json([
            'message' => 'Notification device registered successfully.',
            'device_token_id' => $deviceToken->id,
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        FirebaseDeviceToken::query()
            ->where('token', $data['token'])
            ->update(['is_active' => false]);

        return response()->json([
            'message' => 'Notification device removed successfully.',
        ]);
    }
}
