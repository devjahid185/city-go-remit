<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('app_settings')->updateOrInsert(
            ['key' => 'youtube_url'],
            ['value' => '', 'created_at' => now(), 'updated_at' => now()]
        );

        DB::table('app_settings')->updateOrInsert(
            ['key' => 'telegram_url'],
            ['value' => '', 'created_at' => now(), 'updated_at' => now()]
        );
    }

    public function down(): void
    {
        DB::table('app_settings')->whereIn('key', ['youtube_url', 'telegram_url'])->delete();
    }
};
