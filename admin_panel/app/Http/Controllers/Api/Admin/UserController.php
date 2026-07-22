<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['active', 'pending', 'inactive'])],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $baseQuery = User::query();

        $users = User::query()
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->latest()
            ->paginate(10);

        return response()->json([
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'active' => (clone $baseQuery)->where('status', 'active')->count(),
                'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
                'inactive' => (clone $baseQuery)->where('status', 'inactive')->count(),
                'admins' => (clone $baseQuery)->where('is_admin', true)->count(),
            ],
            'users' => $users,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = User::query()->create($this->validatedData($request));

        return response()->json([
            'message' => 'User created successfully.',
            'user' => $user,
        ], 201);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json(['user' => $user]);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $user->update($this->validatedData($request, $user));

        return response()->json([
            'message' => 'User updated successfully.',
            'user' => $user->fresh(),
        ]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($user->is($request->user())) {
            return response()->json(['message' => 'You cannot delete your own account.'], 422);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted successfully.']);
    }

    private function validatedData(Request $request, ?User $user = null): array
    {
        $passwordRules = $user
            ? ['nullable', 'string', 'confirmed']
            : ['required', 'string', 'confirmed'];

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'first_name' => ['nullable', 'string', 'max:120'],
            'last_name' => ['nullable', 'string', 'max:120'],
            'date_of_birth' => ['nullable', 'date'],
            'father_name' => ['nullable', 'string', 'max:255'],
            'mother_name' => ['nullable', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user)],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
            'country_name' => ['nullable', 'string', 'max:120'],
            'country_code' => ['nullable', 'string', 'max:20'],
            'country_flag' => ['nullable', 'string', 'max:20'],
            'balance' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],
            'password' => $passwordRules,
            'status' => ['required', Rule::in(['active', 'pending', 'inactive'])],
            'is_admin' => ['nullable', 'boolean'],
        ]);

        $payload = collect($data)->except(['password'])->toArray();
        $payload['is_admin'] = $request->boolean('is_admin');
        $payload['email_verified_at'] = $data['status'] === 'pending'
            ? null
            : ($user?->email_verified_at ?? now());

        if (! $user) {
            $payload['last_seen_at'] = now();
        }

        if (! empty($data['password'])) {
            $payload['password'] = $data['password'];
        }

        return $payload;
    }
}
