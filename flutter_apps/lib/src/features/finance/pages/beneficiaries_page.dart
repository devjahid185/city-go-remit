import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';

class BeneficiariesPage extends StatefulWidget {
  const BeneficiariesPage({super.key});

  @override
  State<BeneficiariesPage> createState() => _BeneficiariesPageState();
}

class _BeneficiariesPageState extends State<BeneficiariesPage> {
  final _api = AuthApi();
  String _email = '';
  String _type = 'recharge';
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = await const SessionStore().load();
    _email = session.userEmail;
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _api.beneficiaries(email: _email, type: _type);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.data['beneficiaries'] as List<dynamic>? ?? [];
    });
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BeneficiarySheet(email: _email, type: _type, item: item),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final result = await _api.deleteBeneficiary(id: item['id'].toString(), email: _email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safeAppMessageText(result.message))));
    if (result.ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        title: const Text('Beneficiaries', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.financeBackground,
        actions: [
          IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _TypeChip(label: 'Recharge', value: 'recharge', selected: _type, onTap: _selectType),
                _TypeChip(label: 'Bill', value: 'bill', selected: _type, onTap: _selectType),
                _TypeChip(label: 'Bank', value: 'bank', selected: _type, onTap: _selectType),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No saved beneficiary yet.', style: TextStyle(color: AppColors.financeMuted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        itemBuilder: (context, index) {
                          final item = _items[index] as Map<String, dynamic>;
                          return _BeneficiaryTile(item: item, onEdit: () => _openForm(item), onDelete: () => _delete(item));
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemCount: _items.length,
                      ),
          ),
        ],
      ),
    );
  }

  void _selectType(String value) {
    if (_type == value) return;
    setState(() => _type = value);
    _load();
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.value, required this.selected, required this.onTap});

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(value),
        selectedColor: AppColors.financePrimary.withValues(alpha: .12),
        labelStyle: TextStyle(color: active ? AppColors.financePrimary : AppColors.financeMuted, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _BeneficiaryTile extends StatelessWidget {
  const _BeneficiaryTile({required this.item, required this.onEdit, required this.onDelete});

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item['provider'],
      item['mobile_number'],
      item['account_number'],
    ].where((value) => (value ?? '').toString().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_added_rounded, color: AppColors.financePrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['label']?.toString() ?? 'Saved receiver', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle.isEmpty ? 'Ready for quick payment' : subtitle, style: const TextStyle(color: AppColors.financeMuted, fontSize: 13)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 20)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.financePrimary)),
        ],
      ),
    );
  }
}

class _BeneficiarySheet extends StatefulWidget {
  const _BeneficiarySheet({required this.email, required this.type, this.item});

  final String email;
  final String type;
  final Map<String, dynamic>? item;

  @override
  State<_BeneficiarySheet> createState() => _BeneficiarySheetState();
}

class _BeneficiarySheetState extends State<_BeneficiarySheet> {
  final _api = AuthApi();
  late final TextEditingController _label;
  late final TextEditingController _provider;
  late final TextEditingController _accountName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _mobileNumber;
  bool _favorite = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? {};
    _label = TextEditingController(text: item['label']?.toString() ?? '');
    _provider = TextEditingController(text: item['provider']?.toString() ?? '');
    _accountName = TextEditingController(text: item['account_name']?.toString() ?? '');
    _accountNumber = TextEditingController(text: item['account_number']?.toString() ?? '');
    _mobileNumber = TextEditingController(text: item['mobile_number']?.toString() ?? '');
    _favorite = item['is_favorite'] == true;
  }

  @override
  void dispose() {
    _label.dispose();
    _provider.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _mobileNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _api.saveBeneficiary(
      id: widget.item?['id']?.toString(),
      email: widget.email,
      type: widget.type,
      label: _label.text.trim(),
      provider: _provider.text.trim(),
      accountName: _accountName.text.trim(),
      accountNumber: _accountNumber.text.trim(),
      mobileNumber: _mobileNumber.text.trim(),
      isFavorite: _favorite,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safeAppMessageText(result.message))));
    if (result.ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.financeLine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.item == null ? 'Save New Receiver' : 'Edit Receiver', style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              _Input(controller: _label, label: 'Label'),
              _Input(controller: _provider, label: 'Provider / Bank'),
              _Input(controller: _accountName, label: 'Account Name'),
              _Input(controller: _accountNumber, label: 'Account Number'),
              _Input(controller: _mobileNumber, label: 'Mobile Number'),
              SwitchListTile(
                value: _favorite,
                onChanged: (value) => setState(() => _favorite = value),
                title: const Text('Mark as favorite', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.financePrimary, minimumSize: const Size.fromHeight(50)),
                child: Text(_saving ? 'Saving...' : 'Save Beneficiary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.financeBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
