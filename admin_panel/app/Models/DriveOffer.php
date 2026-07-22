<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DriveOffer extends Model
{
    protected $fillable = [
        'operator',
        'title',
        'offer_type',
        'data_amount',
        'minutes',
        'sms',
        'validity',
        'price',
        'service_charge',
        'activation_code',
        'source_note',
        'description',
        'is_featured',
        'is_active',
        'sort_order',
        'starts_at',
        'ends_at',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'service_charge' => 'decimal:2',
            'is_featured' => 'boolean',
            'is_active' => 'boolean',
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(DriveOfferOrder::class);
    }
}
