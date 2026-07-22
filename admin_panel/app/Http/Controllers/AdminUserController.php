<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class AdminUserController extends Controller
{
    public function index(): View
    {
        $filters = [
            'search' => request('search'),
            'status' => request('status'),
        ];

        $baseQuery = User::query();

        $stats = [
            'total' => (clone $baseQuery)->count(),
            'active' => (clone $baseQuery)->where('status', 'active')->count(),
            'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
            'admins' => (clone $baseQuery)->where('is_admin', true)->count(),
        ];

        $users = User::query()
            ->when($filters['search'], function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'], fn ($query, string $status) => $query->where('status', $status))
            ->latest()
            ->paginate(10)
            ->withQueryString();

        $featuredUser = User::query()
            ->where('is_admin', true)
            ->latest('last_seen_at')
            ->first() ?? User::query()->latest()->first();

        return view('admin.users.index', [
            'filters' => $filters,
            'featuredUser' => $featuredUser,
            'stats' => $stats,
            'users' => $users,
        ]);
    }

    public function create(): View
    {
        return view('admin.users.create');
    }

    public function store(Request $request): RedirectResponse
    {
        User::query()->create($this->validatedUserData($request));

        return redirect()
            ->route('admin.users.index')
            ->with('status', 'User created successfully.');
    }

    public function edit(User $user): View
    {
        return view('admin.users.edit', [
            'user' => $user,
        ]);
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        $user->update($this->validatedUserData($request, $user));

        return redirect()
            ->route('admin.users.index')
            ->with('status', 'User updated successfully.');
    }

    public function destroy(User $user): RedirectResponse
    {
        if ($user->is(auth()->user())) {
            return redirect()
                ->route('admin.users.index')
                ->with('status', 'You cannot delete your own account.');
        }

        $user->delete();

        return redirect()
            ->route('admin.users.index')
            ->with('status', 'User deleted successfully.');
    }

    private function validatedUserData(Request $request, ?User $user = null): array
    {
        $passwordRules = $user
            ? ['nullable', 'string', 'confirmed']
            : ['required', 'string', 'confirmed'];

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user)],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
            'balance' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],
            'password' => $passwordRules,
            'status' => ['required', Rule::in(['active', 'pending', 'inactive'])],
            'is_admin' => ['nullable', 'boolean'],
        ]);

        $payload = [
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'balance' => $data['balance'] ?? ($user?->balance ?? 0),
            'is_admin' => $request->boolean('is_admin'),
            'status' => $data['status'],
            'email_verified_at' => $data['status'] === 'pending' ? null : ($user?->email_verified_at ?? now()),
        ];

        if (! $user) {
            $payload['last_seen_at'] = now();
        }

        if (! empty($data['password'])) {
            $payload['password'] = $data['password'];
        }

        return $payload;
    }
}
