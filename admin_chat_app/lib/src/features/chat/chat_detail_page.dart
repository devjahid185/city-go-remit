import 'dart:async';
import 'dart:typed_data';

import 'package:admin_chat_app/src/core/app_colors.dart';
import 'package:admin_chat_app/src/core/safe_message.dart';
import 'package:admin_chat_app/src/models/chat_models.dart';
import 'package:admin_chat_app/src/services/admin_api.dart';
import 'package:admin_chat_app/src/services/session_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    required this.session,
    required this.conversationId,
    super.key,
  });

  final AdminSession session;
  final int conversationId;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  final _api = AdminApi();
  final _message = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  ChatConversation? _conversation;
  List<ChatMessage> _messages = [];
  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = true;
  bool _sending = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _startPolling();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _load(silent: true);
      });
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent) setState(() => _loading = true);
    final result = await _api.conversation(
      token: widget.session.token,
      id: widget.conversationId,
    );
    if (!mounted) return;
    _fetching = false;
    if (!result.ok) {
      setState(() => _loading = false);
      if (!silent) _show(result.message);
      return;
    }

    final data = result.data ?? {};
    final messages = data['messages'] is List ? data['messages'] as List : const [];
    setState(() {
      _conversation = ChatConversation.fromJson(
        data['conversation'] as Map<String, dynamic>? ?? {},
        baseUrl: _api.baseUrl,
      );
      _messages = messages
          .map((item) => ChatMessage.fromJson(
                item as Map<String, dynamic>? ?? {},
                baseUrl: _api.baseUrl,
              ))
          .toList();
      _loading = false;
    });
    _jumpToEnd();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    setState(() {
      _imageBytes = file.bytes;
      _imageName = file.name;
    });
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final result = await _api.sendMessage(
      token: widget.session.token,
      id: widget.conversationId,
      message: text,
      imageBytes: _imageBytes,
      imageName: _imageName,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (!result.ok) {
      _show(result.message);
      return;
    }
    _message.clear();
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
    await _load(silent: true);
  }

  Future<void> _changeStatus(String status) async {
    final result = await _api.updateStatus(
      token: widget.session.token,
      id: widget.conversationId,
      status: status,
    );
    if (!mounted) return;
    _show(result.message);
    if (result.ok) _load(silent: true);
  }

  Future<void> _toggleBan() async {
    final conversation = _conversation;
    if (conversation == null) return;
    final banned = !conversation.chatBanned;
    final result = await _api.toggleChatBan(
      token: widget.session.token,
      id: widget.conversationId,
      banned: banned,
    );
    if (!mounted) return;
    _show(result.message);
    if (result.ok) _load(silent: true);
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safeMessageText(message))));
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.userName ?? 'Conversation'),
        actions: [
          IconButton(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'ban') {
                _toggleBan();
              } else {
                _changeStatus(value);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Mark Open')),
              const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
              const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
              const PopupMenuItem(value: 'closed', child: Text('Mark Closed')),
              PopupMenuItem(
                value: 'ban',
                child: Text(conversation?.chatBanned == true ? 'Unban Chat' : 'Ban Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (conversation != null) _ConversationHeader(conversation: conversation),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                  ),
          ),
          _Composer(
            controller: _message,
            sending: _sending,
            imageBytes: _imageBytes,
            imageName: _imageName,
            onPickImage: _pickImage,
            onRemoveImage: () => setState(() {
              _imageBytes = null;
              _imageName = null;
            }),
            onSend: _send,
            onTyping: () => _api.typing(
              token: widget.session.token,
              id: widget.conversationId,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: .08),
            child: Text(
              conversation.userName.trim().isEmpty
                  ? 'U'
                  : conversation.userName.trim().substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  conversation.userPhone.isNotEmpty
                      ? conversation.userPhone
                      : conversation.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: conversation.chatBanned ? 'Banned' : conversation.status,
            danger: conversation.chatBanned,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.primary : Colors.white,
          border: Border.all(color: isAdmin ? AppColors.primary : AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasAttachment) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.attachmentUrl!,
                  headers: const {
                    'Accept': 'image/*',
                    'ngrok-skip-browser-warning': 'true',
                  },
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: isAdmin ? Colors.white.withValues(alpha: .12) : AppColors.surfaceLow,
                    child: Text(
                      'Image not available',
                      style: TextStyle(color: isAdmin ? Colors.white : AppColors.muted),
                    ),
                    );
                  },
                ),
              ),
              if (message.message.trim().isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.message.trim().isNotEmpty)
              Text(
                message.message,
                style: TextStyle(
                  color: isAdmin ? Colors.white : AppColors.ink,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 5),
            Text(
              _time(message.createdAt),
              style: TextStyle(
                color: isAdmin ? Colors.white.withValues(alpha: .72) : AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime? value) {
    if (value == null) return '';
    final hour = value.toLocal().hour.toString().padLeft(2, '0');
    final minute = value.toLocal().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.imageBytes,
    required this.imageName,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSend,
    required this.onTyping,
  });

  final TextEditingController controller;
  final bool sending;
  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSend;
  final VoidCallback onTyping;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  DateTime? _lastTyping;

  void _typing() {
    final now = DateTime.now();
    if (_lastTyping != null && now.difference(_lastTyping!) < const Duration(seconds: 2)) {
      return;
    }
    _lastTyping = now;
    widget.onTyping();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.imageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        widget.imageBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.imageName ?? 'Selected image',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onRemoveImage,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: widget.sending ? null : widget.onPickImage,
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (_) => _typing(),
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: FilledButton(
                    onPressed: widget.sending ? null : widget.onSend,
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    child: widget.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: danger ? AppColors.primary.withValues(alpha: .08) : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.primary : AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
