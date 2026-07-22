@extends('admin.layouts.app')

@section('title', 'Add User')
@section('topbar', 'Add User')
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
            <span class="material-symbols-outlined" style="font-size:16px">arrow_back</span>
            Back to Users
        </a>
    </div>

    <section class="page-head">
        <div>
            <h1>Add New User</h1>
            <p>Create a new user profile with address, account status, and access credentials.</p>
        </div>
    </section>

    <section class="form-card">
        <form method="POST" action="{{ route('admin.users.store') }}">
            @csrf
            @include('admin.users._form')
            <div class="form-actions">
                <a class="secondary-button" href="{{ route('admin.users.index') }}">Cancel</a>
                <button class="primary-button" type="submit">
                    <span class="material-symbols-outlined">save</span>
                    Save User
                </button>
            </div>
        </form>
    </section>
@endsection
