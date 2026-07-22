<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BankTransfer;
use App\Services\TransactionStatusNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class BankTransferController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
        ]);

        $baseQuery = BankTransfer::query();

        $transfers = BankTransfer::query()
            ->with(['user:id,name,email,phone', 'reviewer:id,name,email'])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('transaction_id', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('bank_name', 'like', "%{$search}%")
                        ->orWhere('account_name', 'like', "%{$search}%")
                        ->orWhere('account_number', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
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
            'bank_transfers' => $transfers,
        ]);
    }

    public function update(Request $request, BankTransfer $bankTransfer, TransactionStatusNotificationService $notifier): JsonResponse
    {
        $data = $request->validate([
            'bank_name' => ['required', 'string', 'max:120'],
            'branch_name' => ['nullable', 'string', 'max:120'],
            'account_name' => ['required', 'string', 'max:120'],
            'account_number' => ['required', 'string', 'min:6', 'max:30'],
            'routing_number' => ['nullable', 'string', 'max:20'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:100', 'max:500000'],
            'charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'status' => ['required', Rule::in($this->statuses())],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $previousStatus = $bankTransfer->status;
        $data['charge'] = $data['charge'] ?? $bankTransfer->charge;
        $data['total_amount'] = (float) $data['amount'] + (float) $data['charge'];
        $data['reviewed_by'] = $request->user()?->id;

        DB::transaction(function () use ($bankTransfer, $data, $previousStatus): void {
            if (
                $bankTransfer->debited_at &&
                ! in_array($previousStatus, ['refunded', 'failed', 'rejected', 'cancelled'], true) &&
                in_array($data['status'], ['refunded', 'failed', 'rejected', 'cancelled'], true)
            ) {
                $bankTransfer->user()?->increment('balance', (float) $bankTransfer->total_amount);
            }

            if (in_array($data['status'], ['successful', 'failed', 'rejected', 'refunded', 'cancelled'], true) && ! $bankTransfer->processed_at) {
                $data['processed_at'] = now();
            }

            $bankTransfer->update($data);
        });

        $fresh = $bankTransfer->fresh()->load(['user:id,name,email,phone', 'reviewer:id,name,email']);
        $notifier->bankTransfer($fresh, $previousStatus);

        return response()->json([
            'message' => 'Bank transfer updated successfully.',
            'bank_transfer' => $fresh,
        ]);
    }

    private function statuses(): array
    {
        return ['pending', 'processing', 'successful', 'failed', 'rejected', 'refunded', 'cancelled'];
    }
}
