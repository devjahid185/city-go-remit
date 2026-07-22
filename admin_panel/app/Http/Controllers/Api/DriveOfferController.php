<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriveOffer;
use App\Models\DriveOfferOrder;
use App\Models\OtpVerification;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class DriveOfferController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'operator' => ['nullable', 'string', 'max:40'],
            'type' => ['nullable', 'string', 'max:40'],
        ]);

        $offers = DriveOffer::query()
            ->where('is_active', true)
            ->where(function ($query): void {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query): void {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            })
            ->when($filters['operator'] ?? null, fn ($query, string $operator) => $query->where('operator', $operator))
            ->when($filters['type'] ?? null, fn ($query, string $type) => $query->where('offer_type', $type))
            ->orderByDesc('is_featured')
            ->orderBy('sort_order')
            ->orderBy('price')
            ->get()
            ->map(fn (DriveOffer $offer): array => $this->offerPayload($offer));

        return response()->json([
            'message' => 'Drive offers loaded successfully.',
            'operators' => $this->operators(),
            'offers' => $offers,
        ]);
    }

    public function requestOtp(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedOrderData($request);
        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $offer = DriveOffer::query()
            ->whereKey($data['drive_offer_id'])
            ->where('is_active', true)
            ->first();

        if (! $offer) {
            return response()->json(['message' => 'Selected offer is not available right now.'], 422);
        }

        if ($offer->operator !== $data['operator']) {
            return response()->json(['message' => 'Mobile number operator does not match the selected offer.'], 422);
        }

        $payload = [
            ...$data,
            'offer_title' => $offer->title,
            'data_amount' => $offer->data_amount,
            'validity' => $offer->validity,
            'price' => (float) $offer->price,
            'service_charge' => (float) $offer->service_charge,
            'total_amount' => (float) $offer->price + (float) $offer->service_charge,
        ];

        if ((float) $user->balance < (float) $payload['total_amount']) {
            return response()->json([
                'message' => 'Insufficient balance for this internet offer.',
                'balance' => $user->balance,
                'required_amount' => $payload['total_amount'],
            ], 422);
        }

        $otpService->issue($user->email, OtpService::DRIVE_OFFER, $payload);

        return response()->json([
            'message' => 'An internet offer confirmation OTP has been sent to your email.',
            'charge' => $payload['service_charge'],
            'total_amount' => $payload['total_amount'],
        ]);
    }

    public function confirm(Request $request, OtpService $otpService): JsonResponse
    {
        $data = $this->validatedOrderData($request);
        $otpData = $request->validate(['otp' => ['required', 'digits:6']]);

        $verification = $otpService->verify($data['email'], OtpService::DRIVE_OFFER, $otpData['otp']);

        if (! $verification) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $payload = $verification->payload ?? [];
        foreach (['drive_offer_id', 'mobile_number', 'operator'] as $field) {
            if ((string) ($payload[$field] ?? '') !== (string) ($data[$field] ?? '')) {
                return response()->json(['message' => 'Offer details do not match the OTP request.'], 422);
            }
        }

        $user = $this->activeUser($data['email']);

        if (! $user) {
            return response()->json(['message' => 'Active user account was not found.'], 422);
        }

        $order = DB::transaction(function () use ($payload, $user): DriveOfferOrder {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->first();

            if (! $lockedUser || (float) $lockedUser->balance < (float) $payload['total_amount']) {
                abort(response()->json([
                    'message' => 'Insufficient balance for this internet offer.',
                    'balance' => $lockedUser?->balance ?? 0,
                    'required_amount' => $payload['total_amount'],
                ], 422));
            }

            $lockedUser->decrement('balance', (float) $payload['total_amount']);

            return DriveOfferOrder::query()->create([
                ...$payload,
                'user_id' => $lockedUser->id,
                'email' => $lockedUser->email,
                'transaction_id' => 'DO'.now()->format('ymdHis').Str::upper(Str::random(6)),
                'status' => 'pending',
                'debited_at' => now(),
            ]);
        });

        OtpVerification::query()->whereKey($verification->id)->delete();

        return response()->json([
            'message' => 'Internet offer request submitted successfully and is waiting for admin approval.',
            'drive_offer_order' => $this->orderPayload($order),
        ], 201);
    }

    public function orders(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        $orders = DriveOfferOrder::query()
            ->where('email', $data['email'])
            ->latest()
            ->limit(30)
            ->get()
            ->map(fn (DriveOfferOrder $order): array => $this->orderPayload($order));

        return response()->json([
            'message' => 'Internet offer history loaded.',
            'drive_offer_orders' => $orders,
        ]);
    }

    private function validatedOrderData(Request $request): array
    {
        return $request->validate([
            'email' => ['required', 'email'],
            'drive_offer_id' => ['required', 'integer'],
            'mobile_number' => ['required', 'digits:11'],
            'operator' => ['required', 'string', Rule::in($this->operators())],
        ]);
    }

    private function activeUser(string $email): ?User
    {
        return User::query()
            ->where('email', $email)
            ->where('status', 'active')
            ->first();
    }

    private function operators(): array
    {
        return ['Grameenphone', 'Robi', 'Airtel', 'Banglalink', 'Teletalk'];
    }

    private function offerPayload(DriveOffer $offer): array
    {
        return [
            'id' => $offer->id,
            'operator' => $offer->operator,
            'title' => $offer->title,
            'offer_type' => $offer->offer_type,
            'data_amount' => $offer->data_amount,
            'minutes' => $offer->minutes,
            'sms' => $offer->sms,
            'validity' => $offer->validity,
            'price' => $offer->price,
            'service_charge' => $offer->service_charge,
            'total_amount' => (float) $offer->price + (float) $offer->service_charge,
            'activation_code' => $offer->activation_code,
            'source_note' => $offer->source_note,
            'description' => $offer->description,
            'is_featured' => $offer->is_featured,
        ];
    }

    private function orderPayload(DriveOfferOrder $order): array
    {
        return [
            'transaction_id' => $order->transaction_id,
            'mobile_number' => $order->mobile_number,
            'operator' => $order->operator,
            'offer_title' => $order->offer_title,
            'data_amount' => $order->data_amount,
            'validity' => $order->validity,
            'price' => $order->price,
            'service_charge' => $order->service_charge,
            'total_amount' => $order->total_amount,
            'status' => $order->status,
            'processed_at' => $order->processed_at?->toISOString(),
        ];
    }
}
