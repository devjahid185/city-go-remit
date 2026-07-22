<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppBanner;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class BannerController extends Controller
{
    public function index(): JsonResponse
    {
        $banners = AppBanner::query()
            ->where('is_active', true)
            ->where(function ($query): void {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query): void {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            })
            ->orderBy('sort_order')
            ->latest()
            ->limit(10)
            ->get()
            ->map(fn (AppBanner $banner): array => $this->payload($banner))
            ->values();

        return response()->json([
            'message' => 'Banners loaded successfully.',
            'banners' => $banners,
        ]);
    }

    public function image(AppBanner $banner)
    {
        if (! Storage::disk('public')->exists($banner->image_path)) {
            abort(404);
        }

        return Storage::disk('public')->response($banner->image_path);
    }

    private function payload(AppBanner $banner): array
    {
        return [
            'id' => $banner->id,
            'title' => $banner->title,
            'subtitle' => $banner->subtitle,
            'button_text' => $banner->button_text,
            'action_type' => $banner->action_type,
            'action_value' => $banner->action_value,
            'image_url' => route('api.banners.image', $banner),
        ];
    }
}
