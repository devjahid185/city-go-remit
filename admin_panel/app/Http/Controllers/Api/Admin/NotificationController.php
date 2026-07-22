<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\FirebaseDeviceToken;
use App\Models\User;
use App\Services\FirebaseMessagingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationController extends Controller
{
    public function index(): JsonResponse
    {
        $users = User::query()
            ->where('is_admin', false)
            ->withCount(['firebaseDeviceTokens as active_device_tokens_count' => fn ($query) => $query->where('is_active', true)])
            ->orderBy('name')
            ->limit(100)
            ->get(['id', 'name', 'email', 'phone', 'status']);

        return response()->json([
            'message' => 'Notification dashboard loaded.',
            'stats' => [
                'active_devices' => FirebaseDeviceToken::query()->where('is_active', true)->count(),
                'android_devices' => FirebaseDeviceToken::query()->where('is_active', true)->where('platform', 'android')->count(),
                'users_with_devices' => FirebaseDeviceToken::query()->where('is_active', true)->distinct('user_id')->count('user_id'),
            ],
            'users' => $users,
        ]);
    }

    public function send(Request $request, FirebaseMessagingService $messaging): JsonResponse
    {
        $data = $request->validate([
            'audience' => ['required', Rule::in(['all', 'user'])],
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'title' => ['required', 'string', 'max:120'],
            'body' => ['required', 'string', 'max:500'],
            'action_type' => ['nullable', 'string', 'max:50'],
            'action_value' => ['nullable', 'string', 'max:255'],
        ]);

        if ($data['audience'] === 'user' && empty($data['user_id'])) {
            return response()->json(['message' => 'Please select a user.'], 422);
        }

        $query = FirebaseDeviceToken::query()->where('is_active', true);

        if ($data['audience'] === 'user') {
            $query->where('user_id', $data['user_id']);
        }

        $tokens = $query->pluck('token');
        $result = $messaging->sendToTokens($tokens, $data['title'], $data['body'], [
            'action_type' => $data['action_type'] ?? 'none',
            'action_value' => $data['action_value'] ?? '',
        ]);

        $users = $data['audience'] === 'user'
            ? User::query()->whereKey($data['user_id'])->get(['id', 'email'])
            : User::query()->where('is_admin', false)->where('status', 'active')->get(['id', 'email']);

        foreach ($users as $user) {
            AppNotification::query()->create([
                'user_id' => $user->id,
                'email' => $user->email,
                'title' => $data['title'],
                'body' => $data['body'],
                'type' => 'admin_broadcast',
                'data' => [
                    'action_type' => $data['action_type'] ?? 'none',
                    'action_value' => $data['action_value'] ?? '',
                ],
            ]);
        }

        return response()->json([
            'message' => 'Notification sending completed.',
            'result' => [
                ...$result,
                'targeted_devices' => $tokens->count(),
            ],
        ]);
    }
}
