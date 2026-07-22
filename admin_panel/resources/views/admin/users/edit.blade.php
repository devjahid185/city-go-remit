@extends('admin.layouts.app')

@section('title', 'Edit User')
@section('topbar', 'Edit User')
@section('active', 'users')

@section('topbar_actions')
    <a class="secondary-button hide-mobile" href="{{ route('admin.users.index') }}">
        <span class="material-symbols-outlined">arrow_back</span>
        Back
    </a>
@endsection

@section('content')
    <div class="breadcrumb">
        <a href="{{ route('admin.users.index') }}">
            <span class="material-symbols-outlined" style="font-size:16px">group</span>
            Users Directory
        </a>
        <span class="material-symbols-outlined" style="font-size:16px">chevron_right</span>
        <span>Edit Record</span>
    </div>

    <section class="page-head">
        <div>
            <h1 style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
                {{ $user->name }}
                <span class="page-subtitle-badge">{{ ucfirst($user->status) }} Account</span>
            </h1>
            <p>Manage personal details, address, account status, and platform access.</p>
        </div>
    </section>

    <section class="form-card">
        <form method="POST" action="{{ route('admin.users.update', $user) }}">
            @csrf
            @method('PUT')
            @include('admin.users._form', ['user' => $user])
            <div class="form-actions">
                <a class="secondary-button" href="{{ route('admin.users.index') }}">Cancel</a>
                <button class="primary-button" type="submit">
                    <span class="material-symbols-outlined">save</span>
                    Save Changes
                </button>
            </div>
        </form>
    </section>
@endsection
