<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function update(Request $request): JsonResponse
    {
        $admin = $request->user();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($admin)],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
            'first_name' => ['nullable', 'string', 'max:120'],
            'last_name' => ['nullable', 'string', 'max:120'],
            'country_name' => ['nullable', 'string', 'max:120'],
            'country_code' => ['nullable', 'string', 'max:20'],
        ]);

        $admin->update($data);

        return response()->json([
            'message' => 'Admin profile updated successfully.',
            'admin' => $this->payload($admin->fresh()),
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $admin = $request->user();

        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'confirmed'],
        ]);

        if (! Hash::check($data['current_password'], $admin->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $admin->forceFill([
            'password' => $data['password'],
        ])->save();

        return response()->json([
            'message' => 'Password changed successfully.',
        ]);
    }

    private function payload($admin): array
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
