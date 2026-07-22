@extends('admin.layouts.app')

@section('title', 'Dashboard')
@section('topbar', 'Admin Dashboard')
@section('active', 'dashboard')

@section('topbar_actions')
    <a class="top-button hide-mobile" href="#">
        <span class="material-symbols-outlined">download</span>
        Download Report
    </a>
@endsection

@section('content')
    <section class="page-head">
        <div>
            <h1>Welcome back, {{ auth()->user()->name }}</h1>
            <p>Today is {{ now()->format('F d, Y') }}</p>
        </div>
        <a class="secondary-button" href="#">
            <span class="material-symbols-outlined">download</span>
            Download Report
        </a>
    </section>

    <section class="stats">
        <article class="card">
            <div class="metric-label">Admin Users</div>
            <div class="metric-value mono">{{ number_format($stats['admins']) }}</div>
            <div class="metric-note"><span class="material-symbols-outlined" style="font-size:18px">trending_up</span>Access protected</div>
        </article>
        <article class="card">
            <div class="metric-label">Total Users</div>
            <div class="metric-value mono">{{ number_format($stats['users']) }}</div>
            <div class="metric-note"><span class="material-symbols-outlined" style="font-size:18px">database</span>MySQL backed</div>
        </article>
        <article class="card">
            <div class="metric-label">Active Sessions</div>
            <div class="metric-value mono">{{ number_format($stats['sessions']) }}</div>
            <div class="metric-note red"><span class="material-symbols-outlined" style="font-size:18px">priority_high</span>Live admin traffic</div>
        </article>
        <article class="card">
            <div class="metric-label">Queued Jobs</div>
            <div class="metric-value mono">{{ number_format($stats['jobs']) }}</div>
            <div class="metric-note muted"><span class="material-symbols-outlined" style="font-size:18px">remove</span>Stable metric</div>
        </article>
    </section>

    <section class="grid two">
        <article class="panel">
            <div class="panel-header">
                <h2>Recent Admin Accounts</h2>
                <a class="muted" href="{{ route('admin.users.index') }}">View All</a>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>ID</th>
                            <th>Email</th>
                            <th>Status</th>
                            <th>Created</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($recentAdmins as $admin)
                            <tr>
                                <td>{{ $admin->name }}</td>
                                <td class="mono">AD-{{ str_pad((string) $loop->iteration, 4, '0', STR_PAD_LEFT) }}</td>
                                <td>{{ $admin->email }}</td>
                                <td><span class="status active">Active</span></td>
                                <td class="mono">{{ $admin->created_at?->format('d M, h:i A') }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="5">No admin accounts found.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
            <div class="mobile-list">
                @forelse ($recentAdmins as $admin)
                    <article class="mobile-record">
                        <div class="mobile-record-top">
                            <div>
                                <div class="mobile-record-title">{{ $admin->name }}</div>
                                <div class="mobile-record-subtitle">{{ $admin->email }}</div>
                            </div>
                            <span class="status active">Active</span>
                        </div>
                        <div class="mobile-record-meta">
                            <div><span>ID</span><strong>AD-{{ str_pad((string) $loop->iteration, 4, '0', STR_PAD_LEFT) }}</strong></div>
                            <div><span>Created</span><strong>{{ $admin->created_at?->format('d M, h:i A') }}</strong></div>
                        </div>
                    </article>
                @empty
                    <article class="mobile-record">No admin accounts found.</article>
                @endforelse
            </div>
        </article>

        <aside class="panel">
            <div class="panel-header">
                <h2>Quick Analytics</h2>
            </div>
            <div class="chart-bars">
                <div class="bar" style="height:47%"></div>
                <div class="bar" style="height:70%"></div>
                <div class="bar" style="height:35%"></div>
                <div class="bar active" style="height:100%"></div>
                <div class="bar" style="height:65%"></div>
                <div class="bar" style="height:52%"></div>
                <div class="bar" style="height:24%"></div>
            </div>
            <div class="panel-body">
                <div class="card">
                    <div class="metric-label">Top Region</div>
                    <div style="margin-top:8px;font-size:16px">Dhaka Division</div>
                </div>
            </div>
        </aside>
    </section>
@endsection
