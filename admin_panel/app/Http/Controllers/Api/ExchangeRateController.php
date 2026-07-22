<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ExchangeRate;
use Illuminate\Http\JsonResponse;

class ExchangeRateController extends Controller
{
    public function index(): JsonResponse
    {
        $rates = ExchangeRate::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('country_name')
            ->get();

        return response()->json([
            'message' => 'Exchange rates loaded successfully.',
            'base_currency' => 'BDT',
            'rates' => $rates,
        ]);
    }
}
