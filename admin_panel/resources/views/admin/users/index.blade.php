@extends('admin.layouts.app')

@section('title', 'Users')
@section('topbar', 'Users')
@section('active', 'users')

@section('topbar_actions')
    <a class="primary-button hide-mobile" href="{{ route('admin.users.create') }}">
        <span class="material-symbols-outlined">person_add</span>
        Add New User
    </a>
@endsection

@section('content')
    <section class="page-head">
        <div>
            <h1>User Management</h1>
            <p>Manage system access, account status, addresses, and administrative privileges.</p>
        </div>
        <a class="primary-button" href="{{ route('admin.users.create') }}">
            <span class="material-symbols-outlined">person_add</span>
            Add New User
        </a>
    </section>

    @if (session('status'))
        <div class="alert">{{ session('status') }}</div>
    @endif

    <div class="stats">
        <article class="card">
            <div class="metric-label">Total Users</div>
            <div class="metric-value mono">{{ $stats['total'] }}</div>
        </article>
        <article class="card">
            <div class="metric-label">Active</div>
            <div class="metric-value mono">{{ $stats['active'] }}</div>
        </article>
        <article class="card">
            <div class="metric-label">Pending</div>
            <div class="metric-value mono">{{ $stats['pending'] }}</div>
        </article>
        <article class="card">
            <div class="metric-label">Admins</div>
            <div class="metric-value mono">{{ $stats['admins'] }}</div>
        </article>
    </div>

    <section class="stitch-card">
        <form class="stitch-controls" method="GET" action="{{ route('admin.users.index') }}">
            <div class="stitch-search">
                <span class="material-symbols-outlined">search</span>
                <input class="form-control" name="search" value="{{ $filters['search'] }}" placeholder="Search users by name, email, or phone...">
            </div>
            <div class="stitch-filter-group">
                <select class="form-control" name="status" aria-label="Filter by status">
                    <option value="">All Status</option>
                    <option value="active" @selected($filters['status'] === 'active')>Active</option>
                    <option value="pending" @selected($filters['status'] === 'pending')>Pending</option>
                    <option value="inactive" @selected($filters['status'] === 'inactive')>Inactive</option>
                </select>
                <button class="secondary-button" type="submit" aria-label="Filter">
                    <span class="material-symbols-outlined">filter_list</span>
                    Filter
                </button>
                <a class="secondary-button" href="{{ route('admin.users.index') }}">Reset</a>
            </div>
        </form>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th style="width:44px"><input class="checkbox-custom" type="checkbox" aria-label="Select all users"></th>
                        <th>User</th>
                        <th>Address</th>
                        <th>Access</th>
                        <th>Status</th>
                        <th>Last Login</th>
                        <th style="text-align:right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($users as $user)
                        <tr>
                            <td><input class="checkbox-custom" type="checkbox" aria-label="Select {{ $user->name }}"></td>
                            <td>
                                <div class="user-cell">
                                    <div class="user-avatar">{{ strtoupper(substr($user->name, 0, 1)) }}</div>
                                    <div>
                                        <div class="user-name">{{ $user->name }}</div>
                                        <div class="user-email">{{ $user->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>{{ $user->address ?? 'Not provided' }}</td>
                            <td><span class="access-pill">{{ $user->is_admin ? 'Admin Panel' : 'App User' }}</span></td>
                            <td>
                                <span class="status {{ $user->status }}">{{ ucfirst($user->status) }}</span>
                            </td>
                            <td class="mono">{{ $user->last_seen_at?->diffForHumans() ?? 'Never' }}</td>
                            <td>
                                <div class="action-row">
                                    <a class="icon-action" href="{{ route('admin.users.edit', $user) }}" aria-label="Edit {{ $user->name }}">
                                        <span class="material-symbols-outlined">edit</span>
                                    </a>
                                    <form method="POST" action="{{ route('admin.users.destroy', $user) }}" style="margin:0" onsubmit="return confirm(@json('Are you sure you want to delete '.$user->name.'? This action cannot be undone.'));">
                                        @csrf
                                        @method('DELETE')
                                        <button class="icon-action" type="submit" aria-label="Delete {{ $user->name }}" title="Delete user">
                                            <span class="material-symbols-outlined">delete</span>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="muted">No users found for the selected filters.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mobile-list">
            @forelse ($users as $user)
                <article class="mobile-record">
                    <div class="mobile-record-top">
                        <div class="user-cell">
                            <div class="user-avatar">{{ strtoupper(substr($user->name, 0, 1)) }}</div>
                            <div>
                                <div class="mobile-record-title">{{ $user->name }}</div>
                                <div class="mobile-record-subtitle">{{ $user->email }}</div>
                            </div>
                        </div>
                        <span class="status {{ $user->status }}">{{ ucfirst($user->status) }}</span>
                    </div>
                    <div class="mobile-record-meta">
                        <div><span>Access</span><strong>{{ $user->is_admin ? 'Admin Panel' : 'App User' }}</strong></div>
                        <div><span>Address</span><strong>{{ $user->address ?? 'Not provided' }}</strong></div>
                        <div><span>Phone</span><strong>{{ $user->phone ?? 'Not provided' }}</strong></div>
                        <div><span>Last Login</span><strong>{{ $user->last_seen_at?->diffForHumans() ?? 'Never' }}</strong></div>
                    </div>
                    <a class="secondary-button" href="{{ route('admin.users.edit', $user) }}" style="width:100%;margin-top:14px">
                        <span class="material-symbols-outlined">edit</span>
                        Edit User
                    </a>
                    <form method="POST" action="{{ route('admin.users.destroy', $user) }}" style="margin:10px 0 0" onsubmit="return confirm(@json('Are you sure you want to delete '.$user->name.'? This action cannot be undone.'));">
                        @csrf
                        @method('DELETE')
                        <button class="danger-button" type="submit" style="width:100%">
                            <span class="material-symbols-outlined">delete</span>
                            Delete User
                        </button>
                    </form>
                </article>
            @empty
                <article class="mobile-record">
                    <div class="mobile-record-title">No users found</div>
                    <div class="mobile-record-subtitle">Try changing filters or add a new user.</div>
                </article>
            @endforelse
        </div>

        @if ($users->hasPages())
            <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;border-top:1px solid var(--line);background:var(--bg);padding:16px">
                <span class="muted">Showing {{ $users->firstItem() }}-{{ $users->lastItem() }} of {{ $users->total() }}</span>
                <div style="display:flex;gap:8px;flex-wrap:wrap">
                    @if ($users->onFirstPage())
                        <span class="secondary-button" style="opacity:.55;pointer-events:none">Previous</span>
                    @else
                        <a class="secondary-button" href="{{ $users->previousPageUrl() }}">Previous</a>
                    @endif

                    <span class="primary-button">Page {{ $users->currentPage() }} / {{ $users->lastPage() }}</span>

                    @if ($users->hasMorePages())
                        <a class="secondary-button" href="{{ $users->nextPageUrl() }}">Next</a>
                    @else
                        <span class="secondary-button" style="opacity:.55;pointer-events:none">Next</span>
                    @endif
                </div>
            </div>
        @endif
    </section>
@endsection
