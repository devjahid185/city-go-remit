<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChatConversation extends Model
{
    protected $fillable = [
        'user_id',
        'email',
        'user_name',
        'user_phone',
        'assigned_admin_id',
        'status',
        'user_typing_at',
        'admin_typing_at',
        'user_last_seen_at',
        'admin_last_seen_at',
        'last_message_at',
    ];

    protected function casts(): array
    {
        return [
            'user_typing_at' => 'datetime',
            'admin_typing_at' => 'datetime',
            'user_last_seen_at' => 'datetime',
            'admin_last_seen_at' => 'datetime',
            'last_message_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function assignedAdmin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_admin_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(ChatMessage::class);
    }
}
