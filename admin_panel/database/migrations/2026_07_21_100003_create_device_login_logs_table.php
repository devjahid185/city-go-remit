<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_login_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('email')->index();
            $table->string('device_name')->nullable();
            $table->string('platform')->nullable();
            $table->string('ip_address')->nullable();
            $table->string('location')->nullable();
            $table->timestamp('logged_in_at');
            $table->timestamps();

            $table->index(['email', 'logged_in_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_login_logs');
    }
};
