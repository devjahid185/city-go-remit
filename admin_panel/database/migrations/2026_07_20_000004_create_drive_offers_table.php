<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('drive_offers', function (Blueprint $table): void {
            $table->id();
            $table->string('operator');
            $table->string('title');
            $table->string('offer_type')->default('internet');
            $table->string('data_amount')->nullable();
            $table->string('minutes')->nullable();
            $table->string('sms')->nullable();
            $table->string('validity');
            $table->decimal('price', 10, 2);
            $table->decimal('service_charge', 10, 2)->default(0);
            $table->string('activation_code')->nullable();
            $table->string('source_note')->nullable();
            $table->text('description')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();

            $table->index(['operator', 'is_active']);
            $table->index(['offer_type', 'is_active']);
            $table->index(['sort_order', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('drive_offers');
    }
};
