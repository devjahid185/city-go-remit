<?php

namespace App\Services;

use App\Models\AppSetting;

class AppServiceSettings
{
    public const MOBILE_RECHARGE = 'mobile_recharge';
    public const BILL_PAYMENT = 'bill_payment';
    public const BANK_TRANSFER = 'bank_transfer';
    public const WALLET_WITHDRAWAL = 'wallet_withdrawal';
    public const ADD_MONEY = 'add_money';

    public function maintenanceEnabled(): bool
    {
        return AppSetting::bool('maintenance_mode');
    }

    public function serviceEnabled(string $service): bool
    {
        return AppSetting::bool("{$service}_enabled", true);
    }

    public function charge(string $service): float
    {
        return AppSetting::float("{$service}_charge");
    }

    public function minAmount(string $service): float
    {
        return AppSetting::float("{$service}_min_amount", $this->defaultMin($service));
    }

    public function maxAmount(string $service): float
    {
        return AppSetting::float("{$service}_max_amount", $this->defaultMax($service));
    }

    public function amountLimitMessage(string $service, float $amount): ?string
    {
        $min = $this->minAmount($service);
        $max = $this->maxAmount($service);

        if ($amount < $min || $amount > $max) {
            return 'Amount must be between BDT '.number_format($min, 2).' and BDT '.number_format($max, 2).'.';
        }

        return null;
    }

    public function publicSettings(): array
    {
        return [
            'maintenance_mode' => $this->maintenanceEnabled(),
            'services' => [
                self::MOBILE_RECHARGE => $this->servicePayload(self::MOBILE_RECHARGE),
                self::BILL_PAYMENT => $this->servicePayload(self::BILL_PAYMENT),
                self::BANK_TRANSFER => $this->servicePayload(self::BANK_TRANSFER),
                self::WALLET_WITHDRAWAL => $this->servicePayload(self::WALLET_WITHDRAWAL),
                self::ADD_MONEY => $this->servicePayload(self::ADD_MONEY),
            ],
        ];
    }

    private function servicePayload(string $service): array
    {
        return [
            'enabled' => $this->serviceEnabled($service),
            'charge' => $this->charge($service),
            'min_amount' => $this->minAmount($service),
            'max_amount' => $this->maxAmount($service),
        ];
    }

    private function defaultMin(string $service): float
    {
        return match ($service) {
            self::BANK_TRANSFER => 100,
            self::WALLET_WITHDRAWAL => 50,
            default => 10,
        };
    }

    private function defaultMax(string $service): float
    {
        return match ($service) {
            self::MOBILE_RECHARGE => 50000,
            default => 500000,
        };
    }
}
