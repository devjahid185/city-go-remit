<?php

use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\AdminDashboardController;
use App\Http\Controllers\AdminProfileController;
use App\Http\Controllers\AdminUserController;
use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;

Route::get('/run-migrate', function () {
    Artisan::call('migrate', ['--force' => true]);

    return '<pre>'.Artisan::output().'</pre>';
});

Route::get('/run-cache-clear', function () {
    Artisan::call('optimize:clear');

    return '<pre>'.Artisan::output().'</pre>';
});

Route::get('/run-cache-build', function () {
    Artisan::call('config:cache');
    Artisan::call('view:cache');

    return '<pre>Config and view cache build complete.</pre>';
});

Route::get('/run-storage-link', function () {
    Artisan::call('storage:link');

    return '<pre>'.Artisan::output().'</pre>';
});

Route::get('/run-db-seed', function () {
    Artisan::call('db:seed', ['--force' => true]);

    return '<pre>'.Artisan::output().'</pre>';
});

Route::get('/run-admin-reset', function () {
    $email = env('ADMIN_EMAIL', 'admin@iqbal.local');
    $password = env('ADMIN_PASSWORD', 'Admin@12345');

    User::query()->updateOrCreate([
        'email' => $email,
    ], [
        'name' => env('ADMIN_NAME', 'City Go Remit Admin'),
        'password' => Hash::make($password),
        'is_admin' => true,
        'status' => 'active',
        'email_verified_at' => now(),
    ]);

    return '<pre>Admin ready: '.$email."\nPassword: ".$password.'</pre>';
});

Route::redirect('/', '/admin');
Route::redirect('/login', '/admin/login')->name('login');

Route::get('/admin/login', [AdminAuthController::class, 'create'])->name('admin.login');
Route::post('/admin/login', [AdminAuthController::class, 'store'])->name('admin.login.store');

Route::middleware(['auth', 'admin'])->group(function (): void {
    Route::get('/admin', AdminDashboardController::class)->name('admin.dashboard');
    Route::get('/admin/users', [AdminUserController::class, 'index'])->name('admin.users.index');
    Route::get('/admin/users/create', [AdminUserController::class, 'create'])->name('admin.users.create');
    Route::post('/admin/users', [AdminUserController::class, 'store'])->name('admin.users.store');
    Route::get('/admin/users/{user}/edit', [AdminUserController::class, 'edit'])->name('admin.users.edit');
    Route::put('/admin/users/{user}', [AdminUserController::class, 'update'])->name('admin.users.update');
    Route::delete('/admin/users/{user}', [AdminUserController::class, 'destroy'])->name('admin.users.destroy');
    Route::get('/admin/profile', AdminProfileController::class)->name('admin.profile');
    Route::post('/admin/logout', [AdminAuthController::class, 'destroy'])->name('admin.logout');
});
