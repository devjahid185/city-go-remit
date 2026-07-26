# City Go Remit React Admin

Standalone React + Tailwind admin panel for the Laravel API backend.

## Setup

1. Copy `.env.example` to `.env`.
2. Set `VITE_API_BASE_URL` to the same Laravel API URL used by the Flutter app.
3. Run `npm install`.
4. Run `npm run dev`.

Laravel backend needs the admin API token migration:

```bash
php artisan migrate
```

Default API endpoints used by this app:

- `POST /api/admin/login`
- `GET /api/admin/me`
- `POST /api/admin/logout`
- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `POST /api/admin/users`
- `PUT /api/admin/users/{user}`
- `DELETE /api/admin/users/{user}`
- `GET /api/admin/recharges`
- `GET /api/admin/recharges/{recharge}`
- `PUT /api/admin/recharges/{recharge}`
