<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $settings = [
            'add_money_enabled' => '1',
            'add_money_charge' => '0',
            'add_money_min_amount' => '10',
            'add_money_max_amount' => '500000',
            'mobile_recharge_min_amount' => '10',
            'mobile_recharge_max_amount' => '50000',
            'bill_payment_min_amount' => '10',
            'bill_payment_max_amount' => '500000',
            'bank_transfer_min_amount' => '100',
            'bank_transfer_max_amount' => '500000',
            'wallet_withdrawal_min_amount' => '50',
            'wallet_withdrawal_max_amount' => '500000',
        ];

        foreach ($settings as $key => $value) {
            DB::table('app_settings')->updateOrInsert(
                ['key' => $key],
                ['value' => $value, 'created_at' => now(), 'updated_at' => now()]
            );
        }
    }

    public function down(): void
    {
        DB::table('app_settings')
            ->whereIn('key', [
                'add_money_enabled',
                'add_money_charge',
                'add_money_min_amount',
                'add_money_max_amount',
                'mobile_recharge_min_amount',
                'mobile_recharge_max_amount',
                'bill_payment_min_amount',
                'bill_payment_max_amount',
                'bank_transfer_min_amount',
                'bank_transfer_max_amount',
                'wallet_withdrawal_min_amount',
                'wallet_withdrawal_max_amount',
            ])
            ->delete();
    }
};
