<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\FirebaseDeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', Rule::in(['android', 'ios', 'web', 'unknown'])],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $admin = $request->user();

        FirebaseDeviceToken::query()->updateOrCreate([
            'token' => $data['token'],
        ], [
            'user_id' => $admin?->id,
            'email' => $admin?->email,
            'platform' => $data['platform'] ?? 'unknown',
            'device_name' => $data['device_name'] ?? 'Admin Chat App',
            'is_active' => true,
            'last_used_at' => now(),
        ]);

        return response()->json(['message' => 'Notification device registered successfully.']);
    }

    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        FirebaseDeviceToken::query()
            ->where('token', $data['token'])
            ->where('user_id', $request->user()?->id)
            ->update(['is_active' => false]);

        return response()->json(['message' => 'Notification device removed successfully.']);
    }
}
