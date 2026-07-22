<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Services\FirebaseMessagingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ChatController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses())],
        ]);

        $conversations = ChatConversation::query()
            ->with(['user:id,name,email,phone', 'messages' => fn ($query) => $query->latest()->limit(5)])
            ->withCount([
                'messages as unread_for_admin' => fn ($query) => $query
                    ->where('sender_type', 'user')
                    ->whereNull('seen_at'),
            ])
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('email', 'like', "%{$search}%")
                        ->orWhere('user_name', 'like', "%{$search}%")
                        ->orWhere('user_phone', 'like', "%{$search}%");
                });
            })
            ->when($filters['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->orderByDesc('last_message_at')
            ->paginate(20);

        return response()->json([
            'statuses' => $this->statuses(),
            'conversations' => $conversations,
        ]);
    }

    public function show(ChatConversation $conversation): JsonResponse
    {
        $this->markSeen($conversation, 'admin');

        return response()->json([
            'conversation' => $this->conversationPayload($conversation->fresh()),
            'messages' => $this->messagesPayload($conversation),
        ]);
    }

    public function send(Request $request, ChatConversation $conversation, FirebaseMessagingService $firebase): JsonResponse
    {
        $data = $request->validate([
            'message' => ['nullable', 'string', 'max:2000', 'required_without:image'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $admin = $request->user();
        $attachment = $this->storeAttachment($request);

        $message = ChatMessage::query()->create([
            'chat_conversation_id' => $conversation->id,
            'sender_id' => $admin?->id,
            'sender_type' => 'admin',
            'sender_name' => $admin?->name ?: 'Support Admin',
            'message' => trim($data['message'] ?? ''),
            ...$attachment,
            'delivered_at' => now(),
        ]);

        $conversation->update([
            'assigned_admin_id' => $admin?->id,
            'admin_typing_at' => null,
            'last_message_at' => now(),
        ]);

        $this->notifyUser($conversation->fresh(), $message, $firebase);

        return response()->json([
            'message' => 'Message sent successfully.',
            'chat_message' => $this->messagePayload($message),
            'conversation' => $this->conversationPayload($conversation->fresh()),
        ], 201);
    }

    public function typing(Request $request, ChatConversation $conversation): JsonResponse
    {
        $conversation->update([
            'assigned_admin_id' => $request->user()?->id,
            'admin_typing_at' => now(),
        ]);

        return response()->json(['message' => 'Typing status updated.']);
    }

    public function seen(ChatConversation $conversation): JsonResponse
    {
        $this->markSeen($conversation, 'admin');

        return response()->json(['message' => 'Messages marked as seen.']);
    }

    public function update(Request $request, ChatConversation $conversation): JsonResponse
    {
        $data = $request->validate(['status' => ['required', Rule::in($this->statuses())]]);
        $conversation->update($data);

        return response()->json([
            'message' => 'Conversation updated successfully.',
            'conversation' => $this->conversationPayload($conversation->fresh()),
        ]);
    }

    private function markSeen(ChatConversation $conversation, string $viewer): void
    {
        ChatMessage::query()
            ->where('chat_conversation_id', $conversation->id)
            ->where('sender_type', $viewer === 'admin' ? 'user' : 'admin')
            ->whereNull('seen_at')
            ->update(['seen_at' => now()]);

        $conversation->update([
            $viewer.'_last_seen_at' => now(),
        ]);
    }

    private function conversationPayload(ChatConversation $conversation): array
    {
        return [
            'id' => $conversation->id,
            'email' => $conversation->email,
            'user_name' => $conversation->user_name,
            'user_phone' => $conversation->user_phone,
            'status' => $conversation->status,
            'admin_typing' => $conversation->admin_typing_at?->gt(now()->subSeconds(5)) ?? false,
            'user_typing' => $conversation->user_typing_at?->gt(now()->subSeconds(5)) ?? false,
            'last_message_at' => $conversation->last_message_at?->toISOString(),
            'unread_for_admin' => ChatMessage::query()
                ->where('chat_conversation_id', $conversation->id)
                ->where('sender_type', 'user')
                ->whereNull('seen_at')
                ->count(),
        ];
    }

    private function messagesPayload(ChatConversation $conversation): array
    {
        return $conversation->messages()
            ->oldest()
            ->limit(120)
            ->get()
            ->map(fn (ChatMessage $message): array => $this->messagePayload($message))
            ->all();
    }

    private function messagePayload(ChatMessage $message): array
    {
        return [
            'id' => $message->id,
            'sender_type' => $message->sender_type,
            'sender_name' => $message->sender_name,
            'message' => $message->message,
            'attachment_url' => $message->attachment_path ? $message->attachment_url : null,
            'attachment_api_url' => $message->attachment_path ? route('api.chat.attachment', $message) : null,
            'attachment_name' => $message->attachment_name,
            'attachment_mime' => $message->attachment_mime,
            'delivered_at' => $message->delivered_at?->toISOString(),
            'seen_at' => $message->seen_at?->toISOString(),
            'created_at' => $message->created_at?->toISOString(),
        ];
    }

    private function statuses(): array
    {
        return ['open', 'pending', 'resolved', 'closed'];
    }

    private function notifyUser(ChatConversation $conversation, ChatMessage $message, FirebaseMessagingService $firebase): void
    {
        $body = trim($message->message) ?: ($message->attachment_path ? 'Sent you an image.' : 'Sent you a new message.');
        $payload = [
            'type' => 'chat_message',
            'conversation_id' => $conversation->id,
            'message_id' => $message->id,
        ];

        AppNotification::query()->create([
            'user_id' => $conversation->user_id,
            'email' => $conversation->email,
            'title' => 'New support message',
            'body' => $body,
            'type' => 'chat_message',
            'data' => $payload,
        ]);

        if ($conversation->user_id) {
            $firebase->sendToUser($conversation->user_id, 'New support message', $body, $payload);

            return;
        }

        $firebase->sendToEmail($conversation->email, 'New support message', $body, $payload);
    }

    private function storeAttachment(Request $request): array
    {
        if (! $request->hasFile('image')) {
            return [];
        }

        $file = $request->file('image');
        $path = $file->store('chat', 'public');

        return [
            'attachment_path' => $path,
            'attachment_url' => $request->getSchemeAndHttpHost().Storage::url($path),
            'attachment_name' => $file->getClientOriginalName(),
            'attachment_mime' => $file->getMimeType(),
        ];
    }
}
