<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\AppServiceSettings;
use Illuminate\Http\JsonResponse;

class AppSettingController extends Controller
{
    public function show(AppServiceSettings $serviceSettings): JsonResponse
    {
        return response()->json([
            'message' => 'App settings loaded successfully.',
            'settings' => [
                'youtube_url' => AppSetting::value('youtube_url', ''),
                'telegram_url' => AppSetting::value('telegram_url', ''),
                ...$serviceSettings->publicSettings(),
            ],
        ]);
    }
}
