<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankTransfer;
use App\Models\BillPayment;
use App\Models\DriveOfferOrder;
use App\Models\MobileRecharge;
use App\Models\WalletWithdrawal;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    public function show(Request $request, string $type, string $transactionId)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'format' => ['nullable', 'in:json,html'],
        ]);

        $receipt = $this->receipt($type, $transactionId, $data['email']);

        if (! $receipt) {
            return response()->json(['message' => 'Receipt was not found.'], 404);
        }

        if (($data['format'] ?? 'json') === 'html') {
            return response($this->html($receipt))->header('Content-Type', 'text/html');
        }

        return response()->json([
            'message' => 'Receipt loaded successfully.',
            'receipt' => $receipt,
        ]);
    }

    private function receipt(string $type, string $transactionId, string $email): ?array
    {
        return match ($type) {
            'recharge' => $this->mobileRecharge($transactionId, $email),
            'bill' => $this->billPayment($transactionId, $email),
            'bank_transfer' => $this->bankTransfer($transactionId, $email),
            'wallet_withdrawal' => $this->walletWithdrawal($transactionId, $email),
            'drive_offer' => $this->driveOffer($transactionId, $email),
            default => null,
        };
    }

    private function mobileRecharge(string $transactionId, string $email): ?array
    {
        $item = MobileRecharge::query()->where('transaction_id', $transactionId)->where('email', $email)->first();
        if (! $item || $item->status !== 'successful') return null;

        return $this->base('Mobile Recharge', $item->transaction_id, $item->email, (float) $item->amount, $item->status, [
            'Operator' => $item->operator,
            'Mobile Number' => $item->mobile_number,
        ], $item->processed_at ?? $item->updated_at);
    }

    private function billPayment(string $transactionId, string $email): ?array
    {
        $item = BillPayment::query()->where('transaction_id', $transactionId)->where('email', $email)->first();
        if (! $item || $item->status !== 'successful') return null;

        return $this->base('Bill Payment', $item->transaction_id, $item->email, (float) $item->total_amount, $item->status, [
            'Provider' => $item->provider,
            'Category' => $item->category,
            'Account Number' => $item->account_number,
            'Billing Period' => $item->billing_period ?: '-',
        ], $item->processed_at ?? $item->updated_at);
    }

    private function bankTransfer(string $transactionId, string $email): ?array
    {
        $item = BankTransfer::query()->where('transaction_id', $transactionId)->where('email', $email)->first();
        if (! $item || $item->status !== 'successful') return null;

        return $this->base('Bank Transfer', $item->transaction_id, $item->email, (float) $item->total_amount, $item->status, [
            'Bank' => $item->bank_name,
            'Account Name' => $item->account_name,
            'Account Number' => $item->account_number,
            'Branch' => $item->branch_name ?: '-',
        ], $item->processed_at ?? $item->updated_at);
    }

    private function driveOffer(string $transactionId, string $email): ?array
    {
        $item = DriveOfferOrder::query()->where('transaction_id', $transactionId)->where('email', $email)->first();
        if (! $item || $item->status !== 'successful') return null;

        return $this->base('Internet Offer', $item->transaction_id, $item->email, (float) $item->total_amount, $item->status, [
            'Operator' => $item->operator,
            'Offer' => $item->offer_title,
            'Mobile Number' => $item->mobile_number,
            'Validity' => $item->validity,
        ], $item->processed_at ?? $item->updated_at);
    }

    private function walletWithdrawal(string $transactionId, string $email): ?array
    {
        $item = WalletWithdrawal::query()->where('transaction_id', $transactionId)->where('email', $email)->first();
        if (! $item || $item->status !== 'successful') return null;

        return $this->base('Wallet Withdrawal', $item->transaction_id, $item->email, (float) $item->total_amount, $item->status, [
            'Wallet' => $item->wallet_provider,
            'Wallet Number' => $item->wallet_number,
            'Account Name' => $item->account_name ?: '-',
            'Contact Number' => $item->contact_number ?: '-',
        ], $item->processed_at ?? $item->updated_at);
    }

    private function base(string $title, string $transactionId, string $email, float $amount, string $status, array $details, mixed $date): array
    {
        return [
            'brand' => 'City Go Remit',
            'title' => $title,
            'transaction_id' => $transactionId,
            'email' => $email,
            'amount' => $amount,
            'amount_text' => 'BDT '.number_format($amount, 2),
            'status' => $status,
            'date' => $date?->toDayDateTimeString(),
            'details' => $details,
        ];
    }

    private function html(array $receipt): string
    {
        $rows = collect($receipt['details'])
            ->map(fn ($value, $key) => "<tr><td>{$key}</td><td>{$value}</td></tr>")
            ->implode('');

        return "<!doctype html><html><head><meta charset='utf-8'><title>{$receipt['brand']} Receipt</title><style>body{font-family:Inter,Arial,sans-serif;background:#f8fafc;margin:0;padding:24px;color:#0f172a}.card{max-width:560px;margin:auto;background:white;border:1px solid #e2e8f0;border-radius:18px;padding:28px}.brand{color:#dc2626;letter-spacing:.18em;text-transform:uppercase;font-size:12px}.amount{font-size:34px;margin:18px 0}.ok{display:inline-block;background:#dcfce7;color:#166534;border-radius:999px;padding:8px 12px;font-size:13px}table{width:100%;border-collapse:collapse;margin-top:22px}td{padding:12px 0;border-bottom:1px solid #e2e8f0}td:last-child{text-align:right;font-weight:500}.footer{margin-top:22px;color:#64748b;font-size:13px}</style></head><body><div class='card'><div class='brand'>{$receipt['brand']}</div><h1>{$receipt['title']} Receipt</h1><div class='amount'>{$receipt['amount_text']}</div><span class='ok'>{$receipt['status']}</span><table><tr><td>Transaction ID</td><td>{$receipt['transaction_id']}</td></tr><tr><td>Email</td><td>{$receipt['email']}</td></tr><tr><td>Date</td><td>{$receipt['date']}</td></tr>{$rows}</table><p class='footer'>This is a system generated receipt from City Go Remit.</p></div></body></html>";
    }
}
