import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/receipt_page.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class FinanceHistoryTab extends StatefulWidget {
  const FinanceHistoryTab({super.key});

  @override
  State<FinanceHistoryTab> createState() => _FinanceHistoryTabState();
}

class _FinanceHistoryTabState extends State<FinanceHistoryTab> {
  final _search = TextEditingController();
  final _api = AuthApi();
  String _filter = 'all';
  bool _loading = true;
  String _message = '';
  List<HistoryItem> _items = [];
  Map<String, int> _summary = const {
    'total': 0,
    'in': 0,
    'out': 0,
    'recharge': 0,
    'bank_transfer': 0,
    'wallet_withdrawal': 0,
    'drive_offer': 0,
    'pending': 0,
  };

  static const _filters = [
    _HistoryFilter('all', Icons.history_rounded),
    _HistoryFilter('in', Icons.call_received_rounded),
    _HistoryFilter('out', Icons.call_made_rounded),
    _HistoryFilter('recharge', Icons.phone_iphone_rounded),
    _HistoryFilter('bank_transfer', Icons.account_balance_rounded),
    _HistoryFilter('wallet_withdrawal', Icons.account_balance_wallet_rounded),
    _HistoryFilter('drive_offer', Icons.wifi_tethering_rounded),
    _HistoryFilter('pending', Icons.schedule_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _loadHistory();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final session = await const SessionStore().load();
    final email = session.userEmail.trim();

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = AppText.t('missing_email');
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _message = '';
      });
    }

    final result = await _api.histories(email: email);
    if (!mounted) return;

    if (!result.ok) {
      setState(() {
        _loading = false;
        _message = result.message;
      });
      return;
    }

    final histories = result.data['histories'] as List<dynamic>? ?? [];
    final summary = result.data['summary'] as Map<String, dynamic>? ?? {};

    setState(() {
      _items = histories
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromJson)
          .toList();
      _summary = {
        'total': _asInt(summary['total']),
        'in': _asInt(summary['in']),
        'out': _asInt(summary['out']),
        'recharge': _asInt(summary['recharge']),
        'bank_transfer': _asInt(summary['bank_transfer']),
        'wallet_withdrawal': _asInt(summary['wallet_withdrawal']),
        'drive_offer': _asInt(summary['drive_offer']),
        'pending': _asInt(summary['pending']),
      };
      _loading = false;
    });
  }

  List<HistoryItem> get _visibleItems {
    final query = _search.text.trim().toLowerCase();

    return [
      for (final item in _items)
        if (_matchesFilter(item) && _matchesSearch(item, query)) item,
    ];
  }

  bool _matchesFilter(HistoryItem item) {
    return switch (_filter) {
      'all' => true,
      'in' => item.direction == 'in',
      'out' => item.direction == 'out',
      'recharge' => item.category == 'recharge',
      'bank_transfer' => item.category == 'bank_transfer',
      'wallet_withdrawal' => item.category == 'wallet_withdrawal',
      'drive_offer' => item.category == 'drive_offer',
      'pending' => item.status == 'pending' || item.status == 'processing',
      _ => true,
    };
  }

  bool _matchesSearch(HistoryItem item, String query) {
    if (query.isEmpty) return true;

    return item.title.toLowerCase().contains(query) ||
        item.subtitle.toLowerCase().contains(query) ||
        item.reference.toLowerCase().contains(query) ||
        item.status.toLowerCase().contains(query) ||
        item.category.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return RefreshIndicator(
      color: AppColors.financePrimary,
      onRefresh: _loadHistory,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Text(
                  AppText.t('history_title'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.4,
                  ),
                ),
                const Spacer(),
                _CircleAction(icon: Icons.sync_rounded, onTap: _loadHistory),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _SummaryStrip(summary: _summary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SearchBox(
              controller: _search,
              hint: AppText.t('history_search_hint'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return _FilterChip(
                  filter: filter,
                  selected: filter.key == _filter,
                  onTap: () => setState(() => _filter = filter.key),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: _filters.length,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _HistoryLoader()
          else if (_message.isNotEmpty)
            _EmptyHistory(title: AppText.t('history_not_loaded'), body: _message)
          else if (items.isEmpty)
            _EmptyHistory(
              title: AppText.t('history_empty'),
              body: AppText.t('history_empty_body'),
            )
          else
            _HistoryTimeline(items: items),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final Map<String, int> summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(AppText.t('history_total'), summary['total'] ?? 0, Icons.receipt_long_rounded),
      _SummaryCard(AppText.t('history_in'), summary['in'] ?? 0, Icons.call_received_rounded),
      _SummaryCard(AppText.t('history_out'), summary['out'] ?? 0, Icons.call_made_rounded),
      _SummaryCard(AppText.t('history_pending'), summary['pending'] ?? 0, Icons.schedule_rounded),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => cards[index],
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: cards.length,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.financePrimary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.financeMuted,
                    fontSize: 12,
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.financeMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.financeLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.financeLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.financePrimary, width: 1.4),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _HistoryFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.financePrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.financePrimary : AppColors.financeLine,
          ),
        ),
        child: Row(
          children: [
            Icon(
              filter.icon,
              size: 16,
              color: selected ? Colors.white : AppColors.financeMuted,
            ),
            const SizedBox(width: 7),
            Text(
              AppText.t('history_filter_${filter.key}'),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.financeMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.items});

  final List<HistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<HistoryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(_groupLabel(item.createdAt), () => []).add(item);
    }

    return Column(
      children: [
        for (final entry in groups.entries)
          _HistorySection(label: entry.key, items: entry.value),
      ],
    );
  }

  String _groupLabel(DateTime? date) {
    if (date == null) return AppText.t('history_recent');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(itemDay).inDays;
    if (difference == 0) return AppText.t('history_today');
    if (difference == 1) return AppText.t('history_yesterday');
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.label, required this.items});

  final String label;
  final List<HistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.financeMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (var index = 0; index < items.length; index++) ...[
            _HistoryTile(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final out = item.direction == 'out';
    final amountColor = out ? AppColors.financePrimary : const Color(0xFF15803D);

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.financeLine),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconColor().withValues(alpha: .11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.subtitle} • ${_timeText(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.financeMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${out ? '-' : '+'}${_money(item.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusPill(status: item.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _HistoryDetailsSheet(item: item),
    );
  }

  IconData _icon() {
    return switch (item.category) {
      'recharge' => Icons.phone_iphone_rounded,
      'bank_transfer' => Icons.account_balance_rounded,
      'wallet_withdrawal' => Icons.account_balance_wallet_rounded,
      'transfer' => item.direction == 'in'
          ? Icons.call_received_rounded
          : Icons.call_made_rounded,
      'bill' => Icons.receipt_long_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };
  }

  Color _iconColor() {
    if (item.status == 'pending' || item.status == 'processing') {
      return const Color(0xFFB45309);
    }
    if (item.status == 'failed' || item.status == 'cancelled') {
      return AppColors.financePrimary;
    }
    return item.direction == 'in'
        ? const Color(0xFF15803D)
        : AppColors.financePrimary;
  }
}

class _HistoryDetailsSheet extends StatelessWidget {
  const _HistoryDetailsSheet({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.financeLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _StatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: AppText.t('transaction_id'), value: item.reference),
            _DetailRow(label: AppText.t('history_type'), value: _titleCase(item.category)),
            _DetailRow(label: AppText.t('history_direction'), value: _titleCase(item.direction)),
            _DetailRow(label: AppText.t('amount'), value: _money(item.amount)),
            _DetailRow(label: AppText.t('history_date'), value: _dateText(item.createdAt)),
            if ((item.meta['operator'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('operator'), value: item.meta['operator'].toString()),
            if ((item.meta['mobile_number'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('mobile_number'), value: item.meta['mobile_number'].toString()),
            if ((item.meta['bank_name'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('select_bank'), value: item.meta['bank_name'].toString()),
            if ((item.meta['wallet_provider'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('wallet_withdrawal_title'), value: item.meta['wallet_provider'].toString()),
            if ((item.meta['wallet_number'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('wallet_number'), value: item.meta['wallet_number'].toString()),
            if ((item.meta['account_name'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('account_holder_name'), value: item.meta['account_name'].toString()),
            if ((item.meta['account_number'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('bank_account_number'), value: item.meta['account_number'].toString()),
            if ((item.meta['admin_note'] ?? '').toString().isNotEmpty)
              _DetailRow(label: AppText.t('history_note'), value: item.meta['admin_note'].toString()),
            const SizedBox(height: 14),
            if (item.status == 'successful') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptPage(
                          type: item.category,
                          transactionId: item.reference,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('View Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.financePrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.financePrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppText.t('done')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.financeMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending' || status == 'processing';
    final failed = status == 'failed' || status == 'cancelled';
    final color = pending
        ? const Color(0xFFB45309)
        : failed
            ? AppColors.financePrimary
            : const Color(0xFF15803D);
    final background = pending
        ? const Color(0xFFFEF3C7)
        : failed
            ? const Color(0xFFFFE4E1)
            : const Color(0xFFDCFCE7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.financeLine),
        ),
        child: Icon(icon, color: AppColors.ink, size: 21),
      ),
    );
  }
}

class _HistoryLoader extends StatelessWidget {
  const _HistoryLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [
          for (var index = 0; index < 4; index++) ...[
            Container(
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.financeLine),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 160),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.financeSurfaceLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.financePrimary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.financeMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.reference,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.direction,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.meta,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '-',
      title: json['title']?.toString() ?? 'Transaction',
      subtitle: json['subtitle']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      direction: json['direction']?.toString() ?? 'out',
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      meta: (json['meta'] as Map<String, dynamic>?) ?? const {},
    );
  }

  final String id;
  final String reference;
  final String title;
  final String subtitle;
  final String category;
  final String direction;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final Map<String, dynamic> meta;
}

class _HistoryFilter {
  const _HistoryFilter(this.key, this.icon);

  final String key;
  final IconData icon;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(double amount) {
  final hasDecimal = amount % 1 != 0;
  return 'BDT ${amount.toStringAsFixed(hasDecimal ? 2 : 0)}';
}

String _timeText(DateTime? date) {
  if (date == null) return AppText.t('history_recent');
  final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _dateText(DateTime? date) {
  if (date == null) return AppText.t('history_recent');
  return '${date.day}/${date.month}/${date.year} ${_timeText(date)}';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
