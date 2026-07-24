<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MobileRecharge;
use App\Services\TransactionStatusNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class MobileRechargeController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
            'operator' => ['nullable', Rule::in($this->operators())],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $baseQuery = MobileRecharge::query();

        $recharges = MobileRecharge::query()
            ->with(['user:id,name,email,phone', 'reviewer:id,name,email'])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('transaction_id', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('mobile_number', 'like', "%{$search}%")
                        ->orWhere('operator', 'like', "%{$search}%");
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
                'refunded' => (clone $baseQuery)->where('status', 'refunded')->count(),
                'volume' => (float) (clone $baseQuery)->sum('amount'),
            ],
            'operators' => $this->operators(),
            'statuses' => $this->statuses(),
            'recharges' => $recharges,
        ]);
    }

    public function show(MobileRecharge $recharge): JsonResponse
    {
        return response()->json([
            'recharge' => $recharge->load(['user:id,name,email,phone,address', 'reviewer:id,name,email']),
        ]);
    }

    public function update(Request $request, MobileRecharge $recharge, TransactionStatusNotificationService $notifier): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'mobile_number' => ['required', 'digits:11'],
            'operator' => ['required', Rule::in($this->operators())],
            'amount' => ['required', 'numeric', 'min:10', 'max:50000'],
            'charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'status' => ['required', Rule::in($this->statuses())],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $previousStatus = $recharge->status;
        $data['charge'] = $data['charge'] ?? $recharge->charge ?? 0;
        $data['total_amount'] = (float) $data['amount'] + (float) $data['charge'];
        $data['reviewed_by'] = $request->user()?->id;

        DB::transaction(function () use ($recharge, $data, $previousStatus): void {
            if ($data['status'] === 'successful' && ! $recharge->debited_at) {
                $user = $recharge->user()->lockForUpdate()->first();

                if (! $user || (float) $user->balance < (float) $data['total_amount']) {
                    throw ValidationException::withMessages([
                        'balance' => 'User has insufficient balance.',
                    ]);
                }

                $user->decrement('balance', (float) $data['total_amount']);
                $data['debited_at'] = now();
            }

            if (
                $recharge->debited_at &&
                ! in_array($previousStatus, ['refunded', 'failed', 'rejected', 'cancelled'], true) &&
                in_array($data['status'], ['refunded', 'failed', 'rejected', 'cancelled'], true)
            ) {
                $recharge->user()?->increment('balance', (float) ($recharge->total_amount ?: $recharge->amount));
            }

            if (in_array($data['status'], ['successful', 'failed', 'rejected', 'refunded', 'cancelled'], true) && ! $recharge->processed_at) {
                $data['processed_at'] = now();
            }

            $recharge->update($data);
        });

        $fresh = $recharge->fresh()->load(['user:id,name,email,phone', 'reviewer:id,name,email']);
        $notifier->mobileRecharge($fresh, $previousStatus);

        return response()->json([
            'message' => 'Recharge transaction updated successfully.',
            'recharge' => $fresh,
        ]);
    }

    private function operators(): array
    {
        return ['Grameenphone', 'Robi', 'Banglalink', 'Airtel', 'Teletalk'];
    }

    private function statuses(): array
    {
        return ['pending', 'processing', 'successful', 'failed', 'rejected', 'refunded', 'cancelled'];
    }
}
