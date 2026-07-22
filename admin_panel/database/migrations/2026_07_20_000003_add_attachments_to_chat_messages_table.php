<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('chat_messages', function (Blueprint $table): void {
            $table->string('attachment_path')->nullable()->after('message');
            $table->string('attachment_url')->nullable()->after('attachment_path');
            $table->string('attachment_name')->nullable()->after('attachment_url');
            $table->string('attachment_mime')->nullable()->after('attachment_name');
        });
    }

    public function down(): void
    {
        Schema::table('chat_messages', function (Blueprint $table): void {
            $table->dropColumn([
                'attachment_path',
                'attachment_url',
                'attachment_name',
                'attachment_mime',
            ]);
        });
    }
};
