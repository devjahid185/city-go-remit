<?php

namespace App\Services;

use App\Models\AppNotification;

class TransactionStatusNotificationService
{
    public function __construct(private readonly FirebaseMessagingService $messaging)
    {
    }

    public function mobileRecharge(object $recharge, string $previousStatus): void
    {
        $this->send(
            $recharge,
            $previousStatus,
            'Mobile Recharge Update',
            "Your {$recharge->operator} recharge",
            (float) $recharge->amount,
            $recharge->transaction_id,
        );
    }

    public function billPayment(object $billPayment, string $previousStatus): void
    {
        $this->send(
            $billPayment,
            $previousStatus,
            'Bill Payment Update',
            "Your {$billPayment->provider} bill payment",
            (float) $billPayment->total_amount,
            $billPayment->transaction_id,
        );
    }

    public function bankTransfer(object $bankTransfer, string $previousStatus): void
    {
        $this->send(
            $bankTransfer,
            $previousStatus,
            'Bank Transfer Update',
            "Your {$bankTransfer->bank_name} transfer",
            (float) $bankTransfer->total_amount,
            $bankTransfer->transaction_id,
        );
    }

    public function driveOffer(object $order, string $previousStatus): void
    {
        $this->send(
            $order,
            $previousStatus,
            'Internet Offer Update',
            "Your {$order->operator} internet offer",
            (float) $order->total_amount,
            $order->transaction_id,
        );
    }

    private function send(object $transaction, string $previousStatus, string $title, string $subject, float $amount, string $transactionId): void
    {
        if ($previousStatus === $transaction->status) {
            return;
        }

        $body = $this->body($subject, $transaction->status, $amount, $transactionId, $transaction->admin_note ?? null);
        $data = [
            'type' => 'transaction_status',
            'action_type' => 'history',
            'action_value' => $transactionId,
            'status' => $transaction->status,
        ];

        AppNotification::query()->create([
            'user_id' => $transaction->user_id,
            'email' => $transaction->email,
            'title' => $title,
            'body' => $body,
            'type' => 'transaction_status',
            'data' => $data,
        ]);

        if ($transaction->user_id) {
            $this->messaging->sendToUser($transaction->user_id, $title, $body, $data);

            return;
        }

        if (! empty($transaction->email)) {
            $this->messaging->sendToEmail($transaction->email, $title, $body, $data);
        }
    }

    private function body(string $subject, string $status, float $amount, string $transactionId, ?string $adminNote): string
    {
        $amountText = 'BDT '.number_format($amount, 2);
        $statusText = match ($status) {
            'successful' => 'has been completed successfully',
            'failed' => 'could not be completed',
            'rejected' => 'has been rejected',
            'refunded' => 'has been refunded',
            'cancelled' => 'has been cancelled',
            'processing' => 'is now processing',
            default => "is now {$status}",
        };

        $message = "{$subject} ({$transactionId}) for {$amountText} {$statusText}.";

        if (in_array($status, ['failed', 'rejected', 'cancelled'], true) && trim((string) $adminNote) !== '') {
            $message .= ' Reason: '.str($adminNote)->limit(90);
        }

        return $message;
    }
}
