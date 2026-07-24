<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\AppServiceSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class GeneralSettingController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'message' => 'General settings loaded successfully.',
            'settings' => $this->settings(),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'youtube_url' => ['nullable', 'url', 'max:500'],
            'telegram_url' => ['nullable', 'url', 'max:500'],
            'maintenance_mode' => ['nullable', 'boolean'],
            'add_money_enabled' => ['nullable', 'boolean'],
            'add_money_min_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'add_money_max_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'mobile_recharge_enabled' => ['nullable', 'boolean'],
            'mobile_recharge_charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'mobile_recharge_min_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'mobile_recharge_max_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'bill_payment_enabled' => ['nullable', 'boolean'],
            'bill_payment_charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'bill_payment_min_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'bill_payment_max_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'bank_transfer_enabled' => ['nullable', 'boolean'],
            'bank_transfer_charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'bank_transfer_min_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'bank_transfer_max_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'wallet_withdrawal_enabled' => ['nullable', 'boolean'],
            'wallet_withdrawal_charge' => ['nullable', 'numeric', 'min:0', 'max:50000'],
            'wallet_withdrawal_min_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
            'wallet_withdrawal_max_amount' => ['nullable', 'numeric', 'min:0', 'max:999999999'],
        ]);

        AppSetting::put('youtube_url', $data['youtube_url'] ?? '');
        AppSetting::put('telegram_url', $data['telegram_url'] ?? '');
        AppSetting::put('maintenance_mode', ! empty($data['maintenance_mode']) ? '1' : '0');

        foreach ([AppServiceSettings::ADD_MONEY, AppServiceSettings::MOBILE_RECHARGE, AppServiceSettings::BILL_PAYMENT, AppServiceSettings::BANK_TRANSFER, AppServiceSettings::WALLET_WITHDRAWAL] as $service) {
            $enabledKey = "{$service}_enabled";
            $chargeKey = "{$service}_charge";
            $minKey = "{$service}_min_amount";
            $maxKey = "{$service}_max_amount";
            $min = (float) ($data[$minKey] ?? AppSetting::float($minKey));
            $max = (float) ($data[$maxKey] ?? AppSetting::float($maxKey));

            if ($max > 0 && $min > $max) {
                throw ValidationException::withMessages([
                    $minKey => 'Minimum amount cannot be greater than maximum amount.',
                ]);
            }

            if (array_key_exists($enabledKey, $data)) {
                AppSetting::put($enabledKey, ! empty($data[$enabledKey]) ? '1' : '0');
            }

            if (array_key_exists($chargeKey, $data)) {
                AppSetting::put($chargeKey, $data[$chargeKey] ?? '0');
            }

            if (array_key_exists($minKey, $data)) {
                AppSetting::put($minKey, $data[$minKey] ?? '0');
            }

            if (array_key_exists($maxKey, $data)) {
                AppSetting::put($maxKey, $data[$maxKey] ?? '0');
            }
        }

        return response()->json([
            'message' => 'General settings updated successfully.',
            'settings' => $this->settings(),
        ]);
    }

    private function settings(): array
    {
        return [
            'youtube_url' => AppSetting::value('youtube_url', ''),
            'telegram_url' => AppSetting::value('telegram_url', ''),
            'maintenance_mode' => AppSetting::bool('maintenance_mode'),
            'add_money_enabled' => AppSetting::bool('add_money_enabled', true),
            'add_money_min_amount' => AppSetting::float('add_money_min_amount', 10),
            'add_money_max_amount' => AppSetting::float('add_money_max_amount', 500000),
            'mobile_recharge_enabled' => AppSetting::bool('mobile_recharge_enabled', true),
            'mobile_recharge_charge' => AppSetting::float('mobile_recharge_charge'),
            'mobile_recharge_min_amount' => AppSetting::float('mobile_recharge_min_amount', 10),
            'mobile_recharge_max_amount' => AppSetting::float('mobile_recharge_max_amount', 50000),
            'bill_payment_enabled' => AppSetting::bool('bill_payment_enabled', true),
            'bill_payment_charge' => AppSetting::float('bill_payment_charge'),
            'bill_payment_min_amount' => AppSetting::float('bill_payment_min_amount', 10),
            'bill_payment_max_amount' => AppSetting::float('bill_payment_max_amount', 500000),
            'bank_transfer_enabled' => AppSetting::bool('bank_transfer_enabled', true),
            'bank_transfer_charge' => AppSetting::float('bank_transfer_charge'),
            'bank_transfer_min_amount' => AppSetting::float('bank_transfer_min_amount', 100),
            'bank_transfer_max_amount' => AppSetting::float('bank_transfer_max_amount', 500000),
            'wallet_withdrawal_enabled' => AppSetting::bool('wallet_withdrawal_enabled', true),
            'wallet_withdrawal_charge' => AppSetting::float('wallet_withdrawal_charge'),
            'wallet_withdrawal_min_amount' => AppSetting::float('wallet_withdrawal_min_amount', 50),
            'wallet_withdrawal_max_amount' => AppSetting::float('wallet_withdrawal_max_amount', 500000),
        ];
    }
}
