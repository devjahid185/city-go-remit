<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (! Schema::hasColumn('mobile_recharges', 'debited_at')) {
                $table->timestamp('debited_at')->nullable()->after('admin_note');
            }
        });
    }

    public function down(): void
    {
        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (Schema::hasColumn('mobile_recharges', 'debited_at')) {
                $table->dropColumn('debited_at');
            }
        });
    }
};
