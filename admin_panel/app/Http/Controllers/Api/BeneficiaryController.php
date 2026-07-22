<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Beneficiary;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BeneficiaryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'type' => ['nullable', Rule::in($this->types())],
        ]);

        $beneficiaries = Beneficiary::query()
            ->where('email', $data['email'])
            ->when($data['type'] ?? null, fn ($query, string $type) => $query->where('type', $type))
            ->orderByDesc('is_favorite')
            ->latest()
            ->get();

        return response()->json([
            'message' => 'Beneficiaries loaded successfully.',
            'types' => $this->types(),
            'beneficiaries' => $beneficiaries,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validatedData($request);
        $user = User::query()->where('email', $data['email'])->first();
        $data['user_id'] = $user?->id;

        $beneficiary = Beneficiary::query()->updateOrCreate(
            $this->lookup($data),
            $data,
        );

        return response()->json([
            'message' => 'Beneficiary saved successfully.',
            'beneficiary' => $beneficiary,
        ], 201);
    }

    public function update(Request $request, Beneficiary $beneficiary): JsonResponse
    {
        $data = $this->validatedData($request);

        if ($beneficiary->email !== $data['email']) {
            return response()->json(['message' => 'Beneficiary does not belong to this user.'], 403);
        }

        $beneficiary->update($data);

        return response()->json([
            'message' => 'Beneficiary updated successfully.',
            'beneficiary' => $beneficiary->fresh(),
        ]);
    }

    public function destroy(Request $request, Beneficiary $beneficiary): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        if ($beneficiary->email !== $data['email']) {
            return response()->json(['message' => 'Beneficiary does not belong to this user.'], 403);
        }

        $beneficiary->delete();

        return response()->json(['message' => 'Beneficiary removed successfully.']);
    }

    private function validatedData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'type' => ['required', Rule::in($this->types())],
            'label' => ['required', 'string', 'max:120'],
            'provider' => ['nullable', 'string', 'max:120'],
            'account_name' => ['nullable', 'string', 'max:120'],
            'account_number' => ['nullable', 'string', 'max:80'],
            'mobile_number' => ['nullable', 'string', 'max:30'],
            'meta' => ['nullable', 'array'],
            'is_favorite' => ['nullable', 'boolean'],
        ]);
    }

    private function types(): array
    {
        return ['recharge', 'bill', 'bank'];
    }

    private function lookup(array $data): array
    {
        return match ($data['type']) {
            'recharge' => [
                'email' => $data['email'],
                'type' => $data['type'],
                'mobile_number' => $data['mobile_number'] ?? null,
            ],
            'bill' => [
                'email' => $data['email'],
                'type' => $data['type'],
                'provider' => $data['provider'] ?? null,
                'account_number' => $data['account_number'] ?? null,
            ],
            default => [
                'email' => $data['email'],
                'type' => $data['type'],
                'provider' => $data['provider'] ?? null,
                'account_number' => $data['account_number'] ?? null,
            ],
        };
    }
}
