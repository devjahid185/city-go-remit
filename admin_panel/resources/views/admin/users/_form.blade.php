@php
    $editing = isset($user);
    $selectedStatus = old('status', $user->status ?? 'active');
@endphp

@if ($errors->any())
    <div class="error-list">
        Please fix the form errors.
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<div class="form-section">
    <div class="profile-upload">
        <div class="profile-photo">
            @if ($editing)
                <strong style="font-size:42px;color:var(--primary)">{{ strtoupper(substr($user->name, 0, 1)) }}</strong>
            @else
                <span class="material-symbols-outlined">person</span>
            @endif
        </div>
        <div style="padding-top:12px">
            <h3 class="form-section-title" style="margin-bottom:8px">
                <span class="material-symbols-outlined">photo_camera</span>
                Profile Photo
            </h3>
            <p class="muted" style="margin:0 0 16px">Photo upload is not enabled yet. This placeholder keeps the admin record layout consistent.</p>
            <div style="display:flex;gap:10px;flex-wrap:wrap">
                <button class="secondary-button" type="button">Upload Image</button>
                <button class="danger-button" type="button">Remove</button>
            </div>
        </div>
    </div>
</div>

<div class="form-section">
    <h3 class="form-section-title">
        <span class="material-symbols-outlined">badge</span>
        Personal Information
    </h3>
    <div class="form-grid">
        <div class="field">
            <label class="label" for="name">Full Name *</label>
            <input class="form-control" id="name" name="name" value="{{ old('name', $user->name ?? '') }}" placeholder="Enter full name" required>
        </div>
        <div class="field">
            <label class="label" for="email">Email Address *</label>
            <input class="form-control" id="email" name="email" type="email" value="{{ old('email', $user->email ?? '') }}" placeholder="Enter email address" required>
        </div>
        <div class="field">
            <label class="label" for="phone">Phone Number</label>
            <input class="form-control" id="phone" name="phone" value="{{ old('phone', $user->phone ?? '') }}" placeholder="+880 1XXX-XXXXXX">
        </div>
        <div class="field">
            <label class="label" for="address">Address</label>
            <input class="form-control" id="address" name="address" value="{{ old('address', $user->address ?? 'Dhaka, Bangladesh') }}" placeholder="House, Road, City">
        </div>
    </div>
</div>

<div class="form-section">
    <h3 class="form-section-title">
        <span class="material-symbols-outlined">admin_panel_settings</span>
        Security & Access
    </h3>
    <div class="form-grid">
        <div class="field">
            <label class="label" for="password">{{ $editing ? 'New Password' : 'Password *' }}</label>
            <input class="form-control" id="password" name="password" type="password" placeholder="{{ $editing ? 'Leave blank to keep current password' : 'Generate or type password' }}" @required(! $editing)>
            @if ($editing)
                <small class="muted">Leave blank to keep the current password.</small>
            @endif
        </div>
        <div class="field">
            <label class="label" for="password_confirmation">Confirm Password{{ $editing ? '' : ' *' }}</label>
            <input class="form-control" id="password_confirmation" name="password_confirmation" type="password" placeholder="Repeat password" @required(! $editing)>
        </div>
        <div class="field">
            <label class="label" for="status">Account Status *</label>
            <select class="form-control" id="status" name="status" required>
                <option value="active" @selected($selectedStatus === 'active')>Active</option>
                <option value="pending" @selected($selectedStatus === 'pending')>Pending</option>
                <option value="inactive" @selected($selectedStatus === 'inactive')>Inactive</option>
            </select>
        </div>
        <div class="field">
            <span class="label">Admin Privileges</span>
            <label class="checkbox-row">
                <input class="checkbox-custom" type="checkbox" name="is_admin" value="1" @checked(old('is_admin', $user->is_admin ?? false))>
                Give admin panel access
            </label>
        </div>
    </div>
</div>
