<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'referral_code')) {
                $table->string('referral_code')->nullable()->unique()->after('balance');
            }

            if (! Schema::hasColumn('users', 'referred_by_user_id')) {
                $table->foreignId('referred_by_user_id')->nullable()->after('referral_code')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('users', 'referral_bonus_earned')) {
                $table->decimal('referral_bonus_earned', 14, 2)->default(0)->after('referred_by_user_id');
            }
        });

        DB::table('users')->whereNull('referral_code')->orderBy('id')->get(['id'])->each(function ($user): void {
            DB::table('users')->where('id', $user->id)->update([
                'referral_code' => 'CGR'.$user->id.Str::upper(Str::random(5)),
            ]);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'referred_by_user_id')) {
                $table->dropConstrainedForeignId('referred_by_user_id');
            }

            foreach (['referral_bonus_earned', 'referral_code'] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
