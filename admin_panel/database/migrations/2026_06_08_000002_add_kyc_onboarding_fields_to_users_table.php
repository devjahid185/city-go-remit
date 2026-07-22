<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('first_name')->nullable()->after('name');
            $table->string('last_name')->nullable()->after('first_name');
            $table->date('date_of_birth')->nullable()->after('last_name');
            $table->string('father_name')->nullable()->after('date_of_birth');
            $table->string('mother_name')->nullable()->after('father_name');
            $table->string('country_name')->nullable()->after('address');
            $table->string('country_code', 12)->nullable()->after('country_name');
            $table->string('country_flag', 12)->nullable()->after('country_code');
            $table->string('government_document_name')->nullable()->after('country_flag');
            $table->string('government_document_path')->nullable()->after('government_document_name');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'first_name',
                'last_name',
                'date_of_birth',
                'father_name',
                'mother_name',
                'country_name',
                'country_code',
                'country_flag',
                'government_document_name',
                'government_document_path',
            ]);
        });
    }
};
