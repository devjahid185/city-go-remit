<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriveOfferOrder;
use App\Services\TransactionStatusNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DriveOfferOrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
            'operator' => ['nullable', 'string', 'max:40'],
        ]);

        $baseQuery = DriveOfferOrder::query();

        $orders = DriveOfferOrder::query()
            ->with(['user:id,name,email,phone,balance', 'reviewer:id,name,email', 'offer:id,title'])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('transaction_id', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('mobile_number', 'like', "%{$search}%")
                        ->orWhere('offer_title', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when($filters['operator'] ?? null, fn ($query, string $operator) => $query->where('operator', $operator))
            ->latest()
            ->paginate(12);

        return response()->json([
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'successful' => (clone $baseQuery)->where('status', 'successful')->count(),
                'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
                'failed' => (clone $baseQuery)->where('status', 'failed')->count(),
                'volume' => (float) (clone $baseQuery)->sum('total_amount'),
            ],
            'statuses' => $this->statuses(),
            'orders' => $orders,
        ]);
    }

    public function update(Request $request, DriveOfferOrder $driveOfferOrder, TransactionStatusNotificationService $notifier): JsonResponse
    {
        $data = $request->validate([
            'mobile_number' => ['required', 'digits:11'],
            'operator' => ['required', 'string', 'max:40'],
            'offer_title' => ['required', 'string', 'max:160'],
            'data_amount' => ['nullable', 'string', 'max:60'],
            'validity' => ['required', 'string', 'max:60'],
            'price' => ['required', 'numeric', 'min:1', 'max:50000'],
            'service_charge' => ['nullable', 'numeric', 'min:0', 'max:5000'],
            'status' => ['required', Rule::in($this->statuses())],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $previousStatus = $driveOfferOrder->status;
        $data['service_charge'] = $data['service_charge'] ?? $driveOfferOrder->service_charge;
        $data['total_amount'] = (float) $data['price'] + (float) $data['service_charge'];
        $data['reviewed_by'] = $request->user()?->id;

        DB::transaction(function () use ($driveOfferOrder, $data, $previousStatus): void {
            if (
                $driveOfferOrder->debited_at &&
                ! in_array($previousStatus, ['refunded', 'failed', 'rejected', 'cancelled'], true) &&
                in_array($data['status'], ['refunded', 'failed', 'rejected', 'cancelled'], true)
            ) {
                $driveOfferOrder->user()?->increment('balance', (float) $driveOfferOrder->total_amount);
            }

            if (in_array($data['status'], ['successful', 'failed', 'rejected', 'refunded', 'cancelled'], true) && ! $driveOfferOrder->processed_at) {
                $data['processed_at'] = now();
            }

            $driveOfferOrder->update($data);
        });

        $fresh = $driveOfferOrder->fresh()->load(['user:id,name,email,phone,balance', 'reviewer:id,name,email', 'offer:id,title']);
        $notifier->driveOffer($fresh, $previousStatus);

        return response()->json([
            'message' => 'Drive offer order updated successfully.',
            'order' => $fresh,
        ]);
    }

    private function statuses(): array
    {
        return ['pending', 'processing', 'successful', 'failed', 'rejected', 'refunded', 'cancelled'];
    }
}
