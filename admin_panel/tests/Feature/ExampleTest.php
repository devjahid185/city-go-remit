<?php

namespace Tests\Feature;

use App\Models\OtpVerification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin')
            ->assertRedirect('/admin/login');
    }

    public function test_admin_can_view_dashboard(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSee('Admin Dashboard');
    }

    public function test_admin_can_view_users_page(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->get('/admin/users')
            ->assertOk()
            ->assertSee('User Management');
    }

    public function test_admin_can_view_profile_page(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->get('/admin/profile')
            ->assertOk()
            ->assertSee('Profile Settings');
    }

    public function test_admin_can_create_user_manually(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->post('/admin/users', [
                'name' => 'Manual User',
                'email' => 'manual@example.com',
                'phone' => '+880 1711-000000',
                'address' => 'Dhaka, Bangladesh',
                'password' => 'Manual123',
                'password_confirmation' => 'Manual123',
                'status' => 'active',
            ])
            ->assertRedirect('/admin/users');

        $this->assertDatabaseHas('users', [
            'email' => 'manual@example.com',
            'address' => 'Dhaka, Bangladesh',
            'status' => 'active',
            'is_admin' => false,
        ]);
    }

    public function test_admin_can_delete_another_user(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'status' => 'active',
        ]);
        $user = User::factory()->create([
            'email' => 'delete-me@example.com',
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->delete("/admin/users/{$user->id}")
            ->assertRedirect('/admin/users');

        $this->assertDatabaseMissing('users', [
            'email' => 'delete-me@example.com',
        ]);
    }

    public function test_admin_cannot_delete_own_account(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'email' => 'keep-admin@example.com',
            'status' => 'active',
        ]);

        $this->actingAs($admin)
            ->delete("/admin/users/{$admin->id}")
            ->assertRedirect('/admin/users');

        $this->assertDatabaseHas('users', [
            'email' => 'keep-admin@example.com',
        ]);
    }

    public function test_app_user_can_register_through_api(): void
    {
        Mail::fake();

        $this->postJson('/api/register', [
            'name' => 'App User',
            'email' => 'app-user@example.com',
            'phone' => '+880 1812-000000',
            'address' => 'Dhaka, Bangladesh',
            'password' => 'AppUser123',
            'password_confirmation' => 'AppUser123',
        ])
            ->assertOk()
            ->assertJsonPath('email', 'app-user@example.com');

        $this->assertDatabaseHas('otp_verifications', [
            'email' => 'app-user@example.com',
            'purpose' => 'register',
        ]);

        $this->assertDatabaseMissing('users', [
            'email' => 'app-user@example.com',
        ]);
    }

    public function test_app_user_can_verify_registration_otp(): void
    {
        OtpVerification::query()->create([
            'email' => 'verify-user@example.com',
            'purpose' => 'register',
            'code_hash' => Hash::make('123456'),
            'payload' => [
                'name' => 'Verify User',
                'email' => 'verify-user@example.com',
                'phone' => '+880 1812-000001',
                'address' => 'Dhaka, Bangladesh',
                'password' => Hash::make('Verify123'),
                'is_admin' => false,
                'status' => 'active',
            ],
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/register/verify-otp', [
            'email' => 'verify-user@example.com',
            'otp' => '123456',
        ])
            ->assertCreated()
            ->assertJsonPath('user.email', 'verify-user@example.com');

        $this->assertDatabaseHas('users', [
            'email' => 'verify-user@example.com',
            'address' => 'Dhaka, Bangladesh',
        ]);
    }

    public function test_app_user_can_create_account_with_kyc_flow(): void
    {
        Mail::fake();
        Storage::fake('public');

        $this->postJson('/api/kyc-register', [
            'email' => 'kyc-user@example.com',
            'first_name' => 'Kyc',
            'last_name' => 'User',
            'date_of_birth' => '1998-06-04',
            'father_name' => 'Father User',
            'mother_name' => 'Mother User',
            'phone' => '1711000000',
            'address' => 'Dhaka, Bangladesh',
            'country_name' => 'Bangladesh',
            'country_code' => '+880',
            'country_flag' => '🇧🇩',
            'government_document' => UploadedFile::fake()->image('passport.jpg'),
            'password' => 'KycUser123',
            'password_confirmation' => 'KycUser123',
            'source' => 'google',
        ])
            ->assertCreated()
            ->assertJsonPath('user.email', 'kyc-user@example.com')
            ->assertJsonPath('user.country_code', '+880');

        $this->assertDatabaseHas('users', [
            'email' => 'kyc-user@example.com',
            'first_name' => 'Kyc',
            'country_name' => 'Bangladesh',
            'status' => 'active',
        ]);
    }

    public function test_app_user_can_login_through_api(): void
    {
        User::factory()->create([
            'email' => 'login-user@example.com',
            'password' => 'LoginUser123',
            'status' => 'active',
        ]);

        $this->postJson('/api/login', [
            'email' => 'login-user@example.com',
            'password' => 'LoginUser123',
        ])
            ->assertOk()
            ->assertJsonPath('user.email', 'login-user@example.com');
    }

    public function test_app_user_can_request_forgot_password_message(): void
    {
        Mail::fake();
        User::factory()->create([
            'email' => 'forgot-user@example.com',
            'password' => 'OldPass123',
            'status' => 'active',
        ]);

        $this->postJson('/api/forgot-password', [
            'email' => 'forgot-user@example.com',
        ])
            ->assertOk()
            ->assertJsonStructure(['message']);

        $this->assertDatabaseHas('otp_verifications', [
            'email' => 'forgot-user@example.com',
            'purpose' => 'password_reset',
        ]);
    }

    public function test_app_user_can_reset_password_with_otp(): void
    {
        User::factory()->create([
            'email' => 'reset-user@example.com',
            'password' => 'OldPass123',
            'status' => 'active',
        ]);

        OtpVerification::query()->create([
            'email' => 'reset-user@example.com',
            'purpose' => 'password_reset',
            'code_hash' => Hash::make('654321'),
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/forgot-password/verify-otp', [
            'email' => 'reset-user@example.com',
            'otp' => '654321',
            'password' => 'NewPass123',
            'password_confirmation' => 'NewPass123',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Password reset successfully.');
    }
}
