<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('exchange_rates', function (Blueprint $table): void {
            $table->id();
            $table->string('country_name');
            $table->string('country_code', 8);
            $table->string('country_flag', 12)->nullable();
            $table->string('currency_code', 8);
            $table->string('currency_name')->nullable();
            $table->decimal('bdt_rate', 12, 4);
            $table->decimal('service_fee', 12, 2)->default(0);
            $table->string('delivery_time')->nullable();
            $table->text('note')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();

            $table->unique(['country_code', 'currency_code']);
            $table->index(['is_active', 'sort_order']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('exchange_rates');
    }
};
