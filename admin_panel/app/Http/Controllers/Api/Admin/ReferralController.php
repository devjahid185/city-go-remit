<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReferralController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'message' => 'Referral settings loaded successfully.',
            'settings' => $this->settings(),
            'stats' => [
                'referred_users' => User::query()->whereNotNull('referred_by_user_id')->count(),
                'total_bonus' => (float) User::query()->sum('referral_bonus_earned'),
            ],
            'recent_referrals' => User::query()
                ->whereNotNull('referred_by_user_id')
                ->with('referredBy:id,name,email,referral_code')
                ->latest()
                ->limit(25)
                ->get(['id', 'name', 'email', 'referred_by_user_id', 'referral_bonus_earned', 'created_at']),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'referral_enabled' => ['required', 'boolean'],
            'referral_referrer_bonus' => ['required', 'numeric', 'min:0', 'max:100000'],
            'referral_new_user_bonus' => ['required', 'numeric', 'min:0', 'max:100000'],
        ]);

        foreach ($data as $key => $value) {
            AppSetting::put($key, is_bool($value) ? (int) $value : $value);
        }

        return response()->json([
            'message' => 'Referral settings updated successfully.',
            'settings' => $this->settings(),
        ]);
    }

    private function settings(): array
    {
        return [
            'referral_enabled' => AppSetting::value('referral_enabled', '1') === '1',
            'referral_referrer_bonus' => (float) AppSetting::value('referral_referrer_bonus', 25),
            'referral_new_user_bonus' => (float) AppSetting::value('referral_new_user_bonus', 10),
        ];
    }
}
