<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BankTransfer extends Model
{
    protected $fillable = [
        'user_id',
        'email',
        'bank_name',
        'branch_name',
        'account_name',
        'account_number',
        'routing_number',
        'contact_number',
        'amount',
        'charge',
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
            'amount' => 'decimal:2',
            'charge' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'debited_at' => 'datetime',
            'processed_at' => 'datetime',
        ];
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
