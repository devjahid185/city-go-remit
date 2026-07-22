<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Beneficiary extends Model
{
    protected $fillable = [
        'user_id',
        'email',
        'type',
        'label',
        'provider',
        'account_name',
        'account_number',
        'mobile_number',
        'meta',
        'is_favorite',
    ];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
            'is_favorite' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
