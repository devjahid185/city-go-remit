<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Admin') | {{ config('app.name', 'City Go Remit') }}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=JetBrains+Mono:wght@450;500&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">
    <style>
        :root {
            color-scheme: light;
            --bg: #f9f9ff;
            --card: #ffffff;
            --low: #f0f3ff;
            --container: #e7eeff;
            --high: #dee8ff;
            --text: #111c2d;
            --muted: #3f4944;
            --line: #bec9c2;
            --primary: #00503a;
            --primary-strong: #006a4e;
            --primary-soft: #dcefe9;
            --red: #bb0027;
            --red-soft: #ffdad6;
            --radius: 8px;
            --sidebar: 260px;
        }

        * { box-sizing: border-box; }
        html { min-width: 320px; }
        body {
            margin: 0;
            min-height: 100vh;
            background: var(--bg);
            color: var(--text);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 14px;
            line-height: 20px;
        }
        button, input, select { font: inherit; }
        a { color: inherit; }
        .material-symbols-outlined { font-variation-settings: "FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24; }
        .icon-fill { font-variation-settings: "FILL" 1, "wght" 500, "GRAD" 0, "opsz" 24; }
        .mono { font-family: "JetBrains Mono", ui-monospace, SFMono-Regular, Consolas, monospace; }

        .sidebar-toggle { position: fixed; opacity: 0; pointer-events: none; }
        .sidebar {
            position: fixed;
            inset: 0 auto 0 0;
            z-index: 50;
            display: flex;
            width: var(--sidebar);
            min-height: 100vh;
            flex-direction: column;
            border-right: 1px solid var(--line);
            background: var(--bg);
        }
        .sidebar-overlay { display: none; }
        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 16px;
            min-height: 110px;
            border-bottom: 1px solid var(--line);
            padding: 24px;
        }
        .brand-mark {
            display: grid;
            width: 48px;
            height: 48px;
            flex: 0 0 48px;
            place-items: center;
            border-radius: 999px;
            background: var(--primary-strong);
            color: #92e7c3;
            font-size: 17px;
            font-weight: 800;
            text-transform: lowercase;
        }
        .sidebar-brand h1 {
            margin: 0;
            color: var(--primary);
            font-size: 20px;
            font-weight: 800;
            line-height: 26px;
        }
        .sidebar-brand p {
            margin: 2px 0 0;
            color: var(--text);
            font-size: 12px;
            letter-spacing: .08em;
            line-height: 16px;
        }
        .sidebar-close {
            display: none;
            align-items: center;
            justify-content: center;
            position: absolute;
            top: 12px;
            right: 12px;
            width: 42px;
            height: 42px;
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            cursor: pointer;
        }
        .quick-action { padding: 20px 16px; }
        .primary-button, .secondary-button, .danger-button, .top-button {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 44px;
            border-radius: var(--radius);
            gap: 10px;
            padding: 0 16px;
            text-decoration: none;
            font-weight: 800;
            cursor: pointer;
        }
        .primary-button {
            border: 1px solid var(--primary-strong);
            background: var(--primary-strong);
            color: #ffffff;
        }
        .secondary-button, .top-button {
            border: 1px solid var(--line);
            background: var(--card);
            color: var(--text);
        }
        .danger-button {
            border: 1px solid var(--line);
            background: var(--card);
            color: var(--red);
        }
        .primary-button:hover { background: var(--primary); }
        .secondary-button:hover, .danger-button:hover, .top-button:hover { background: var(--low); }

        .sidebar-nav {
            display: flex;
            flex: 1;
            flex-direction: column;
            gap: 4px;
            overflow-y: auto;
            padding: 12px 16px;
        }
        .sidebar-link, .sidebar-logout {
            display: flex;
            align-items: center;
            gap: 12px;
            min-height: 48px;
            border: 0;
            border-left: 4px solid transparent;
            border-radius: 0 var(--radius) var(--radius) 0;
            background: transparent;
            color: var(--muted);
            padding: 0 16px 0 12px;
            text-align: left;
            text-decoration: none;
            font-weight: 700;
            cursor: pointer;
        }
        .sidebar-link.active {
            border-left-color: var(--primary);
            background: var(--high);
            color: var(--primary);
        }
        .sidebar-link:hover, .sidebar-logout:hover { background: var(--low); color: var(--text); }
        .sidebar-footer {
            display: grid;
            gap: 4px;
            border-top: 1px solid var(--line);
            padding: 16px;
        }
        .sidebar-footer form { margin: 0; }

        .page { min-height: 100vh; margin-left: var(--sidebar); }
        .topbar {
            position: sticky;
            top: 0;
            z-index: 40;
            display: flex;
            align-items: center;
            justify-content: space-between;
            min-height: 64px;
            border-bottom: 1px solid var(--line);
            background: var(--bg);
            padding: 0 32px;
        }
        .topbar-left { display: flex; align-items: center; gap: 20px; min-width: 0; }
        .mobile-menu {
            display: none;
            align-items: center;
            justify-content: center;
            width: 42px;
            height: 42px;
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            cursor: pointer;
        }
        .topbar h2 {
            margin: 0;
            color: var(--primary);
            font-size: 22px;
            font-weight: 800;
            line-height: 28px;
            white-space: nowrap;
        }
        .topbar-actions { display: flex; align-items: center; gap: 12px; }
        .avatar {
            display: grid;
            width: 40px;
            height: 40px;
            place-items: center;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: var(--high);
            color: var(--primary);
            font-weight: 800;
            text-decoration: none;
        }
        .main {
            width: min(100%, 1440px);
            padding: 32px;
        }
        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 20px;
            margin-bottom: 24px;
        }
        .page-head h1 {
            margin: 0;
            color: var(--text);
            font-size: 36px;
            font-weight: 800;
            letter-spacing: -.02em;
            line-height: 44px;
        }
        .page-head p {
            margin: 8px 0 0;
            color: var(--muted);
            font-size: 16px;
            line-height: 24px;
        }
        .grid { display: grid; gap: 24px; }
        .grid.two { grid-template-columns: minmax(0, 2fr) minmax(320px, 1fr); }
        .grid.profile { grid-template-columns: 360px minmax(0, 1fr); }
        .stats { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 24px; }
        .card, .panel {
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
        }
        .card { padding: 20px; }
        .metric-label, th, .label {
            color: var(--text);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .08em;
            line-height: 16px;
            text-transform: uppercase;
        }
        .metric-value {
            margin-top: 10px;
            color: var(--text);
            font-size: 34px;
            font-weight: 800;
            letter-spacing: -.02em;
            line-height: 42px;
        }
        .metric-note { display: flex; align-items: center; gap: 6px; margin-top: 12px; color: var(--primary); }
        .metric-note.red { color: var(--red); }
        .panel-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            min-height: 70px;
            border-bottom: 1px solid var(--line);
            padding: 0 22px;
        }
        .panel-header h2 { margin: 0; font-size: 22px; line-height: 28px; }
        .panel-body { padding: 22px; }
        .toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; border-bottom: 1px solid var(--line); padding: 16px 18px; }
        .search {
            min-width: 260px;
            height: 42px;
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            padding: 0 12px;
        }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; min-width: 680px; border-collapse: collapse; }
        thead { background: var(--low); }
        th, td { border-bottom: 1px solid var(--line); padding: 14px 18px; text-align: left; vertical-align: middle; }
        td { color: var(--text); }
        .muted { color: var(--muted); }
        .status {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 4px 10px;
            font-family: "JetBrains Mono", ui-monospace, SFMono-Regular, Consolas, monospace;
            font-size: 13px;
            line-height: 18px;
        }
        .status.active, .status.paid { background: var(--primary-soft); color: var(--primary); }
        .status.pending { background: var(--high); color: var(--muted); }
        .status.inactive, .status.failed { background: var(--red-soft); color: var(--red); }
        .identity { text-align: center; }
        .initial {
            display: grid;
            width: 112px;
            height: 112px;
            margin: 10px auto 18px;
            place-items: center;
            border: 4px solid var(--low);
            border-radius: 999px;
            background: var(--high);
            color: var(--primary);
            font-size: 42px;
            font-weight: 800;
        }
        .identity h2 { margin: 0; font-size: 28px; line-height: 34px; }
        .info-list { display: grid; gap: 18px; }
        .info-row { display: flex; gap: 12px; color: var(--muted); }
        .info-row strong { display: block; color: var(--text); font-weight: 700; overflow-wrap: anywhere; }
        .tabs { display: flex; gap: 20px; border-bottom: 1px solid var(--line); padding: 18px 22px 0; overflow-x: auto; }
        .tabs span { border-bottom: 3px solid transparent; padding-bottom: 16px; font-size: 12px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; white-space: nowrap; }
        .tabs span.active { border-color: var(--primary); color: var(--primary); }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        .field { display: grid; gap: 8px; margin-bottom: 18px; }
        .input-box { min-height: 48px; border: 1px solid var(--line); background: var(--card); padding: 13px 14px; }
        .form-control {
            width: 100%;
            min-height: 46px;
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            color: var(--text);
            padding: 0 12px;
        }
        .form-control:focus {
            border-color: var(--primary-strong);
            outline: 2px solid rgba(0, 106, 78, .18);
        }
        .checkbox-row {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            min-height: 46px;
            color: var(--muted);
            font-weight: 700;
        }
        .checkbox-row input {
            width: 18px;
            height: 18px;
            accent-color: var(--primary-strong);
        }
        .alert {
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--low);
            color: var(--primary);
            margin-bottom: 16px;
            padding: 12px 14px;
            font-weight: 800;
        }
        .error-list {
            border: 1px solid #ffb3b1;
            border-radius: var(--radius);
            background: var(--red-soft);
            color: var(--red);
            margin-bottom: 16px;
            padding: 12px 14px;
            font-weight: 700;
        }
        .error-list ul { margin: 8px 0 0; padding-left: 18px; }
        .stitch-card {
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            overflow: hidden;
        }
        .stitch-controls {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            border-bottom: 1px solid var(--line);
            background: var(--bg);
            padding: 16px;
        }
        .stitch-search {
            position: relative;
            width: min(100%, 360px);
        }
        .stitch-search .material-symbols-outlined {
            position: absolute;
            left: 12px;
            top: 50%;
            color: var(--muted);
            font-size: 20px;
            transform: translateY(-50%);
        }
        .stitch-search input { padding-left: 40px; }
        .stitch-filter-group { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .access-pill {
            display: inline-flex;
            align-items: center;
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            color: var(--muted);
            padding: 5px 10px;
            font-family: "JetBrains Mono", ui-monospace, SFMono-Regular, Consolas, monospace;
            font-size: 13px;
            line-height: 18px;
        }
        .user-cell {
            display: flex;
            align-items: center;
            gap: 12px;
            min-width: 250px;
        }
        .user-avatar {
            display: grid;
            width: 42px;
            height: 42px;
            flex: 0 0 42px;
            place-items: center;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: var(--high);
            color: var(--primary);
            font-weight: 800;
        }
        .user-name { font-weight: 800; }
        .user-email { margin-top: 2px; color: var(--muted); overflow-wrap: anywhere; }
        .action-row { display: flex; align-items: center; justify-content: flex-end; gap: 6px; }
        .icon-action {
            display: inline-grid;
            width: 34px;
            height: 34px;
            place-items: center;
            border: 0;
            border-radius: var(--radius);
            background: transparent;
            color: var(--muted);
            text-decoration: none;
            cursor: pointer;
        }
        .icon-action:hover { background: var(--high); color: var(--primary); }
        .checkbox-custom {
            appearance: none;
            display: grid;
            width: 16px;
            height: 16px;
            place-content: center;
            border: 1px solid var(--line);
            border-radius: 4px;
            background: var(--card);
            cursor: pointer;
        }
        .checkbox-custom::before {
            display: block;
            width: 10px;
            height: 10px;
            content: "";
            transform: scale(0);
            transform-origin: center;
            background: var(--card);
            clip-path: polygon(14% 44%, 0 65%, 50% 100%, 100% 16%, 80% 0%, 43% 62%);
        }
        .checkbox-custom:checked { border-color: var(--primary-strong); background: var(--primary-strong); }
        .checkbox-custom:checked::before { transform: scale(1); }
        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;
            color: var(--muted);
            font-size: 14px;
        }
        .breadcrumb a {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            color: var(--muted);
            text-decoration: none;
        }
        .breadcrumb a:hover { color: var(--primary); }
        .form-card {
            border: 1px solid var(--line);
            border-radius: var(--radius);
            background: var(--card);
            overflow: hidden;
        }
        .form-section {
            border-bottom: 1px solid var(--line);
            padding: 28px;
        }
        .form-section:last-child { border-bottom: 0; }
        .form-section-title {
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 0 0 22px;
            color: var(--text);
            font-size: 20px;
            font-weight: 800;
            line-height: 28px;
        }
        .form-section-title .material-symbols-outlined { color: var(--primary); }
        .profile-upload {
            display: flex;
            align-items: flex-start;
            gap: 24px;
        }
        .profile-photo {
            display: grid;
            width: 128px;
            height: 128px;
            flex: 0 0 128px;
            place-items: center;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: var(--container);
            color: var(--muted);
        }
        .profile-photo .material-symbols-outlined { font-size: 42px; }
        .form-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 12px;
            background: var(--bg);
            padding: 20px 28px;
        }
        .page-subtitle-badge {
            display: inline-flex;
            align-items: center;
            border: 1px solid rgba(131, 215, 180, .45);
            border-radius: 999px;
            background: rgba(131, 215, 180, .14);
            color: var(--primary);
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .04em;
        }
        .chart-bars { display: grid; grid-template-columns: repeat(7, 1fr); align-items: end; gap: 14px; height: 180px; padding: 22px; }
        .bar { border-radius: 3px 3px 0 0; background: #cadfdc; }
        .bar.active { background: var(--primary-strong); }
        .mobile-list, .mobile-summary { display: none; }

        @media (max-width: 1100px) {
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .grid.two, .grid.profile { grid-template-columns: 1fr; }
        }
        @media (max-width: 900px) {
            body { background: var(--card); }
            .sidebar {
                width: min(92vw, 344px);
                transform: translateX(-100%);
                transition: transform .2s ease;
                box-shadow: 8px 0 24px rgba(17, 28, 45, .12);
            }
            .sidebar-toggle:checked ~ .sidebar { transform: translateX(0); }
            .sidebar-overlay { position: fixed; inset: 0; z-index: 45; background: rgba(17,28,45,.38); }
            .sidebar-toggle:checked ~ .sidebar-overlay { display: block; }
            .sidebar-close, .mobile-menu { display: inline-flex; }
            .page { margin-left: 0; }
            .topbar { min-height: 60px; background: var(--card); padding: 0 16px; }
            .topbar h2 { font-size: 20px; }
            .top-button.hide-mobile { display: none; }
            .main { padding: 20px 16px 32px; }
            .page-head {
                border: 1px solid var(--line);
                border-radius: var(--radius);
                background: var(--card);
                flex-direction: column;
                margin-bottom: 16px;
                padding: 20px;
            }
            .page-head h1 { font-size: 28px; line-height: 36px; }
            .page-head p { font-size: 14px; line-height: 20px; }
            .toolbar { align-items: stretch; flex-direction: column; }
            .search, .toolbar .primary-button { width: 100%; min-width: 0; }
            .stitch-controls { align-items: stretch; flex-direction: column; }
            .stitch-search { width: 100%; }
            .stitch-filter-group { display: grid; grid-template-columns: 1fr 1fr; width: 100%; }
            .stitch-filter-group .form-control, .stitch-filter-group .primary-button, .stitch-filter-group .secondary-button { width: 100%; }
            .profile-upload { flex-direction: column; }
        }
        @media (max-width: 640px) {
            .sidebar-brand { min-height: 96px; padding: 20px; }
            .quick-action { padding: 16px; }
            .sidebar-nav { padding: 8px 12px; }
            .sidebar-link, .sidebar-logout { min-height: 52px; font-size: 15px; }
            .stats { grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 16px; }
            .card { padding: 16px; }
            .metric-value { font-size: 28px; line-height: 34px; }
            .panel-header { align-items: flex-start; flex-direction: column; justify-content: center; gap: 6px; min-height: 84px; }
            .table-wrap { display: none; }
            .mobile-list { display: grid; gap: 10px; padding: 14px; }
            .mobile-record {
                border: 1px solid var(--line);
                border-radius: var(--radius);
                background: var(--card);
                padding: 14px;
            }
            .mobile-record-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
            .mobile-record-title { font-weight: 800; }
            .mobile-record-subtitle { margin-top: 3px; color: var(--muted); overflow-wrap: anywhere; }
            .mobile-record-meta {
                display: grid;
                grid-template-columns: repeat(2, minmax(0, 1fr));
                gap: 10px;
                border-top: 1px solid var(--line);
                margin-top: 12px;
                padding-top: 12px;
            }
            .mobile-record-meta span { display: block; color: var(--muted); font-size: 11px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }
            .mobile-record-meta strong { display: block; margin-top: 4px; font-family: "JetBrains Mono", ui-monospace, SFMono-Regular, Consolas, monospace; font-size: 13px; }
            .form-grid { grid-template-columns: 1fr; gap: 0; }
            .form-section { padding: 20px; }
            .form-actions { align-items: stretch; flex-direction: column-reverse; padding: 16px 20px; }
            .form-actions .primary-button, .form-actions .secondary-button { width: 100%; }
            .stitch-filter-group { grid-template-columns: 1fr; }
            .chart-bars { height: 150px; gap: 10px; padding: 18px; }
        }
        @media (max-width: 380px) {
            .stats, .mobile-record-meta { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <input class="sidebar-toggle" id="sidebar-toggle" type="checkbox" aria-label="Toggle sidebar">
    @include('admin.partials.sidebar')
    <label class="sidebar-overlay" for="sidebar-toggle" aria-label="Close sidebar overlay"></label>

    <div class="page">
        <header class="topbar">
            <div class="topbar-left">
                <label class="mobile-menu" for="sidebar-toggle" aria-label="Open menu">
                    <span class="material-symbols-outlined">menu</span>
                </label>
                <h2>@yield('topbar', 'Admin Panel')</h2>
            </div>
            <div class="topbar-actions">
                @yield('topbar_actions')
                <a class="avatar" href="{{ route('admin.profile') }}" title="{{ auth()->user()->email }}">
                    {{ strtoupper(substr(auth()->user()->name, 0, 1)) }}
                </a>
            </div>
        </header>

        <main class="main">
            @yield('content')
        </main>
    </div>
</body>
</html>
