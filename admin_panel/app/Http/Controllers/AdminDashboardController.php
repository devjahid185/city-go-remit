<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AdminDashboardController extends Controller
{
    public function __invoke(): View
    {
        $stats = [
            'admins' => User::query()->where('is_admin', true)->count(),
            'users' => User::query()->count(),
            'sessions' => DB::table('sessions')->count(),
            'jobs' => DB::table('jobs')->count(),
        ];

        $recentAdmins = User::query()
            ->where('is_admin', true)
            ->latest()
            ->limit(5)
            ->get(['name', 'email', 'created_at']);

        return view('admin.dashboard', [
            'stats' => $stats,
            'recentAdmins' => $recentAdmins,
        ]);
    }
}
