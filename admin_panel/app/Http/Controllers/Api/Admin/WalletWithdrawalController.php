<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\WalletWithdrawal;
use App\Services\TransactionStatusNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class WalletWithdrawalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
            'wallet_provider' => ['nullable', Rule::in(['bKash', 'Nagad', 'Rocket'])],
        ]);

        $baseQuery = WalletWithdrawal::query();

        $withdrawals = WalletWithdrawal::query()
            ->with(['user:id,name,email,phone', 'reviewer:id,name,email'])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('transaction_id', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('wallet_provider', 'like', "%{$search}%")
                        ->orWhere('wallet_number', 'like', "%{$search}%")
                        ->orWhere('account_name', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when($filters['wallet_provider'] ?? null, fn ($query, string $provider) => $query->where('wallet_provider', $provider))
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
            'providers' => ['bKash', 'Nagad', 'Rocket'],
            'wallet_withdrawals' => $withdrawals,
        ]);
    }

    public function update(Request $request, WalletWithdrawal $walletWithdrawal, TransactionStatusNotificationService $notifier): JsonResponse
    {
        $data = $request->validate([
            'wallet_provider' => ['required', Rule::in(['bKash', 'Nagad', 'Rocket'])],
            'wallet_number' => ['required', 'regex:/^01[0-9]{9}$/'],
            'account_name' => ['nullable', 'string', 'max:120'],
            'contact_number' => ['nullable', 'string', 'max:30'],
            'amount' => ['required', 'numeric', 'min:50', 'max:500000'],
            'charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'status' => ['required', Rule::in($this->statuses())],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $previousStatus = $walletWithdrawal->status;
        $data['charge'] = $data['charge'] ?? $walletWithdrawal->charge;
        $data['total_amount'] = (float) $data['amount'] + (float) $data['charge'];
        $data['reviewed_by'] = $request->user()?->id;

        DB::transaction(function () use ($walletWithdrawal, $data, $previousStatus): void {
            if (
                $walletWithdrawal->debited_at &&
                ! in_array($previousStatus, ['refunded', 'failed', 'rejected', 'cancelled'], true) &&
                in_array($data['status'], ['refunded', 'failed', 'rejected', 'cancelled'], true)
            ) {
                $walletWithdrawal->user()?->increment('balance', (float) $walletWithdrawal->total_amount);
            }

            if (in_array($data['status'], ['successful', 'failed', 'rejected', 'refunded', 'cancelled'], true) && ! $walletWithdrawal->processed_at) {
                $data['processed_at'] = now();
            }

            $walletWithdrawal->update($data);
        });

        $fresh = $walletWithdrawal->fresh()->load(['user:id,name,email,phone', 'reviewer:id,name,email']);
        $notifier->walletWithdrawal($fresh, $previousStatus);

        return response()->json([
            'message' => 'Wallet withdrawal updated successfully.',
            'wallet_withdrawal' => $fresh,
        ]);
    }

    private function statuses(): array
    {
        return ['pending', 'processing', 'successful', 'failed', 'rejected', 'refunded', 'cancelled'];
    }
}
