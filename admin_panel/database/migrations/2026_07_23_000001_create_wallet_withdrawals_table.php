<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wallet_withdrawals', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('email');
            $table->string('wallet_provider');
            $table->string('wallet_number');
            $table->string('account_name')->nullable();
            $table->string('contact_number')->nullable();
            $table->decimal('amount', 12, 2);
            $table->decimal('charge', 10, 2)->default(0);
            $table->decimal('total_amount', 12, 2);
            $table->string('transaction_id')->unique();
            $table->string('status')->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('admin_note')->nullable();
            $table->timestamp('debited_at')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['email', 'created_at']);
            $table->index(['wallet_provider', 'status']);
            $table->index(['wallet_number', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_withdrawals');
    }
};
