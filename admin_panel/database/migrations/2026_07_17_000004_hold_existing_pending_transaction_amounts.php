<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('bill_payments')) {
            DB::table('bill_payments')
                ->whereIn('status', ['pending', 'processing'])
                ->whereNull('debited_at')
                ->orderBy('id')
                ->get()
                ->each(function ($bill): void {
                    DB::transaction(function () use ($bill): void {
                        $user = DB::table('users')->where('id', $bill->user_id)->lockForUpdate()->first();
                        if (! $user || (float) $user->balance < (float) $bill->total_amount) {
                            return;
                        }

                        DB::table('users')->where('id', $bill->user_id)->update([
                            'balance' => (float) $user->balance - (float) $bill->total_amount,
                            'updated_at' => now(),
                        ]);

                        DB::table('bill_payments')->where('id', $bill->id)->update([
                            'debited_at' => now(),
                            'updated_at' => now(),
                        ]);
                    });
                });
        }

        if (Schema::hasTable('mobile_recharges') && Schema::hasColumn('mobile_recharges', 'debited_at')) {
            DB::table('mobile_recharges')
                ->whereIn('status', ['pending', 'processing'])
                ->whereNull('debited_at')
                ->orderBy('id')
                ->get()
                ->each(function ($recharge): void {
                    DB::transaction(function () use ($recharge): void {
                        $user = DB::table('users')->where('id', $recharge->user_id)->lockForUpdate()->first();
                        if (! $user || (float) $user->balance < (float) $recharge->amount) {
                            return;
                        }

                        DB::table('users')->where('id', $recharge->user_id)->update([
                            'balance' => (float) $user->balance - (float) $recharge->amount,
                            'updated_at' => now(),
                        ]);

                        DB::table('mobile_recharges')->where('id', $recharge->id)->update([
                            'debited_at' => now(),
                            'updated_at' => now(),
                        ]);
                    });
                });
        }
    }

    public function down(): void
    {
        //
    }
};
