<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminApiToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $admin = User::query()
            ->where('email', $credentials['email'])
            ->where('is_admin', true)
            ->first();

        if (! $admin || ! Hash::check($credentials['password'], $admin->password)) {
            return response()->json(['message' => 'Invalid admin credentials.'], 422);
        }

        $plainToken = Str::random(80);

        AdminApiToken::query()->create([
            'user_id' => $admin->id,
            'name' => 'admin-react',
            'token_hash' => hash('sha256', $plainToken),
            'expires_at' => now()->addDays(7),
        ]);

        $admin->forceFill(['last_seen_at' => now()])->save();

        return response()->json([
            'token' => $plainToken,
            'token_type' => 'Bearer',
            'expires_at' => now()->addDays(7)->toISOString(),
            'admin' => $this->adminPayload($admin),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'admin' => $this->adminPayload($request->user()),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->attributes->get('admin_api_token')?->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    private function adminPayload(User $admin): array
    {
        return [
            'id' => $admin->id,
            'name' => $admin->name,
            'email' => $admin->email,
            'phone' => $admin->phone,
            'address' => $admin->address,
            'first_name' => $admin->first_name,
            'last_name' => $admin->last_name,
            'country_name' => $admin->country_name,
            'country_code' => $admin->country_code,
            'last_seen_at' => $admin->last_seen_at?->toISOString(),
        ];
    }
}
