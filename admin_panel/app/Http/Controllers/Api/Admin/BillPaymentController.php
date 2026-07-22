<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BillPayment;
use App\Services\TransactionStatusNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class BillPaymentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
            'category' => ['nullable', Rule::in($this->categories())],
        ]);

        $baseQuery = BillPayment::query();

        $payments = BillPayment::query()
            ->with(['user:id,name,email,phone', 'reviewer:id,name,email'])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('transaction_id', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('provider', 'like', "%{$search}%")
                        ->orWhere('account_number', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when($filters['category'] ?? null, fn ($query, string $category) => $query->where('category', $category))
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
            'categories' => $this->categories(),
            'statuses' => $this->statuses(),
            'bill_payments' => $payments,
        ]);
    }

    public function update(Request $request, BillPayment $billPayment, TransactionStatusNotificationService $notifier): JsonResponse
    {
        $data = $request->validate([
            'category' => ['required', Rule::in($this->categories())],
            'provider' => ['required', 'string', 'max:120'],
            'bill_type' => ['nullable', 'string', 'max:80'],
            'account_number' => ['required', 'string', 'max:80'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'billing_period' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:10', 'max:500000'],
            'charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'status' => ['required', Rule::in($this->statuses())],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $previousStatus = $billPayment->status;
        $data['charge'] = $data['charge'] ?? $billPayment->charge;
        $data['total_amount'] = (float) $data['amount'] + (float) $data['charge'];
        $data['reviewed_by'] = $request->user()?->id;

        DB::transaction(function () use ($billPayment, $data, $previousStatus): void {
            if ($data['status'] === 'successful' && ! $billPayment->debited_at) {
                $user = $billPayment->user()->lockForUpdate()->first();

                if (! $user || (float) $user->balance < (float) $data['total_amount']) {
                    throw ValidationException::withMessages([
                        'balance' => 'User has insufficient balance.',
                    ]);
                }

                $user->decrement('balance', (float) $data['total_amount']);
                $data['debited_at'] = now();
            }

            if (
                $billPayment->debited_at &&
                ! in_array($previousStatus, ['refunded', 'failed', 'rejected', 'cancelled'], true) &&
                in_array($data['status'], ['refunded', 'failed', 'rejected', 'cancelled'], true)
            ) {
                $billPayment->user()?->increment('balance', (float) $billPayment->total_amount);
            }

            if (in_array($data['status'], ['successful', 'failed', 'rejected', 'refunded', 'cancelled'], true) && ! $billPayment->processed_at) {
                $data['processed_at'] = now();
            }

            $billPayment->update($data);
        });

        $fresh = $billPayment->fresh()->load(['user:id,name,email,phone', 'reviewer:id,name,email']);
        $notifier->billPayment($fresh, $previousStatus);

        return response()->json([
            'message' => 'Bill payment updated successfully.',
            'bill_payment' => $fresh,
        ]);
    }

    private function categories(): array
    {
        return ['electricity', 'gas', 'water', 'internet', 'telephone', 'tv', 'credit_card', 'education', 'insurance', 'government', 'loan', 'donation'];
    }

    private function statuses(): array
    {
        return ['pending', 'processing', 'successful', 'failed', 'rejected', 'refunded', 'cancelled'];
    }
}
