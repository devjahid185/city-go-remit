<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mobile_recharges', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('email');
            $table->string('mobile_number');
            $table->string('operator');
            $table->decimal('amount', 10, 2);
            $table->string('transaction_id')->unique();
            $table->string('status')->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('admin_note')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['email', 'created_at']);
            $table->index(['mobile_number', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mobile_recharges');
    }
};
