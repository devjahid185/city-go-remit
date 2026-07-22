import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final _api = AuthApi();
  List<dynamic> _items = [];
  bool _loading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await const SessionStore().load();
    final result = await _api.notifications(email: session.userEmail);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = result.message;
      _items = result.data['notifications']?['data'] as List<dynamic>? ?? [];
    });
    if (result.ok) {
      await _api.markNotificationsRead(email: session.userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.financeBackground,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _EmptyState(message: _message),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    itemBuilder: (context, index) {
                      final item = _items[index] as Map<String, dynamic>;
                      return _NotificationTile(item: item);
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemCount: _items.length,
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final read = item['read_at'] != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: read ? AppColors.financeLine : AppColors.financePrimary.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.financePrimary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.financePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'Notification',
                  style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  item['body']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.financeMuted, height: 1.4, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                Text(
                  item['created_at']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.financeMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.financePrimary, size: 42),
          const SizedBox(height: 12),
          const Text('No notifications yet', style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.financeMuted)),
        ],
      ),
    );
  }
}
