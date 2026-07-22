@php($active = trim($__env->yieldContent('active')))

<aside class="sidebar" aria-label="Admin sidebar">
    <label class="sidebar-close" for="sidebar-toggle" aria-label="Close menu">
        <span class="material-symbols-outlined">close</span>
    </label>

    <div class="sidebar-brand">
        <div class="brand-mark">bd</div>
        <div>
            <h1>Admin Panel</h1>
            <p>IQBAL SYSTEM</p>
        </div>
    </div>

    <div class="quick-action">
        <a class="primary-button" href="#">
            <span class="material-symbols-outlined">add</span>
            New Entry
        </a>
    </div>

    <nav class="sidebar-nav">
        <a class="sidebar-link {{ $active === 'dashboard' ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">
            <span class="material-symbols-outlined {{ $active === 'dashboard' ? 'icon-fill' : '' }}">dashboard</span>
            Dashboard
        </a>
        <a class="sidebar-link {{ $active === 'users' ? 'active' : '' }}" href="{{ route('admin.users.index') }}">
            <span class="material-symbols-outlined {{ $active === 'users' ? 'icon-fill' : '' }}">group</span>
            Users
        </a>
        <a class="sidebar-link" href="#">
            <span class="material-symbols-outlined">description</span>
            Reports
        </a>
        <a class="sidebar-link" href="#">
            <span class="material-symbols-outlined">payments</span>
            Transactions
        </a>
        <a class="sidebar-link {{ $active === 'profile' ? 'active' : '' }}" href="{{ route('admin.profile') }}">
            <span class="material-symbols-outlined {{ $active === 'profile' ? 'icon-fill' : '' }}">settings</span>
            Profile
        </a>
    </nav>

    <div class="sidebar-footer">
        <a class="sidebar-link" href="#">
            <span class="material-symbols-outlined">help</span>
            Support
        </a>
        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button class="sidebar-logout" type="submit">
                <span class="material-symbols-outlined">logout</span>
                Logout
            </button>
        </form>
    </div>
</aside>
