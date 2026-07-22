<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriveOffer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DriveOfferController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'operator' => ['nullable', Rule::in($this->operators())],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
        ]);

        $baseQuery = DriveOffer::query();

        $offers = DriveOffer::query()
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('title', 'like', "%{$search}%")
                        ->orWhere('operator', 'like', "%{$search}%")
                        ->orWhere('data_amount', 'like', "%{$search}%")
                        ->orWhere('activation_code', 'like', "%{$search}%");
                });
            })
            ->when($filters['operator'] ?? null, fn ($query, string $operator) => $query->where('operator', $operator))
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('is_active', $status === 'active'))
            ->orderBy('sort_order')
            ->latest()
            ->paginate(12);

        return response()->json([
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'active' => (clone $baseQuery)->where('is_active', true)->count(),
                'featured' => (clone $baseQuery)->where('is_featured', true)->count(),
                'operators' => (clone $baseQuery)->distinct('operator')->count('operator'),
            ],
            'operators' => $this->operators(),
            'offers' => $offers,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $offer = DriveOffer::query()->create($this->validatedOfferData($request));

        return response()->json([
            'message' => 'Drive offer created successfully.',
            'offer' => $offer,
        ], 201);
    }

    public function update(Request $request, DriveOffer $driveOffer): JsonResponse
    {
        $driveOffer->update($this->validatedOfferData($request));

        return response()->json([
            'message' => 'Drive offer updated successfully.',
            'offer' => $driveOffer->fresh(),
        ]);
    }

    public function destroy(DriveOffer $driveOffer): JsonResponse
    {
        $driveOffer->delete();

        return response()->json([
            'message' => 'Drive offer deleted successfully.',
        ]);
    }

    private function validatedOfferData(Request $request): array
    {
        return $request->validate([
            'operator' => ['required', Rule::in($this->operators())],
            'title' => ['required', 'string', 'max:160'],
            'offer_type' => ['required', Rule::in(['internet', 'bundle', 'social', 'unlimited'])],
            'data_amount' => ['nullable', 'string', 'max:60'],
            'minutes' => ['nullable', 'string', 'max:60'],
            'sms' => ['nullable', 'string', 'max:60'],
            'validity' => ['required', 'string', 'max:60'],
            'price' => ['required', 'numeric', 'min:1', 'max:50000'],
            'service_charge' => ['nullable', 'numeric', 'min:0', 'max:5000'],
            'activation_code' => ['nullable', 'string', 'max:80'],
            'source_note' => ['nullable', 'string', 'max:160'],
            'description' => ['nullable', 'string', 'max:2000'],
            'is_featured' => ['boolean'],
            'is_active' => ['boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:999999'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
        ]);
    }

    private function operators(): array
    {
        return ['Grameenphone', 'Robi', 'Airtel', 'Banglalink', 'Teletalk'];
    }
}
