import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/auth/account_blocked_page.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final _api = AuthApi();
  final _message = TextEditingController();
  final _scroll = ScrollController();
  Timer? _pollTimer;
  Timer? _typingTimer;
  String _email = '';
  bool _loading = true;
  bool _sending = false;
  bool _adminTyping = false;
  bool _chatBlocked = false;
  int? _lastMessageId;
  DateTime? _lastTypingToneAt;
  EditedChatImage? _imageDraft;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final session = await const SessionStore().load();
    _email = session.userEmail.trim();
    if (_email.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppMessage(context, AppText.t('missing_email'));
      return;
    }

    await _loadChat();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadChat(silent: true));
  }

  Future<void> _loadChat({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    final result = await _api.chat(email: _email);
    if (!mounted) return;

    if (!result.ok) {
      final chatBlocked = result.data['chat_banned'] == true;
      final accountBanned = result.data['account_banned'] == true;
      setState(() {
        _loading = false;
        _chatBlocked = chatBlocked;
      });
      if (accountBanned) {
        await const SessionStore().signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AccountBlockedPage()),
          (_) => false,
        );
      } else if (chatBlocked) {
        _pollTimer?.cancel();
      } else {
        showAppMessage(context, result.message);
      }
      return;
    }

    final conversation = result.data['conversation'] as Map<String, dynamic>? ?? {};
    final messages = result.data['messages'] as List<dynamic>? ?? [];

    final parsedMessages = messages
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
    final latestMessage = parsedMessages.isEmpty ? null : parsedMessages.last;
    final nextAdminTyping = conversation['admin_typing'] == true;

    if (silent && latestMessage != null && latestMessage.id != _lastMessageId && latestMessage.senderType == 'admin') {
      _playReceiveTone();
    }

    if (silent && nextAdminTyping && !_adminTyping) {
      _playTypingTone();
    }

    setState(() {
      _adminTyping = conversation['admin_typing'] == true;
      _messages = parsedMessages;
      _lastMessageId = latestMessage?.id ?? _lastMessageId;
      _loading = false;
      _chatBlocked = false;
    });

    await _api.markChatSeen(email: _email);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if ((text.isEmpty && _imageDraft == null) || _sending || _chatBlocked) return;

    setState(() => _sending = true);
    final result = await _api.sendChatMessage(
      email: _email,
      message: text,
      imageBytes: _imageDraft?.bytes,
      imageName: _imageDraft?.name,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (!result.ok) {
      showAppMessage(context, result.message);
      return;
    }

    _playSendTone();
    _message.clear();
    setState(() => _imageDraft = null);
    await _loadChat(silent: true);
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null || !mounted) return;

    final edited = await Navigator.of(context).push<EditedChatImage>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChatImageEditorPage(
          imageBytes: file!.bytes!,
          fileName: file.name,
        ),
      ),
    );

    if (edited == null || !mounted) return;
    setState(() => _imageDraft = edited);
  }

  void _onTyping(String value) {
    if (_email.isEmpty || value.trim().isEmpty || _chatBlocked) return;
    _playTypingTone();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 350), () {
      _api.sendChatTyping(email: _email);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _playTypingTone() {
    final now = DateTime.now();
    if (_lastTypingToneAt != null && now.difference(_lastTypingToneAt!).inMilliseconds < 850) {
      return;
    }
    _lastTypingToneAt = now;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void _playSendTone() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  void _playReceiveTone() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(AppText.t('live_chat'), style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: Text(AppText.t('chat_loading'), style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500)))
                : _chatBlocked
                    ? const _ChatBlocked()
                    : _messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        itemBuilder: (context, index) {
                          if (_adminTyping && index == _messages.length) {
                            return const _TypingBubble();
                          }
                          return _MessageBubble(message: _messages[index]);
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemCount: _messages.length + (_adminTyping ? 1 : 0),
                      ),
          ),
          if (!_chatBlocked)
            SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.financeLine)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.financeSurfaceLow,
                      foregroundColor: AppColors.financePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_imageDraft != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.financeSurfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.financeLine),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(_imageDraft!.bytes, width: 46, height: 46, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_imageDraft!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500)),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _imageDraft = null),
                                  icon: const Icon(Icons.close_rounded),
                                  color: AppColors.financeMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                        TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 4,
                          onChanged: _onTyping,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: AppText.t('chat_input_hint'),
                            filled: true,
                            fillColor: AppColors.financeSurfaceLow,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.financeLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.financeLine),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.financePrimary, width: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.financePrimary,
                      minimumSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.financePrimary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.financePrimary),
            ),
            const SizedBox(height: 14),
            Text(AppText.t('chat_empty'), style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 7),
            Text(AppText.t('chat_empty_body'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.financeMuted, height: 1.4, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ChatBlocked extends StatelessWidget {
  const _ChatBlocked();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.financeLine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.financePrimary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: AppColors.financePrimary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppText.t('chat_blocked'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.senderType == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: mine ? AppColors.financePrimary : Colors.white,
          border: Border.all(color: mine ? AppColors.financePrimary : AppColors.financeLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.hasImage) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatImageViewerPage(
                      imageUrl: message.imageUrl,
                      title: message.attachmentName,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.imageUrl,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    width: MediaQuery.sizeOf(context).width * .62,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.sizeOf(context).width * .62,
                        height: 150,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mine
                              ? Colors.white.withValues(alpha: .12)
                              : AppColors.financeSurfaceLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Image unavailable',
                          style: TextStyle(
                            color: mine ? Colors.white70 : AppColors.financeMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (message.message.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: TextStyle(color: mine ? Colors.white : AppColors.ink, height: 1.45, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 6),
            Text(
              mine
                  ? '${_timeText(message.createdAt)} · ${message.seenAt == null ? AppText.t('chat_delivered') : AppText.t('chat_seen')}'
                  : _timeText(message.createdAt),
              style: TextStyle(color: mine ? Colors.white70 : AppColors.financeMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _timeText(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.financeLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              Transform.translate(
                offset: Offset(0, _dotOffset(index)),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.financeMuted.withValues(alpha: .75),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (index != 2) const SizedBox(width: 5),
            ],
          ],
        );
      },
    );
  }

  double _dotOffset(int index) {
    final phase = (_controller.value + (index * .18)) % 1;
    if (phase < .5) return -4 * phase;
    return -4 * (1 - phase);
  }
}

class ChatImageViewerPage extends StatelessWidget {
  const ChatImageViewerPage({
    required this.imageUrl,
    required this.title,
    super.key,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title.isEmpty ? 'Chat Image' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: .8,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(80),
            child: Image.network(
              imageUrl,
              headers: const {'ngrok-skip-browser-warning': 'true'},
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Image unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ChatImageEditorPage extends StatefulWidget {
  const ChatImageEditorPage({
    required this.imageBytes,
    required this.fileName,
    super.key,
  });

  final Uint8List imageBytes;
  final String fileName;

  @override
  State<ChatImageEditorPage> createState() => _ChatImageEditorPageState();
}

class _ChatImageEditorPageState extends State<ChatImageEditorPage> {
  final _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];
  double _scale = 1;
  double _brushSize = 5;
  Color _brushColor = AppColors.financePrimary;
  bool _saving = false;

  Future<void> _useImage() async {
    setState(() => _saving = true);
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      setState(() => _saving = false);
      return;
    }

    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted || data == null) return;

    Navigator.of(context).pop(
      EditedChatImage(
        bytes: data.buffer.asUint8List(),
        name: 'edited-${widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), '')}.png',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text('Edit Image', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _useImage,
            child: Text(_saving ? 'Saving...' : 'Use Image'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onPanUpdate: (details) => setState(() => _points.add(details.localPosition)),
                onPanEnd: (_) => setState(() => _points.add(null)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: _scale,
                        child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                      ),
                      CustomPaint(
                        painter: _BrushPainter(
                          points: _points,
                          color: _brushColor,
                          strokeWidth: _brushSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _EditorControl(
            label: 'Crop Zoom',
            child: Slider(
              value: _scale,
              min: 1,
              max: 2.4,
              onChanged: (value) => setState(() => _scale = value),
            ),
          ),
          _EditorControl(
            label: 'Brush Size',
            child: Slider(
              value: _brushSize,
              min: 2,
              max: 18,
              onChanged: (value) => setState(() => _brushSize = value),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final color in [AppColors.financePrimary, Colors.black, Colors.white, Colors.green, Colors.blue])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => setState(() => _brushColor = color),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _brushColor == color ? AppColors.ink : AppColors.financeLine,
                          width: _brushColor == color ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() => _points.clear()),
                child: const Text('Clear Brush'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorControl extends StatelessWidget {
  const _EditorControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500)),
          child,
        ],
      ),
    );
  }
}

class _BrushPainter extends CustomPainter {
  const _BrushPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrushPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class EditedChatImage {
  const EditedChatImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.attachmentUrl,
    required this.attachmentApiUrl,
    required this.attachmentName,
    required this.createdAt,
    required this.seenAt,
  });

  final int id;
  final String senderType;
  final String senderName;
  final String message;
  final String attachmentUrl;
  final String attachmentApiUrl;
  final String attachmentName;
  final DateTime? createdAt;
  final DateTime? seenAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final attachmentUrl = _safeAttachmentUrl(json['attachment_url']?.toString() ?? '');
    final attachmentApiUrl = json['attachment_api_url']?.toString() ?? '';
    final attachmentName = json['attachment_name']?.toString() ?? '';

    return ChatMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      senderType: json['sender_type']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      attachmentUrl: attachmentUrl,
      attachmentApiUrl: _attachmentEndpoint(
        int.tryParse(json['id']?.toString() ?? '') ?? 0,
        attachmentApiUrl,
        hasAttachment: attachmentUrl.isNotEmpty ||
            attachmentApiUrl.isNotEmpty ||
            attachmentName.isNotEmpty,
      ),
      attachmentName: attachmentName,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
      seenAt: DateTime.tryParse(json['seen_at']?.toString() ?? '')?.toLocal(),
    );
  }

  String get imageUrl {
    if (attachmentApiUrl.isNotEmpty) return attachmentApiUrl;
    return attachmentUrl;
  }

  bool get hasImage {
    return attachmentName.isNotEmpty || attachmentUrl.isNotEmpty || attachmentApiUrl.isNotEmpty;
  }

  static String _attachmentEndpoint(
    int id,
    String fallback, {
    required bool hasAttachment,
  }) {
    if (!hasAttachment) return '';
    if (id <= 0) return _safeAttachmentUrl(fallback);

    final apiUri = _apiBaseUri();

    return apiUri.replace(path: '${apiUri.path}/chat/messages/$id/attachment').toString();
  }

  static String _safeAttachmentUrl(String value) {
    if (value.isEmpty) return value;

    final uri = Uri.tryParse(value);
    if (uri == null || (!uri.host.contains('127.0.0.1') && uri.host != 'localhost')) {
      return value;
    }

    final apiUri = _apiBaseUri();

    return apiUri.replace(path: uri.path, query: uri.query).toString();
  }

  static Uri _apiBaseUri() {
    return Uri.parse(AuthApi().baseUrl);
  }
}
