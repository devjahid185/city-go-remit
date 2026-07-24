<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ChatController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $conversation = $this->conversationForEmail($data['email']);
        if ($response = $this->blockedChatResponse($conversation)) {
            return $response;
        }

        $this->markSeen($conversation, 'user');

        return response()->json([
            'message' => 'Chat loaded successfully.',
            'conversation' => $this->conversationPayload($conversation->fresh()),
            'messages' => $this->messagesPayload($conversation),
        ]);
    }

    public function send(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'message' => ['nullable', 'string', 'max:2000', 'required_without:image'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $conversation = $this->conversationForEmail($data['email']);
        if ($response = $this->blockedChatResponse($conversation)) {
            return $response;
        }

        $attachment = $this->storeAttachment($request);

        $message = ChatMessage::query()->create([
            'chat_conversation_id' => $conversation->id,
            'sender_id' => $conversation->user_id,
            'sender_type' => 'user',
            'sender_name' => $conversation->user_name ?: 'App User',
            'message' => trim($data['message'] ?? ''),
            ...$attachment,
            'delivered_at' => now(),
        ]);

        $conversation->update([
            'status' => 'open',
            'user_typing_at' => null,
            'last_message_at' => now(),
        ]);

        return response()->json([
            'message' => 'Message sent successfully.',
            'chat_message' => $this->messagePayload($message),
            'conversation' => $this->conversationPayload($conversation->fresh()),
        ], 201);
    }

    public function typing(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $conversation = $this->conversationForEmail($data['email']);
        if ($response = $this->blockedChatResponse($conversation)) {
            return $response;
        }
        $conversation->update(['user_typing_at' => now()]);

        return response()->json(['message' => 'Typing status updated.']);
    }

    public function seen(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $conversation = $this->conversationForEmail($data['email']);
        if ($response = $this->blockedChatResponse($conversation)) {
            return $response;
        }
        $this->markSeen($conversation, 'user');

        return response()->json(['message' => 'Messages marked as seen.']);
    }

    public function attachment(ChatMessage $message)
    {
        if (! $message->attachment_path || ! Storage::disk('public')->exists($message->attachment_path)) {
            abort(404);
        }

        return Storage::disk('public')->response(
            $message->attachment_path,
            $message->attachment_name ?: basename($message->attachment_path),
            ['Content-Type' => $message->attachment_mime ?: 'application/octet-stream'],
        );
    }

    private function conversationForEmail(string $email): ChatConversation
    {
        $user = User::query()->where('email', $email)->first();

        return ChatConversation::query()->firstOrCreate(
            ['email' => $email],
            [
                'user_id' => $user?->id,
                'user_name' => $user?->name,
                'user_phone' => $user?->phone,
                'status' => 'open',
                'last_message_at' => now(),
            ],
        );
    }

    private function blockedChatResponse(ChatConversation $conversation): ?JsonResponse
    {
        $user = $conversation->user ?: User::query()->where('email', $conversation->email)->first();

        if (! $user) {
            return null;
        }

        if ($user->isBanned()) {
            return response()->json([
                'message' => 'Your account has been banned. Please contact support.',
                'account_banned' => true,
            ], 403);
        }

        if ($user->isChatBanned()) {
            return response()->json([
                'message' => 'Live chat is temporarily unavailable for your account.',
                'chat_banned' => true,
            ], 403);
        }

        return null;
    }

    private function markSeen(ChatConversation $conversation, string $viewer): void
    {
        ChatMessage::query()
            ->where('chat_conversation_id', $conversation->id)
            ->where('sender_type', $viewer === 'user' ? 'admin' : 'user')
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
            'unread_for_user' => ChatMessage::query()
                ->where('chat_conversation_id', $conversation->id)
                ->where('sender_type', 'admin')
                ->whereNull('seen_at')
                ->count(),
        ];
    }

    private function messagesPayload(ChatConversation $conversation): array
    {
        return $conversation->messages()
            ->oldest()
            ->limit(100)
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
