<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppNotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        $notifications = AppNotification::query()
            ->where('email', $data['email'])
            ->latest()
            ->paginate(30);

        return response()->json([
            'message' => 'Notifications loaded successfully.',
            'unread_count' => AppNotification::query()->where('email', $data['email'])->whereNull('read_at')->count(),
            'notifications' => $notifications,
        ]);
    }

    public function markRead(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'notification_id' => ['nullable', 'integer', 'exists:app_notifications,id'],
        ]);

        AppNotification::query()
            ->where('email', $data['email'])
            ->when($data['notification_id'] ?? null, fn ($query, int $id) => $query->whereKey($id))
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Notifications marked as read.']);
    }
}
