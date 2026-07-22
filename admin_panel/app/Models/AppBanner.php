<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppBanner extends Model
{
    protected $fillable = [
        'title',
        'subtitle',
        'image_path',
        'button_text',
        'action_type',
        'action_value',
        'is_active',
        'sort_order',
        'starts_at',
        'ends_at',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }
}
