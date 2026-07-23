<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Login | {{ config('app.name', 'City Go Remit') }}</title>
    <link rel="icon" type="image/png" href="{{ asset('assets/brand/favicon.png') }}">
    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=JetBrains+Mono:wght@450&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">
    <style>
        :root {
            color-scheme: light;
            --surface: #f9f9ff;
            --surface-lowest: #ffffff;
            --surface-low: #f0f3ff;
            --surface-container: #e7eeff;
            --on-surface: #111c2d;
            --on-surface-variant: #3f4944;
            --outline: #6f7a73;
            --outline-variant: #bec9c2;
            --primary: #00503a;
            --primary-container: #006a4e;
            --on-primary: #ffffff;
            --secondary: #bb0027;
            --error-container: #ffdad6;
            --radius: 8px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            display: grid;
            min-height: 100svh;
            margin: 0;
            place-items: center;
            background: var(--surface);
            color: var(--on-surface);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 14px;
            line-height: 20px;
            padding: 16px;
        }

        button,
        input {
            font: inherit;
        }

        .material-symbols-outlined {
            font-variation-settings: "FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24;
        }

        .login-card {
            display: flex;
            width: min(420px, 100%);
            flex-direction: column;
            gap: 32px;
            border: 1px solid var(--outline-variant);
            border-radius: var(--radius);
            background: var(--surface-lowest);
            padding: 32px;
        }

        .login-head {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 16px;
            text-align: center;
        }

        .login-icon {
            display: block;
            width: 64px;
            height: 64px;
            border: 1px solid var(--outline-variant);
            border-radius: var(--radius);
            background: var(--surface-container);
            object-fit: cover;
            box-shadow: 0 12px 26px rgba(17, 28, 45, .10);
        }

        h1 {
            margin: 0;
            color: var(--on-surface);
            font-size: 22px;
            font-weight: 800;
            line-height: 28px;
        }

        .subtitle {
            margin: 4px 0 0;
            color: var(--on-surface-variant);
            font-size: 14px;
            line-height: 20px;
        }

        form {
            display: flex;
            flex-direction: column;
            gap: 24px;
            margin: 0;
        }

        .fields {
            display: grid;
            gap: 16px;
        }

        .field {
            display: grid;
            gap: 6px;
        }

        label,
        .footer {
            font-size: 12px;
            font-weight: 700;
            letter-spacing: .08em;
            line-height: 16px;
            text-transform: uppercase;
        }

        label {
            color: var(--on-surface);
        }

        input[type="email"],
        input[type="password"] {
            width: 100%;
            height: 48px;
            border: 1px solid var(--outline-variant);
            border-radius: var(--radius);
            background: var(--surface-lowest);
            color: var(--on-surface);
            padding: 0 14px;
        }

        input::placeholder {
            color: var(--outline);
        }

        input:focus {
            border-color: var(--primary-container);
            outline: 2px solid rgba(0, 106, 78, .18);
            outline-offset: 0;
        }

        .form-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            margin-top: -8px;
        }

        .remember {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: var(--on-surface-variant);
            font-size: 14px;
            letter-spacing: 0;
            text-transform: none;
            font-weight: 400;
        }

        input[type="checkbox"] {
            width: 18px;
            height: 18px;
            accent-color: var(--primary-container);
        }

        .forgot {
            color: var(--primary-container);
            text-decoration: none;
            white-space: nowrap;
        }

        .forgot:hover {
            color: var(--primary);
            text-decoration: underline;
        }

        .error {
            border: 1px solid #ffb3b1;
            border-radius: var(--radius);
            background: var(--error-container);
            color: var(--secondary);
            padding: 12px;
            font-weight: 700;
        }

        .submit {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            height: 48px;
            border: 1px solid var(--primary-container);
            border-radius: var(--radius);
            background: var(--primary-container);
            color: var(--on-primary);
            cursor: pointer;
            gap: 10px;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        .submit:hover {
            background: var(--primary);
        }

        .footer {
            border-top: 1px solid var(--outline-variant);
            color: var(--outline);
            padding-top: 24px;
            text-align: center;
        }

        @media (max-width: 440px) {
            body {
                align-items: stretch;
                padding: 12px;
            }

            .login-card {
                justify-content: center;
                min-height: calc(100svh - 24px);
                gap: 24px;
                padding: 24px 18px;
            }

            .form-row {
                align-items: flex-start;
                flex-direction: column;
                gap: 10px;
            }

            input[type="email"],
            input[type="password"],
            .submit {
                height: 52px;
            }
        }

        @media (max-width: 360px) {
            .login-card {
                padding-inline: 14px;
            }

            h1 {
                font-size: 20px;
                line-height: 26px;
            }

            .login-icon {
                width: 56px;
                height: 56px;
            }
        }
    </style>
</head>
<body>
    <main class="login-card">
        <section class="login-head">
            <img class="login-icon" src="{{ asset('assets/brand/logo.png') }}" alt="{{ config('app.name', 'City Go Remit') }} logo">
            <div>
                <h1>City Go Remit Administrative System</h1>
                <p class="subtitle">Sign in to access your administrative workspace.</p>
            </div>
        </section>

        @if ($errors->any())
            <div class="error">{{ $errors->first() }}</div>
        @endif

        <form method="POST" action="{{ route('admin.login.store') }}">
            @csrf
            <div class="fields">
                <div class="field">
                    <label for="email">Corporate Email</label>
                    <input id="email" name="email" type="email" value="{{ old('email') }}" placeholder="admin@iqbal.local" autocomplete="email" required autofocus>
                </div>

                <div class="field">
                    <label for="password">Password</label>
                    <input id="password" name="password" type="password" placeholder="••••••••" autocomplete="current-password" required>
                </div>
            </div>

            <div class="form-row">
                <label class="remember" for="remember">
                    <input id="remember" type="checkbox" name="remember" value="1">
                    Remember Me
                </label>
            </div>

            <button class="submit" type="submit">
                <span class="material-symbols-outlined" style="font-size:18px">login</span>
                Authenticate
            </button>
        </form>

        <div class="footer">Secure Access Portal © {{ now()->year }}</div>
    </main>
</body>
</html>
