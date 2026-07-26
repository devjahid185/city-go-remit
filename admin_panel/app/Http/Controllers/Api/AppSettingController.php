<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\AppServiceSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AppSettingController extends Controller
{
    public function show(AppServiceSettings $serviceSettings): JsonResponse
    {
        return response()->json([
            'message' => 'App settings loaded successfully.',
            'settings' => [
                'youtube_url' => AppSetting::value('youtube_url', ''),
                'telegram_url' => AppSetting::value('telegram_url', ''),
                'home_popup_enabled' => AppSetting::bool('home_popup_enabled', true),
                'home_popup_title' => AppSetting::value('home_popup_title', 'Welcome to City Go Remit'),
                'home_popup_body' => AppSetting::value('home_popup_body', 'Manage payments, transfers and account services securely from one place.'),
                'home_popup_button_text' => AppSetting::value('home_popup_button_text', 'Continue'),
                'home_popup_image_url' => AppSetting::value('home_popup_image_path')
                    ? route('api.settings.home-popup-image', ['v' => AppSetting::value('home_popup_image_updated_at', time())])
                    : '',
                ...$serviceSettings->publicSettings(),
            ],
        ]);
    }

    public function homePopupImage(): StreamedResponse|JsonResponse
    {
        $path = AppSetting::value('home_popup_image_path');

        if (! $path || ! Storage::disk('public')->exists($path)) {
            return response()->json(['message' => 'Popup image was not found.'], 404);
        }

        return Storage::disk('public')->response($path);
    }
}
