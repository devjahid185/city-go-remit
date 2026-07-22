<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone')->nullable()->after('email');
            $table->string('address')->nullable()->after('phone');
            $table->string('status')->default('active')->after('address');
            $table->timestamp('last_seen_at')->nullable()->after('status');
            $table->index('status', 'users_status_index');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex('users_status_index');
            $table->dropColumn([
                'phone',
                'address',
                'status',
                'last_seen_at',
            ]);
        });
    }
};
