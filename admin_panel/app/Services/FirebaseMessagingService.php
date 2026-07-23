<?php

namespace App\Services;

use App\Models\FirebaseDeviceToken;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FirebaseMessagingService
{
    public function sendToTokens(iterable $tokens, string $title, string $body, array $data = []): array
    {
        $success = 0;
        $failed = 0;

        foreach ($tokens as $token) {
            if (! is_string($token) || trim($token) === '') {
                continue;
            }

            $sent = $this->sendToToken($token, $title, $body, $data);
            $sent ? $success++ : $failed++;
        }

        return compact('success', 'failed');
    }

    public function sendToUser(int $userId, string $title, string $body, array $data = []): array
    {
        $tokens = FirebaseDeviceToken::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->pluck('token');

        Log::info('Firebase send to user requested.', [
            'user_id' => $userId,
            'token_count' => $tokens->count(),
            'title' => $title,
        ]);

        return $this->sendToTokens($tokens, $title, $body, $data);
    }

    public function sendToEmail(string $email, string $title, string $body, array $data = []): array
    {
        $tokens = FirebaseDeviceToken::query()
            ->where('email', $email)
            ->where('is_active', true)
            ->pluck('token');

        Log::info('Firebase send to email requested.', [
            'email' => $email,
            'token_count' => $tokens->count(),
            'title' => $title,
        ]);

        return $this->sendToTokens($tokens, $title, $body, $data);
    }

    public function sendToToken(string $token, string $title, string $body, array $data = []): bool
    {
        try {
            $projectId = $this->projectId();
            $response = Http::withToken($this->accessToken())
                ->timeout(12)
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'data' => collect($data)
                            ->map(fn ($value) => is_scalar($value) ? (string) $value : json_encode($value))
                            ->toArray(),
                        'android' => [
                            'priority' => 'HIGH',
                            'notification' => [
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ]);

            if ($response->successful()) {
                return true;
            }

            Log::warning('Firebase message failed.', [
                'status' => $response->status(),
                'body' => $response->json(),
            ]);
        } catch (\Throwable $exception) {
            Log::warning('Firebase message exception.', [
                'message' => $exception->getMessage(),
            ]);
        }

        return false;
    }

    private function accessToken(): string
    {
        return Cache::remember('firebase_messaging_access_token', now()->addMinutes(50), function (): string {
            $credentials = $this->credentials();
            $now = time();
            $jwt = $this->jwt([
                'iss' => $credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ], $credentials['private_key']);

            $response = Http::asForm()
                ->timeout(12)
                ->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

            if (! $response->successful()) {
                throw new RuntimeException('Could not generate Firebase access token.');
            }

            return $response->json('access_token');
        });
    }

    private function jwt(array $payload, string $privateKey): string
    {
        $segments = [
            $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])),
            $this->base64Url(json_encode($payload)),
        ];

        openssl_sign(implode('.', $segments), $signature, $privateKey, OPENSSL_ALGO_SHA256);
        $segments[] = $this->base64Url($signature);

        return implode('.', $segments);
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function credentials(): array
    {
        $path = config('services.firebase.credentials');

        if (! $path || ! is_file($path)) {
            throw new RuntimeException('Firebase credentials file was not found.');
        }

        $credentials = json_decode(file_get_contents($path), true);

        if (! is_array($credentials) || empty($credentials['private_key']) || empty($credentials['client_email'])) {
            throw new RuntimeException('Firebase credentials file is invalid.');
        }

        return $credentials;
    }

    private function projectId(): string
    {
        $projectId = config('services.firebase.project_id') ?: ($this->credentials()['project_id'] ?? null);

        if (! $projectId) {
            throw new RuntimeException('Firebase project id is missing.');
        }

        return $projectId;
    }
}
