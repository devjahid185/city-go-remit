@extends('admin.layouts.app')

@section('title', 'Profile')
@section('topbar', 'Profile')
@section('active', 'profile')

@section('topbar_actions')
    <a class="top-button hide-mobile" href="{{ route('admin.dashboard') }}">Dashboard</a>
@endsection

@section('content')
    <section class="page-head">
        <div>
            <h1>Profile Settings</h1>
            <p>Manage your account credentials, preferences, and activity details.</p>
        </div>
    </section>

    <section class="grid profile">
        <aside>
            <article class="card identity">
                <div class="initial">{{ strtoupper(substr($admin->name, 0, 1)) }}</div>
                <h2>{{ $admin->name }}</h2>
                <div class="page-subtitle-badge" style="margin-top:10px">{{ $admin->is_admin ? 'Admin Panel Access' : 'App User' }}</div>
                <p class="muted">{{ $admin->address ?? 'Dhaka, Bangladesh' }}</p>
                <a class="primary-button" href="#" style="width:100%;margin-top:22px">
                    <span class="material-symbols-outlined">lock_reset</span>
                    Change Password
                </a>
                <form method="POST" action="{{ route('admin.logout') }}" style="margin:10px 0 0">
                    @csrf
                    <button class="secondary-button" type="submit" style="width:100%">
                        <span class="material-symbols-outlined">logout</span>
                        Sign Out
                    </button>
                </form>
            </article>

            <article class="card" style="margin-top:24px">
                <h2 style="margin:0 0 16px">Contact Details</h2>
                <div class="info-list">
                    <div class="info-row"><span class="material-symbols-outlined">mail</span><div>Email Address<strong>{{ $admin->email }}</strong></div></div>
                    <div class="info-row"><span class="material-symbols-outlined">call</span><div>Phone Number<strong>{{ $admin->phone ?? 'Not provided' }}</strong></div></div>
                    <div class="info-row"><span class="material-symbols-outlined">home_pin</span><div>Address<strong>{{ $admin->address ?? 'Not provided' }}</strong></div></div>
                </div>
            </article>
        </aside>

        <article class="panel">
            <div class="tabs">
                <span class="active">Personal Information</span>
                <span>Security Settings</span>
                <span>Activity Logs</span>
            </div>
            <div class="panel-body">
                <h2 style="margin:0 0 20px">Basic Information</h2>
                <div class="form-grid">
                    <div class="field"><label class="label">Name</label><div class="input-box">{{ $admin->name }}</div></div>
                    <div class="field"><label class="label">Access</label><div class="input-box">{{ $admin->is_admin ? 'Admin Panel' : 'App User' }}</div></div>
                </div>
                <div class="field"><label class="label">Email</label><div class="input-box">{{ $admin->email }}</div></div>
                <div class="form-grid">
                    <div class="field"><label class="label">Timezone</label><div class="input-box">(GMT+06:00) Dhaka</div></div>
                    <div class="field"><label class="label">Language</label><div class="input-box">English (UK)</div></div>
                </div>
                <div style="display:flex;justify-content:flex-end;gap:14px;border-top:1px solid var(--line);padding-top:24px">
                    <button class="secondary-button" type="button">Discard Changes</button>
                    <button class="primary-button" type="button">Save Modifications</button>
                </div>
            </div>
        </article>
    </section>
@endsection
