<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    protected $fillable = [
        'chat_conversation_id',
        'sender_id',
        'sender_type',
        'sender_name',
        'message',
        'attachment_path',
        'attachment_url',
        'attachment_name',
        'attachment_mime',
        'delivered_at',
        'seen_at',
    ];

    protected function casts(): array
    {
        return [
            'delivered_at' => 'datetime',
            'seen_at' => 'datetime',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(ChatConversation::class, 'chat_conversation_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
