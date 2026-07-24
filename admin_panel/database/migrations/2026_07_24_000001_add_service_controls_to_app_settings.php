<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $settings = [
            'maintenance_mode' => '0',
            'mobile_recharge_enabled' => '1',
            'mobile_recharge_charge' => '0',
            'bill_payment_enabled' => '1',
            'bill_payment_charge' => '0',
            'bank_transfer_enabled' => '1',
            'bank_transfer_charge' => '0',
            'wallet_withdrawal_enabled' => '1',
            'wallet_withdrawal_charge' => '0',
        ];

        foreach ($settings as $key => $value) {
            DB::table('app_settings')->updateOrInsert(
                ['key' => $key],
                ['value' => $value, 'created_at' => now(), 'updated_at' => now()]
            );
        }

        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (! Schema::hasColumn('mobile_recharges', 'charge')) {
                $table->decimal('charge', 10, 2)->default(0)->after('amount');
            }

            if (! Schema::hasColumn('mobile_recharges', 'total_amount')) {
                $table->decimal('total_amount', 10, 2)->default(0)->after('charge');
            }
        });

        DB::table('mobile_recharges')
            ->where('total_amount', 0)
            ->update(['total_amount' => DB::raw('amount + charge')]);
    }

    public function down(): void
    {
        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (Schema::hasColumn('mobile_recharges', 'total_amount')) {
                $table->dropColumn('total_amount');
            }

            if (Schema::hasColumn('mobile_recharges', 'charge')) {
                $table->dropColumn('charge');
            }
        });

        DB::table('app_settings')
            ->whereIn('key', [
                'maintenance_mode',
                'mobile_recharge_enabled',
                'mobile_recharge_charge',
                'bill_payment_enabled',
                'bill_payment_charge',
                'bank_transfer_enabled',
                'bank_transfer_charge',
                'wallet_withdrawal_enabled',
                'wallet_withdrawal_charge',
            ])
            ->delete();
    }
};
