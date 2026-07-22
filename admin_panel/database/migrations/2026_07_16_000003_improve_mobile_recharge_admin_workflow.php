<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (! Schema::hasColumn('mobile_recharges', 'reviewed_by')) {
                $table->foreignId('reviewed_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            }

            if (! Schema::hasColumn('mobile_recharges', 'admin_note')) {
                $table->text('admin_note')->nullable()->after('reviewed_by');
            }
        });

        DB::statement("ALTER TABLE mobile_recharges MODIFY status VARCHAR(255) NOT NULL DEFAULT 'pending'");
    }

    public function down(): void
    {
        Schema::table('mobile_recharges', function (Blueprint $table): void {
            if (Schema::hasColumn('mobile_recharges', 'reviewed_by')) {
                $table->dropConstrainedForeignId('reviewed_by');
            }

            if (Schema::hasColumn('mobile_recharges', 'admin_note')) {
                $table->dropColumn('admin_note');
            }
        });

        DB::statement("ALTER TABLE mobile_recharges MODIFY status VARCHAR(255) NOT NULL DEFAULT 'successful'");
    }
};
