import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class BankTransferPage extends StatefulWidget {
  const BankTransferPage({super.key});

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _branch = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _routingNumber = TextEditingController();
  final _contactNumber = TextEditingController();
  final _amount = TextEditingController();
  final _otp = TextEditingController();
  final _api = AuthApi();

  AppSession? _session;
  List<dynamic> _beneficiaries = [];
  String _bank = bangladeshBanks.first;
  bool _loading = false;
  bool _otpSent = false;
  double _charge = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await const SessionStore().load();
    if (!mounted) return;
    setState(() {
      _session = session;
      if (session.userPhone.trim().isNotEmpty) {
        _contactNumber.text = session.userPhone.trim();
      }
    });
    _loadBeneficiaries(session.userEmail);
  }

  Future<void> _loadBeneficiaries(String email) async {
    if (email.trim().isEmpty) return;
    final result = await _api.beneficiaries(email: email, type: 'bank');
    if (!mounted || !result.ok) return;
    setState(() {
      _beneficiaries = result.data['beneficiaries'] as List<dynamic>? ?? [];
    });
  }

  @override
  void dispose() {
    _branch.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _routingNumber.dispose();
    _contactNumber.dispose();
    _amount.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _session?.userEmail ?? '';
    if (email.trim().isEmpty) {
      showAppMessage(context, AppText.t('missing_email'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = _otpSent
        ? await _api.confirmBankTransfer(
            email: email,
            bankName: _bank,
            branchName: _branch.text.trim(),
            accountName: _accountName.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            routingNumber: _routingNumber.text.trim(),
            contactNumber: _contactNumber.text.trim(),
            amount: _amount.text.trim(),
            otp: _otp.text.trim(),
          )
        : await _api.requestBankTransferOtp(
            email: email,
            bankName: _bank,
            branchName: _branch.text.trim(),
            accountName: _accountName.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            routingNumber: _routingNumber.text.trim(),
            contactNumber: _contactNumber.text.trim(),
            amount: _amount.text.trim(),
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.ok) {
      showAppMessage(context, result.message);
      return;
    }

    if (!_otpSent) {
      setState(() {
        _otpSent = true;
        _charge = double.tryParse(result.data['charge']?.toString() ?? '') ?? 0;
        _total = double.tryParse(result.data['total_amount']?.toString() ?? '') ?? 0;
      });
      showAppMessage(context, AppText.t('otp_sent_message'));
      return;
    }

    await _refreshSessionBalance();
    await _saveBeneficiary(email);
    if (!mounted) return;
    _showSubmittedSheet(result.data['bank_transfer'] as Map<String, dynamic>? ?? {});
  }

  Future<void> _saveBeneficiary(String email) async {
    await _api.saveBeneficiary(
      email: email,
      type: 'bank',
      label: '$_bank • ${_accountName.text.trim()}',
      provider: _bank,
      accountName: _accountName.text.trim(),
      accountNumber: _accountNumber.text.trim(),
      mobileNumber: _contactNumber.text.trim(),
      isFavorite: _beneficiaries.isEmpty,
    );
  }

  void _applyBeneficiary(Map<String, dynamic> item) {
    final bank = item['provider']?.toString() ?? _bank;
    setState(() {
      if (bangladeshBanks.contains(bank)) _bank = bank;
      _accountName.text = item['account_name']?.toString() ?? '';
      _accountNumber.text = item['account_number']?.toString() ?? '';
      _contactNumber.text = item['mobile_number']?.toString() ?? '';
      _otpSent = false;
      _otp.clear();
    });
  }

  Future<void> _refreshSessionBalance() async {
    final email = _session?.userEmail ?? '';
    if (email.trim().isEmpty) return;

    final result = await _api.profile(email: email);
    if (!result.ok) return;

    final user = result.data['user'] as Map<String, dynamic>? ?? {};
    final latestBalance = double.tryParse(user['balance']?.toString() ?? '');

    await const SessionStore().saveProfile(
      userName: user['name']?.toString() ?? _session?.userName ?? 'User',
      userEmail: user['email']?.toString() ?? email,
      userPhone: user['phone']?.toString() ?? _session?.userPhone ?? '',
      userAddress: user['address']?.toString() ?? _session?.userAddress ?? '',
      userBalance: latestBalance,
    );
  }

  void _showSubmittedSheet(Map<String, dynamic> transfer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankTransferSubmittedSheet(transfer: transfer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(AppText.t('bank_transfer_title'), style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const _BankTransferHeader(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.financeLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BankDropdown(
                    value: _bank,
                    onChanged: (value) {
                      setState(() {
                        _bank = value;
                        _otpSent = false;
                        _otp.clear();
                      });
                    },
                  ),
                  _BeneficiaryStrip(
                    items: _beneficiaries,
                    onTap: _applyBeneficiary,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _branch,
                    label: AppText.t('branch_name'),
                    hint: AppText.t('branch_name_hint'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _accountName,
                    label: AppText.t('account_holder_name'),
                    hint: AppText.t('account_holder_hint'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _accountNumber,
                    label: AppText.t('bank_account_number'),
                    hint: AppText.t('bank_account_hint'),
                    keyboardType: TextInputType.number,
                    validator: _accountValidator,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _routingNumber,
                    label: AppText.t('routing_number'),
                    hint: AppText.t('routing_number_hint'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _contactNumber,
                    label: AppText.t('contact_number'),
                    hint: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amount,
                    label: AppText.t('withdraw_amount'),
                    hint: AppText.t('amount_hint'),
                    keyboardType: TextInputType.number,
                    validator: _amountValidator,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 14),
                    _ChargeSummary(charge: _charge, total: _total),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _otp,
                      label: AppText.t('otp_code'),
                      hint: AppText.t('otp_hint'),
                      keyboardType: TextInputType.number,
                      validator: _otpValidator,
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    label: _otpSent ? AppText.t('confirm_bank_transfer') : AppText.t('send_otp'),
                    icon: _otpSent ? Icons.verified_rounded : Icons.mark_email_read_rounded,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return AppText.t('required_field');
    return null;
  }

  String? _accountValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AppText.t('required_field');
    if (text.length < 6) return AppText.t('invalid_bank_account');
    return null;
  }

  String? _amountValidator(String? value) {
    final amount = num.tryParse(value?.trim() ?? '');
    if (amount == null) return AppText.t('invalid_amount');
    if (amount < 100) return AppText.t('min_bank_transfer');
    if (amount > 500000) return AppText.t('max_bill_payment');
    return null;
  }

  String? _otpValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return AppText.t('invalid_otp');
    return null;
  }
}

class _BankTransferHeader extends StatelessWidget {
  const _BankTransferHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppText.t('bank_transfer_header'),
              style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDropdown extends StatelessWidget {
  const _BankDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [
        for (final bank in bangladeshBanks)
          DropdownMenuItem(value: bank, child: Text(bank, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        labelText: AppText.t('select_bank'),
        filled: true,
        fillColor: AppColors.financeSurfaceLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) => value == null || value.isEmpty ? AppText.t('required_field') : null,
    );
  }
}

class _BeneficiaryStrip extends StatelessWidget {
  const _BeneficiaryStrip({
    required this.items,
    required this.onTap,
  });

  final List<dynamic> items;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            final label = item['label']?.toString() ?? item['account_number']?.toString() ?? 'Saved bank';
            return ActionChip(
              avatar: const Icon(Icons.bookmark_added_rounded, size: 16, color: AppColors.financePrimary),
              label: Text(label, overflow: TextOverflow.ellipsis),
              onPressed: () => onTap(item),
              backgroundColor: AppColors.financeSurfaceLow,
              side: const BorderSide(color: AppColors.financeLine),
              labelStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemCount: items.length > 8 ? 8 : items.length,
        ),
      ),
    );
  }
}

class _ChargeSummary extends StatelessWidget {
  const _ChargeSummary({required this.charge, required this.total});

  final double charge;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${AppText.t('service_charge')}: BDT ${charge.toStringAsFixed(2)}  •  ${AppText.t('total')}: BDT ${total.toStringAsFixed(2)}',
        style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _BankTransferSubmittedSheet extends StatelessWidget {
  const _BankTransferSubmittedSheet({required this.transfer});

  final Map<String, dynamic> transfer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.financeLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: AppColors.financePrimary, size: 56),
            const SizedBox(height: 12),
            Text(AppText.t('bank_transfer_submitted'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(transfer['transaction_id']?.toString() ?? '-', style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(backgroundColor: AppColors.financePrimary, minimumSize: const Size.fromHeight(48)),
                child: Text(AppText.t('done')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const bangladeshBanks = [
  'AB Bank',
  'Agrani Bank',
  'Al-Arafah Islami Bank',
  'Bangladesh Commerce Bank',
  'Bangladesh Development Bank',
  'Bangladesh Krishi Bank',
  'Bank Asia',
  'BASIC Bank',
  'Bengal Commercial Bank',
  'Bank Alfalah',
  'BRAC Bank',
  'Citizens Bank',
  'City Bank',
  'Commercial Bank of Ceylon',
  'Community Bank Bangladesh',
  'Dhaka Bank',
  'Dutch-Bangla Bank',
  'Eastern Bank',
  'EXIM Bank',
  'First Security Islami Bank',
  'Habib Bank',
  'ICB Islamic Bank',
  'IFIC Bank',
  'Islami Bank Bangladesh',
  'Jamuna Bank',
  'Janata Bank',
  'Meghna Bank',
  'Mercantile Bank',
  'Midland Bank',
  'Modhumoti Bank',
  'Mutual Trust Bank',
  'National Bank',
  'National Bank of Pakistan',
  'NCC Bank',
  'NRB Bank',
  'NRB Commercial Bank',
  'NRB Global Bank',
  'One Bank',
  'Padma Bank',
  'Premier Bank',
  'Prime Bank',
  'Probashi Kallyan Bank',
  'Pubali Bank',
  'Rajshahi Krishi Unnayan Bank',
  'Rupali Bank',
  'Shahjalal Islami Bank',
  'Shimanto Bank',
  'Social Islami Bank',
  'Sonali Bank',
  'South Bangla Agriculture and Commerce Bank',
  'Southeast Bank',
  'Standard Bank',
  'Standard Chartered Bank',
  'State Bank of India',
  'The Hongkong and Shanghai Banking Corporation',
  'Trust Bank',
  'UCB',
  'Union Bank',
  'Uttara Bank',
  'Woori Bank',
];
