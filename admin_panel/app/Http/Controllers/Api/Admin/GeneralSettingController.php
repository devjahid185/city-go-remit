<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GeneralSettingController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'message' => 'General settings loaded successfully.',
            'settings' => $this->settings(),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'youtube_url' => ['nullable', 'url', 'max:500'],
            'telegram_url' => ['nullable', 'url', 'max:500'],
        ]);

        AppSetting::put('youtube_url', $data['youtube_url'] ?? '');
        AppSetting::put('telegram_url', $data['telegram_url'] ?? '');

        return response()->json([
            'message' => 'General settings updated successfully.',
            'settings' => $this->settings(),
        ]);
    }

    private function settings(): array
    {
        return [
            'youtube_url' => AppSetting::value('youtube_url', ''),
            'telegram_url' => AppSetting::value('telegram_url', ''),
        ];
    }
}
