<?php

namespace App\Http\Middleware;

use App\Models\AdminApiToken;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminApiToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $plainToken = $request->bearerToken();

        if (! $plainToken) {
            return response()->json(['message' => 'Authentication token is required.'], 401);
        }

        $accessToken = AdminApiToken::query()
            ->with('user')
            ->where('token_hash', hash('sha256', $plainToken))
            ->first();

        if (! $accessToken || ($accessToken->expires_at && $accessToken->expires_at->isPast())) {
            return response()->json(['message' => 'Invalid or expired admin token.'], 401);
        }

        if (! $accessToken->user?->is_admin) {
            return response()->json(['message' => 'Admin access is required.'], 403);
        }

        $accessToken->forceFill(['last_used_at' => now()])->save();

        Auth::setUser($accessToken->user);
        $request->setUserResolver(fn () => $accessToken->user);
        $request->attributes->set('admin_api_token', $accessToken);

        return $next($request);
    }
}
