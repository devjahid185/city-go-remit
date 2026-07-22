<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'login_pin_hash')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('login_pin_hash');
        });
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'login_pin_hash')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->string('login_pin_hash')->nullable()->after('government_document_path');
        });
    }
};
