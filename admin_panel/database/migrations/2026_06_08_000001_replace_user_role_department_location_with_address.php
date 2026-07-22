<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'address')) {
                $table->string('address')->nullable()->after('phone');
            }
        });

        if (Schema::hasColumn('users', 'location') && Schema::hasColumn('users', 'address')) {
            DB::statement('UPDATE users SET address = location WHERE address IS NULL AND location IS NOT NULL');
        }

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'role')) {
                try {
                    $table->dropIndex('users_role_index');
                } catch (\Throwable) {
                }
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $dropColumns = array_values(array_filter([
                Schema::hasColumn('users', 'role') ? 'role' : null,
                Schema::hasColumn('users', 'department') ? 'department' : null,
                Schema::hasColumn('users', 'location') ? 'location' : null,
            ]));

            if ($dropColumns !== []) {
                $table->dropColumn($dropColumns);
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'role')) {
                $table->string('role')->default('User')->after('is_admin');
            }

            if (! Schema::hasColumn('users', 'department')) {
                $table->string('department')->nullable()->after('role');
            }

            if (! Schema::hasColumn('users', 'location')) {
                $table->string('location')->nullable()->after('department');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'role')) {
                $table->index('role', 'users_role_index');
            }
        });
    }
};
