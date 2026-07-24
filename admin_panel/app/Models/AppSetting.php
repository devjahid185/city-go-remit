<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppSetting extends Model
{
    protected $fillable = [
        'key',
        'value',
    ];

    public static function value(string $key, mixed $default = null): mixed
    {
        return static::query()->where('key', $key)->value('value') ?? $default;
    }

    public static function put(string $key, mixed $value): void
    {
        static::query()->updateOrCreate(['key' => $key], ['value' => (string) $value]);
    }

    public static function bool(string $key, bool $default = false): bool
    {
        return filter_var(static::value($key, $default ? '1' : '0'), FILTER_VALIDATE_BOOLEAN);
    }

    public static function float(string $key, float $default = 0): float
    {
        return (float) static::value($key, (string) $default);
    }
}
