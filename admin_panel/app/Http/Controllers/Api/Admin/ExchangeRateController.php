<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ExchangeRate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ExchangeRateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = ExchangeRate::query()
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search')->toString();
                $query->where(function ($query) use ($search): void {
                    $query->where('country_name', 'like', "%{$search}%")
                        ->orWhere('country_code', 'like', "%{$search}%")
                        ->orWhere('currency_code', 'like', "%{$search}%")
                        ->orWhere('currency_name', 'like', "%{$search}%");
                });
            })
            ->when($request->filled('status') && $request->status !== 'all', function ($query) use ($request): void {
                $query->where('is_active', $request->status === 'active');
            });

        $rates = (clone $query)
            ->orderBy('sort_order')
            ->orderBy('country_name')
            ->paginate(15)
            ->withQueryString();

        return response()->json([
            'message' => 'Exchange rates loaded successfully.',
            'stats' => [
                'total' => ExchangeRate::query()->count(),
                'active' => ExchangeRate::query()->where('is_active', true)->count(),
                'inactive' => ExchangeRate::query()->where('is_active', false)->count(),
                'average_rate' => round((float) ExchangeRate::query()->avg('bdt_rate'), 2),
            ],
            'rates' => $rates,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $rate = ExchangeRate::query()->create($this->validated($request));

        return response()->json([
            'message' => 'Exchange rate created successfully.',
            'rate' => $rate,
        ], 201);
    }

    public function update(Request $request, ExchangeRate $exchangeRate): JsonResponse
    {
        $exchangeRate->update($this->validated($request, $exchangeRate));

        return response()->json([
            'message' => 'Exchange rate updated successfully.',
            'rate' => $exchangeRate->fresh(),
        ]);
    }

    public function destroy(ExchangeRate $exchangeRate): JsonResponse
    {
        $exchangeRate->delete();

        return response()->json([
            'message' => 'Exchange rate deleted successfully.',
        ]);
    }

    private function validated(Request $request, ?ExchangeRate $exchangeRate = null): array
    {
        $data = $request->validate([
            'country_name' => ['required', 'string', 'max:120'],
            'country_code' => [
                'required',
                'string',
                'max:8',
                Rule::unique('exchange_rates', 'country_code')
                    ->where(fn ($query) => $query->where('currency_code', strtoupper((string) $request->input('currency_code'))))
                    ->ignore($exchangeRate?->id),
            ],
            'country_flag' => ['nullable', 'string', 'max:12'],
            'currency_code' => ['required', 'string', 'max:8'],
            'currency_name' => ['nullable', 'string', 'max:120'],
            'bdt_rate' => ['required', 'numeric', 'min:0.0001', 'max:9999999'],
            'service_fee' => ['nullable', 'numeric', 'min:0', 'max:9999999'],
            'delivery_time' => ['nullable', 'string', 'max:120'],
            'note' => ['nullable', 'string', 'max:1000'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:999999'],
        ]);

        $data['country_code'] = strtoupper($data['country_code']);
        $data['currency_code'] = strtoupper($data['currency_code']);
        $data['service_fee'] = $data['service_fee'] ?? 0;
        $data['sort_order'] = $data['sort_order'] ?? 0;

        return $data;
    }
}
