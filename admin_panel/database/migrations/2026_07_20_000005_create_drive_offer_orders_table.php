<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('drive_offer_orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('drive_offer_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('email');
            $table->string('mobile_number');
            $table->string('operator');
            $table->string('offer_title');
            $table->string('data_amount')->nullable();
            $table->string('validity');
            $table->decimal('price', 10, 2);
            $table->decimal('service_charge', 10, 2)->default(0);
            $table->decimal('total_amount', 10, 2);
            $table->string('transaction_id')->unique();
            $table->string('status')->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('admin_note')->nullable();
            $table->timestamp('debited_at')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['email', 'created_at']);
            $table->index(['operator', 'status']);
            $table->index(['mobile_number', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('drive_offer_orders');
    }
};
