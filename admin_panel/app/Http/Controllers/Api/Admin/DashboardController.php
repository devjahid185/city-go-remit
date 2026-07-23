<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppBanner;
use App\Models\AppNotification;
use App\Models\BankTransfer;
use App\Models\BillPayment;
use App\Models\ChatConversation;
use App\Models\DriveOfferOrder;
use App\Models\FirebaseDeviceToken;
use App\Models\MobileRecharge;
use App\Models\User;
use App\Models\WalletWithdrawal;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $hasRecharges = Schema::hasTable('mobile_recharges');
        $hasBills = Schema::hasTable('bill_payments');
        $hasBankTransfers = Schema::hasTable('bank_transfers');
        $hasWalletWithdrawals = Schema::hasTable('wallet_withdrawals');
        $hasDriveOrders = Schema::hasTable('drive_offer_orders');
        $hasChats = Schema::hasTable('chat_conversations');
        $hasBanners = Schema::hasTable('app_banners');
        $hasNotifications = Schema::hasTable('app_notifications');
        $hasTokens = Schema::hasTable('firebase_device_tokens');

        $transactionCollections = collect([
            $hasRecharges ? $this->transactionSummary(MobileRecharge::query(), 'amount') : null,
            $hasBills ? $this->transactionSummary(BillPayment::query(), 'total_amount') : null,
            $hasBankTransfers ? $this->transactionSummary(BankTransfer::query(), 'total_amount') : null,
            $hasWalletWithdrawals ? $this->transactionSummary(WalletWithdrawal::query(), 'total_amount') : null,
            $hasDriveOrders ? $this->transactionSummary(DriveOfferOrder::query(), 'total_amount') : null,
        ])->filter();

        $totalTransactions = (int) $transactionCollections->sum('total');
        $pendingTransactions = (int) $transactionCollections->sum('pending');
        $successfulTransactions = (int) $transactionCollections->sum('successful');
        $failedTransactions = (int) $transactionCollections->sum('failed');
        $totalVolume = (float) $transactionCollections->sum('volume');

        return response()->json([
            'stats' => [
                'users' => User::query()->where('is_admin', false)->count(),
                'active_users' => User::query()->where('is_admin', false)->where('status', 'active')->count(),
                'pending_users' => User::query()->where('is_admin', false)->where('status', 'pending')->count(),
                'admins' => User::query()->where('is_admin', true)->count(),
                'sessions' => Schema::hasTable('sessions') ? DB::table('sessions')->count() : 0,
                'transactions' => $totalTransactions,
                'pending_transactions' => $pendingTransactions,
                'successful_transactions' => $successfulTransactions,
                'failed_transactions' => $failedTransactions,
                'transaction_volume' => $totalVolume,
                'wallet_balance' => (float) User::query()->where('is_admin', false)->sum('balance'),
                'open_chats' => $hasChats ? ChatConversation::query()->whereIn('status', ['open', 'pending'])->count() : 0,
                'active_devices' => $hasTokens ? FirebaseDeviceToken::query()->where('is_active', true)->count() : 0,
                'active_banners' => $hasBanners ? AppBanner::query()->where('is_active', true)->count() : 0,
                'unread_notifications' => $hasNotifications ? AppNotification::query()->whereNull('read_at')->count() : 0,
            ],
            'transaction_modules' => [
                'mobile_recharge' => $hasRecharges ? $this->transactionSummary(MobileRecharge::query(), 'amount') : $this->emptySummary(),
                'bill_payment' => $hasBills ? $this->transactionSummary(BillPayment::query(), 'total_amount') : $this->emptySummary(),
                'bank_transfer' => $hasBankTransfers ? $this->transactionSummary(BankTransfer::query(), 'total_amount') : $this->emptySummary(),
                'wallet_withdrawal' => $hasWalletWithdrawals ? $this->transactionSummary(WalletWithdrawal::query(), 'total_amount') : $this->emptySummary(),
                'drive_offer' => $hasDriveOrders ? $this->transactionSummary(DriveOfferOrder::query(), 'total_amount') : $this->emptySummary(),
            ],
            'status_breakdown' => [
                'pending' => $pendingTransactions,
                'successful' => $successfulTransactions,
                'failed' => $failedTransactions,
                'processing' => (int) $transactionCollections->sum('processing'),
                'refunded' => (int) $transactionCollections->sum('refunded'),
                'cancelled' => (int) $transactionCollections->sum('cancelled'),
            ],
            'daily_trend' => $this->dailyTrend(),
            'pending_queues' => [
                'recharges' => $hasRecharges ? MobileRecharge::query()->whereIn('status', ['pending', 'processing'])->count() : 0,
                'bill_payments' => $hasBills ? BillPayment::query()->whereIn('status', ['pending', 'processing'])->count() : 0,
                'bank_transfers' => $hasBankTransfers ? BankTransfer::query()->whereIn('status', ['pending', 'processing'])->count() : 0,
                'wallet_withdrawals' => $hasWalletWithdrawals ? WalletWithdrawal::query()->whereIn('status', ['pending', 'processing'])->count() : 0,
                'drive_offers' => $hasDriveOrders ? DriveOfferOrder::query()->whereIn('status', ['pending', 'processing'])->count() : 0,
                'chats' => $hasChats ? ChatConversation::query()->whereIn('status', ['open', 'pending'])->count() : 0,
            ],
            'recent_activity' => $this->recentActivity(),
            'recent_users' => User::query()
                ->where('is_admin', false)
                ->latest()
                ->limit(6)
                ->get(['id', 'name', 'email', 'phone', 'status', 'is_admin', 'created_at']),
        ]);
    }

    private function transactionSummary($query, string $amountColumn): array
    {
        return [
            'total' => (clone $query)->count(),
            'pending' => (clone $query)->where('status', 'pending')->count(),
            'processing' => (clone $query)->where('status', 'processing')->count(),
            'successful' => (clone $query)->where('status', 'successful')->count(),
            'failed' => (clone $query)->whereIn('status', ['failed', 'rejected'])->count(),
            'refunded' => (clone $query)->where('status', 'refunded')->count(),
            'cancelled' => (clone $query)->where('status', 'cancelled')->count(),
            'volume' => (float) (clone $query)->sum($amountColumn),
            'today_volume' => (float) (clone $query)->whereDate('created_at', today())->sum($amountColumn),
        ];
    }

    private function emptySummary(): array
    {
        return [
            'total' => 0,
            'pending' => 0,
            'processing' => 0,
            'successful' => 0,
            'failed' => 0,
            'refunded' => 0,
            'cancelled' => 0,
            'volume' => 0,
            'today_volume' => 0,
        ];
    }

    private function dailyTrend(): array
    {
        return collect(range(6, 0))
            ->map(function (int $daysAgo): array {
                $date = today()->subDays($daysAgo);

                return [
                    'date' => $date->format('M d'),
                    'transactions' => $this->countForDate($date),
                    'volume' => $this->volumeForDate($date),
                ];
            })
            ->values()
            ->all();
    }

    private function countForDate($date): int
    {
        return collect([
            Schema::hasTable('mobile_recharges') ? MobileRecharge::query()->whereDate('created_at', $date)->count() : 0,
            Schema::hasTable('bill_payments') ? BillPayment::query()->whereDate('created_at', $date)->count() : 0,
            Schema::hasTable('bank_transfers') ? BankTransfer::query()->whereDate('created_at', $date)->count() : 0,
            Schema::hasTable('wallet_withdrawals') ? WalletWithdrawal::query()->whereDate('created_at', $date)->count() : 0,
            Schema::hasTable('drive_offer_orders') ? DriveOfferOrder::query()->whereDate('created_at', $date)->count() : 0,
        ])->sum();
    }

    private function volumeForDate($date): float
    {
        return (float) collect([
            Schema::hasTable('mobile_recharges') ? MobileRecharge::query()->whereDate('created_at', $date)->sum('amount') : 0,
            Schema::hasTable('bill_payments') ? BillPayment::query()->whereDate('created_at', $date)->sum('total_amount') : 0,
            Schema::hasTable('bank_transfers') ? BankTransfer::query()->whereDate('created_at', $date)->sum('total_amount') : 0,
            Schema::hasTable('wallet_withdrawals') ? WalletWithdrawal::query()->whereDate('created_at', $date)->sum('total_amount') : 0,
            Schema::hasTable('drive_offer_orders') ? DriveOfferOrder::query()->whereDate('created_at', $date)->sum('total_amount') : 0,
        ])->sum();
    }

    private function recentActivity(): array
    {
        $items = collect()
            ->merge($this->recentTransactions(MobileRecharge::class, 'mobile_recharges', 'Recharge', 'amount'))
            ->merge($this->recentTransactions(BillPayment::class, 'bill_payments', 'Bill Payment', 'total_amount'))
            ->merge($this->recentTransactions(BankTransfer::class, 'bank_transfers', 'Bank Transfer', 'total_amount'))
            ->merge($this->recentTransactions(WalletWithdrawal::class, 'wallet_withdrawals', 'Wallet Withdrawal', 'total_amount'))
            ->merge($this->recentTransactions(DriveOfferOrder::class, 'drive_offer_orders', 'Drive Offer', 'total_amount'));

        return $items
            ->sortByDesc('created_at')
            ->take(10)
            ->values()
            ->all();
    }

    private function recentTransactions(string $model, string $table, string $type, string $amountColumn): Collection
    {
        if (! Schema::hasTable($table)) {
            return collect();
        }

        return $model::query()
            ->latest()
            ->limit(6)
            ->get()
            ->map(fn ($item): array => [
                'id' => $table.'-'.$item->id,
                'type' => $type,
                'reference' => $item->transaction_id,
                'email' => $item->email,
                'amount' => (float) $item->{$amountColumn},
                'status' => $item->status,
                'created_at' => $item->created_at?->toISOString(),
            ]);
    }
}
