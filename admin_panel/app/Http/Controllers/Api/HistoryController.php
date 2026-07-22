<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankTransfer;
use App\Models\BillPayment;
use App\Models\DriveOfferOrder;
use App\Models\MobileRecharge;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HistoryController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $recharges = MobileRecharge::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn (MobileRecharge $recharge): array => [
                'id' => 'recharge-'.$recharge->id,
                'reference' => $recharge->transaction_id,
                'title' => $recharge->operator.' Recharge',
                'subtitle' => $recharge->mobile_number,
                'category' => 'recharge',
                'direction' => 'out',
                'amount' => (float) $recharge->amount,
                'currency' => 'BDT',
                'status' => $recharge->status,
                'created_at' => $recharge->created_at?->toISOString(),
                'processed_at' => $recharge->processed_at?->toISOString(),
                'meta' => [
                    'operator' => $recharge->operator,
                    'mobile_number' => $recharge->mobile_number,
                    'admin_note' => $recharge->admin_note,
                ],
            ]);

        $billPayments = BillPayment::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn (BillPayment $bill): array => [
                'id' => 'bill-'.$bill->id,
                'reference' => $bill->transaction_id,
                'title' => $bill->provider.' Bill',
                'subtitle' => $bill->account_number,
                'category' => 'bill',
                'direction' => 'out',
                'amount' => (float) $bill->total_amount,
                'currency' => 'BDT',
                'status' => $bill->status,
                'created_at' => $bill->created_at?->toISOString(),
                'processed_at' => $bill->processed_at?->toISOString(),
                'meta' => [
                    'bill_category' => $bill->category,
                    'provider' => $bill->provider,
                    'account_number' => $bill->account_number,
                    'billing_period' => $bill->billing_period,
                    'admin_note' => $bill->admin_note,
                ],
            ]);

        $bankTransfers = BankTransfer::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn (BankTransfer $transfer): array => [
                'id' => 'bank-transfer-'.$transfer->id,
                'reference' => $transfer->transaction_id,
                'title' => $transfer->bank_name.' Transfer',
                'subtitle' => $transfer->account_number,
                'category' => 'bank_transfer',
                'direction' => 'out',
                'amount' => (float) $transfer->total_amount,
                'currency' => 'BDT',
                'status' => $transfer->status,
                'created_at' => $transfer->created_at?->toISOString(),
                'processed_at' => $transfer->processed_at?->toISOString(),
                'meta' => [
                    'bank_name' => $transfer->bank_name,
                    'branch_name' => $transfer->branch_name,
                    'account_name' => $transfer->account_name,
                    'account_number' => $transfer->account_number,
                    'admin_note' => $transfer->admin_note,
                ],
            ]);

        $driveOfferOrders = DriveOfferOrder::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn (DriveOfferOrder $order): array => [
                'id' => 'drive-offer-'.$order->id,
                'reference' => $order->transaction_id,
                'title' => $order->operator.' Internet Offer',
                'subtitle' => $order->offer_title,
                'category' => 'drive_offer',
                'direction' => 'out',
                'amount' => (float) $order->total_amount,
                'currency' => 'BDT',
                'status' => $order->status,
                'created_at' => $order->created_at?->toISOString(),
                'processed_at' => $order->processed_at?->toISOString(),
                'meta' => [
                    'operator' => $order->operator,
                    'mobile_number' => $order->mobile_number,
                    'data_amount' => $order->data_amount,
                    'validity' => $order->validity,
                    'admin_note' => $order->admin_note,
                ],
            ]);

        $histories = $recharges
            ->merge($billPayments)
            ->merge($bankTransfers)
            ->merge($driveOfferOrders)
            ->sortByDesc('created_at')
            ->values();

        return response()->json([
            'message' => 'History loaded successfully.',
            'summary' => [
                'total' => $histories->count(),
                'in' => 0,
                'out' => $histories->count(),
                'recharge' => $recharges->count(),
                'bank_transfer' => $bankTransfers->count(),
                'drive_offer' => $driveOfferOrders->count(),
                'pending' => $histories->where('status', 'pending')->count(),
            ],
            'histories' => $histories,
        ]);
    }
}
