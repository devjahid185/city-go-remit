<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExchangeRate extends Model
{
    use HasFactory;

    protected $fillable = [
        'country_name',
        'country_code',
        'country_flag',
        'currency_code',
        'currency_name',
        'bdt_rate',
        'service_fee',
        'delivery_time',
        'note',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'bdt_rate' => 'decimal:4',
        'service_fee' => 'decimal:2',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];
}
