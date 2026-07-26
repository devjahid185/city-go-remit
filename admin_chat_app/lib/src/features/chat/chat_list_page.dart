import 'dart:async';

import 'package:admin_chat_app/src/core/app_colors.dart';
import 'package:admin_chat_app/src/core/safe_message.dart';
import 'package:admin_chat_app/src/features/auth/login_page.dart';
import 'package:admin_chat_app/src/features/chat/chat_detail_page.dart';
import 'package:admin_chat_app/src/models/chat_models.dart';
import 'package:admin_chat_app/src/services/admin_api.dart';
import 'package:admin_chat_app/src/services/push_notification_service.dart';
import 'package:admin_chat_app/src/services/session_store.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({required this.session, super.key});

  final AdminSession session;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with WidgetsBindingObserver {
  final _api = AdminApi();
  final _search = TextEditingController();
  Timer? _timer;
  List<ChatConversation> _items = [];
  String _status = '';
  bool _loading = true;
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
    _search.dispose();
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
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent) setState(() => _loading = true);
    final result = await _api.conversations(
      token: widget.session.token,
      search: _search.text,
      status: _status,
    );
    if (!mounted) return;
    _fetching = false;
    if (result.ok) {
      setState(() {
        _items = result.data ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (!silent) _show(result.message);
    }
  }

  Future<void> _logout() async {
    await AdminPushNotificationService.instance.unregisterCurrentToken(widget.session);
    await _api.logout(token: widget.session.token);
    await const SessionStore().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safeMessageText(message))));
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.fold<int>(0, (sum, item) => sum + item.unreadForAdmin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Support'),
        actions: [
          IconButton(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _HeaderCard(
              adminName: widget.session.admin.name,
              total: _items.length,
              unread: unread,
            ),
            const SizedBox(height: 14),
            _SearchAndFilter(
              search: _search,
              status: _status,
              onStatus: (value) {
                setState(() => _status = value);
                _load();
              },
              onSearch: _load,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _LoadingList()
            else if (_items.isEmpty)
              const _EmptyState()
            else
              for (final item in _items) ...[
                _ConversationTile(
                  item: item,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          session: widget.session,
                          conversationId: item.id,
                        ),
                      ),
                    );
                    _load(silent: true);
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.adminName,
    required this.total,
    required this.unread,
  });

  final String adminName;
  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $adminName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$total conversations • $unread unread',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.search,
    required this.status,
    required this.onStatus,
    required this.onSearch,
  });

  final TextEditingController search;
  final String status;
  final ValueChanged<String> onStatus;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search name, email or phone',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.tune_rounded),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('All Conversations')),
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'closed', child: Text('Closed')),
            ],
            onChanged: (value) => onStatus(value ?? ''),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.item,
    required this.onTap,
  });

  final ChatConversation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = item.latestMessage;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: .08),
          child: Text(
            _initial(item.userName),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (item.unreadForAdmin > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.unreadForAdmin.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.userTyping
                    ? 'Typing...'
                    : (latest?.message.trim().isNotEmpty == true
                        ? latest!.message
                        : latest?.hasAttachment == true
                            ? 'Image attachment'
                            : item.email),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.userTyping ? AppColors.primary : AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniChip(label: item.status),
                  if (item.chatBanned) const _MiniChip(label: 'chat banned', danger: true),
                  if (item.userPhone.isNotEmpty) _MiniChip(label: item.userPhone),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _initial(String text) {
    final value = text.trim();
    if (value.isEmpty) return 'U';
    return value.substring(0, 1).toUpperCase();
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: danger ? AppColors.primary.withValues(alpha: .08) : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.primary : AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 50),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined, color: AppColors.primary, size: 42),
          SizedBox(height: 12),
          Text(
            'No conversations found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'New user support chats will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
