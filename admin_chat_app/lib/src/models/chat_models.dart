class AdminUser {
  const AdminUser({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      name: json['name']?.toString() ?? 'Admin',
      email: json['email']?.toString() ?? '',
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.email,
    required this.userName,
    required this.userPhone,
    required this.status,
    required this.unreadForAdmin,
    required this.userTyping,
    required this.chatBanned,
    this.lastMessageAt,
    this.latestMessage,
  });

  final int id;
  final String email;
  final String userName;
  final String userPhone;
  final String status;
  final int unreadForAdmin;
  final bool userTyping;
  final bool chatBanned;
  final DateTime? lastMessageAt;
  final ChatMessage? latestMessage;

  factory ChatConversation.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final messages = json['messages'] is List ? json['messages'] as List : const [];
    return ChatConversation(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      email: json['email']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Customer',
      userPhone: json['user_phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      unreadForAdmin: int.tryParse(json['unread_for_admin']?.toString() ?? '') ?? 0,
      userTyping: _asBool(json['user_typing']),
      chatBanned: _asBool(json['chat_banned']),
      lastMessageAt: DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
      latestMessage: messages.isEmpty
          ? null
          : ChatMessage.fromJson(
              messages.first as Map<String, dynamic>? ?? {},
              baseUrl: baseUrl,
            ),
    );
  }
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim() ?? '';
  return text == '1' || text == 'true' || text == 'yes';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.message,
    this.attachmentUrl,
    this.attachmentName,
    this.createdAt,
    this.seenAt,
  });

  final int id;
  final String senderType;
  final String senderName;
  final String message;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? createdAt;
  final DateTime? seenAt;

  bool get isAdmin => senderType == 'admin';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    return ChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'user',
      senderName: json['sender_name']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      attachmentUrl: _attachmentUrl(json, baseUrl),
      attachmentName: json['attachment_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      seenAt: DateTime.tryParse(json['seen_at']?.toString() ?? ''),
    );
  }
}

String? _attachmentUrl(Map<String, dynamic> json, String? baseUrl) {
  final raw = (json['attachment_api_url'] ?? json['attachment_url'])?.toString().trim();
  if (raw == null || raw.isEmpty) return null;

  if (baseUrl == null || baseUrl.trim().isEmpty) return raw;

  final base = Uri.tryParse(baseUrl.trim());
  final uri = Uri.tryParse(raw);
  if (base == null || uri == null || !base.hasScheme || base.host.isEmpty) {
    return raw;
  }

  final origin = Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
  );

  if (!uri.hasScheme) {
    return origin.replace(path: raw.startsWith('/') ? raw : '/$raw').toString();
  }

  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    return uri
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        )
        .toString();
  }

  return raw;
}
