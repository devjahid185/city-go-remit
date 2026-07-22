<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceLoginLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SecurityController extends Controller
{
    public function devices(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        return response()->json([
            'message' => 'Device history loaded successfully.',
            'devices' => DeviceLoginLog::query()
                ->where('email', $data['email'])
                ->latest('logged_in_at')
                ->limit(20)
                ->get(),
        ]);
    }
}
