<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriveOfferOrder extends Model
{
    protected $fillable = [
        'drive_offer_id',
        'user_id',
        'email',
        'mobile_number',
        'operator',
        'offer_title',
        'data_amount',
        'validity',
        'price',
        'service_charge',
        'total_amount',
        'transaction_id',
        'status',
        'reviewed_by',
        'admin_note',
        'debited_at',
        'processed_at',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'service_charge' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'debited_at' => 'datetime',
            'processed_at' => 'datetime',
        ];
    }

    public function offer(): BelongsTo
    {
        return $this->belongsTo(DriveOffer::class, 'drive_offer_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
