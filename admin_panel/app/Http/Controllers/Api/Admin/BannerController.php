<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppBanner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class BannerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
        ]);

        $baseQuery = AppBanner::query();

        $banners = AppBanner::query()
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('title', 'like', "%{$search}%")
                        ->orWhere('subtitle', 'like', "%{$search}%")
                        ->orWhere('action_value', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('is_active', $status === 'active'))
            ->orderBy('sort_order')
            ->latest()
            ->paginate(12);

        return response()->json([
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'active' => (clone $baseQuery)->where('is_active', true)->count(),
                'inactive' => (clone $baseQuery)->where('is_active', false)->count(),
            ],
            'banners' => $banners->through(fn (AppBanner $banner): array => $this->payload($banner)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validatedData($request);
        $data['image_path'] = $request->file('image')->store('banners', 'public');

        $banner = AppBanner::query()->create($data);

        return response()->json([
            'message' => 'Banner created successfully.',
            'banner' => $this->payload($banner),
        ], 201);
    }

    public function update(Request $request, AppBanner $banner): JsonResponse
    {
        $data = $this->validatedData($request, updating: true);

        if ($request->hasFile('image')) {
            Storage::disk('public')->delete($banner->image_path);
            $data['image_path'] = $request->file('image')->store('banners', 'public');
        }

        $banner->update($data);

        return response()->json([
            'message' => 'Banner updated successfully.',
            'banner' => $this->payload($banner->fresh()),
        ]);
    }

    public function destroy(AppBanner $banner): JsonResponse
    {
        Storage::disk('public')->delete($banner->image_path);
        $banner->delete();

        return response()->json([
            'message' => 'Banner deleted successfully.',
        ]);
    }

    private function validatedData(Request $request, bool $updating = false): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:120'],
            'subtitle' => ['nullable', 'string', 'max:180'],
            'button_text' => ['nullable', 'string', 'max:40'],
            'action_type' => ['required', Rule::in(['none', 'service', 'url'])],
            'action_value' => ['nullable', 'string', 'max:255'],
            'is_active' => ['required', 'boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:999999'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
            'image' => [$updating ? 'nullable' : 'required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096', 'dimensions:width=960,height=320'],
        ]);
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
            'is_active' => $banner->is_active,
            'sort_order' => $banner->sort_order,
            'starts_at' => $banner->starts_at?->toISOString(),
            'ends_at' => $banner->ends_at?->toISOString(),
            'image_url' => route('api.banners.image', $banner),
            'created_at' => $banner->created_at?->toISOString(),
        ];
    }
}
