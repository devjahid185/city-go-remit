import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({
    required this.type,
    required this.transactionId,
    super.key,
  });

  final String type;
  final String transactionId;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final _api = AuthApi();
  Map<String, dynamic>? _receipt;
  String _email = '';
  String _message = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await const SessionStore().load();
    final result = await _api.receipt(
      type: widget.type,
      transactionId: widget.transactionId,
      email: session.userEmail,
    );
    if (!mounted) return;
    setState(() {
      _email = session.userEmail;
      _message = result.message;
      _receipt = result.data['receipt'] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  Future<void> _copyLink() async {
    final link = _api.receiptUrl(type: widget.type, transactionId: widget.transactionId, email: _email);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt link copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        title: const Text('Receipt', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.financeBackground,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _receipt == null
              ? Center(child: Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.financeMuted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.financeLine),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CITY GO REMIT', style: TextStyle(color: AppColors.financePrimary, fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Text(_receipt!['title']?.toString() ?? 'Transaction Receipt', style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 18),
                          Text(_receipt!['amount_text']?.toString() ?? '', style: const TextStyle(color: AppColors.ink, fontSize: 34, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Chip(label: Text(_receipt!['status']?.toString() ?? ''), backgroundColor: const Color(0xFFDCFCE7), labelStyle: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 18),
                          _ReceiptRow(label: 'Transaction ID', value: _receipt!['transaction_id']?.toString() ?? '-'),
                          _ReceiptRow(label: 'Email', value: _receipt!['email']?.toString() ?? '-'),
                          _ReceiptRow(label: 'Date', value: _receipt!['date']?.toString() ?? '-'),
                          ...((_receipt!['details'] as Map<String, dynamic>? ?? {}).entries.map((entry) => _ReceiptRow(label: entry.key, value: entry.value.toString()))),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: _copyLink,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy Shareable Receipt Link'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: AppColors.financePrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.financeMuted))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
