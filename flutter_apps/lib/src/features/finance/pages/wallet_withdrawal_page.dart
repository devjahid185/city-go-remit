import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class WalletWithdrawalPage extends StatefulWidget {
  const WalletWithdrawalPage({super.key});

  @override
  State<WalletWithdrawalPage> createState() => _WalletWithdrawalPageState();
}

class _WalletWithdrawalPageState extends State<WalletWithdrawalPage> {
  final _formKey = GlobalKey<FormState>();
  final _walletNumber = TextEditingController();
  final _accountName = TextEditingController();
  final _contactNumber = TextEditingController();
  final _amount = TextEditingController();
  final _otp = TextEditingController();
  final _api = AuthApi();

  AppSession? _session;
  List<dynamic> _beneficiaries = [];
  String _provider = walletProviders.first;
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
    final result = await _api.beneficiaries(email: email, type: 'wallet');
    if (!mounted || !result.ok) return;
    setState(() {
      _beneficiaries = result.data['beneficiaries'] as List<dynamic>? ?? [];
    });
  }

  @override
  void dispose() {
    _walletNumber.dispose();
    _accountName.dispose();
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
        ? await _api.confirmWalletWithdrawal(
            email: email,
            walletProvider: _provider,
            walletNumber: _onlyDigits(_walletNumber.text),
            accountName: _accountName.text.trim(),
            contactNumber: _contactNumber.text.trim(),
            amount: _amount.text.trim(),
            otp: _onlyDigits(_otp.text),
          )
        : await _api.requestWalletWithdrawalOtp(
            email: email,
            walletProvider: _provider,
            walletNumber: _onlyDigits(_walletNumber.text),
            accountName: _accountName.text.trim(),
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
    _showSubmittedSheet(result.data['wallet_withdrawal'] as Map<String, dynamic>? ?? {});
  }

  Future<void> _saveBeneficiary(String email) async {
    await _api.saveBeneficiary(
      email: email,
      type: 'wallet',
      label: '$_provider • ${_maskNumber(_walletNumber.text)}',
      provider: _provider,
      accountName: _accountName.text.trim(),
      accountNumber: _onlyDigits(_walletNumber.text),
      mobileNumber: _onlyDigits(_walletNumber.text),
      isFavorite: _beneficiaries.isEmpty,
    );
  }

  void _applyBeneficiary(Map<String, dynamic> item) {
    final provider = item['provider']?.toString() ?? _provider;
    setState(() {
      if (walletProviders.contains(provider)) _provider = provider;
      _walletNumber.text = item['mobile_number']?.toString() ?? item['account_number']?.toString() ?? '';
      _accountName.text = item['account_name']?.toString() ?? '';
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
    await const SessionStore().saveProfile(
      userName: user['name']?.toString() ?? _session?.userName ?? 'User',
      userEmail: user['email']?.toString() ?? email,
      userPhone: user['phone']?.toString() ?? _session?.userPhone ?? '',
      userAddress: user['address']?.toString() ?? _session?.userAddress ?? '',
      userBalance: double.tryParse(user['balance']?.toString() ?? ''),
    );
  }

  void _showSubmittedSheet(Map<String, dynamic> withdrawal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalletSubmittedSheet(withdrawal: withdrawal),
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
        title: Text(AppText.t('wallet_withdrawal_title'), style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const _WalletHeader(),
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
                  _WalletProviderSelector(
                    value: _provider,
                    onChanged: (value) {
                      setState(() {
                        _provider = value;
                        _otpSent = false;
                        _otp.clear();
                      });
                    },
                  ),
                  _BeneficiaryStrip(items: _beneficiaries, onTap: _applyBeneficiary),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _walletNumber,
                    label: AppText.t('wallet_number'),
                    hint: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    validator: _walletNumberValidator,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _accountName,
                    label: AppText.t('account_holder_name'),
                    hint: AppText.t('account_holder_hint'),
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
                    label: _otpSent ? AppText.t('confirm_wallet_withdrawal') : AppText.t('send_otp'),
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

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _maskNumber(String value) {
    final digits = _onlyDigits(value);
    if (digits.length < 4) return digits;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  String? _walletNumberValidator(String? value) {
    final digits = _onlyDigits(value ?? '');
    if (digits.length != 11 || !digits.startsWith('01')) return AppText.t('invalid_mobile_number');
    return null;
  }

  String? _amountValidator(String? value) {
    final amount = num.tryParse(value?.trim() ?? '');
    if (amount == null) return AppText.t('invalid_amount');
    if (amount < 50) return AppText.t('min_wallet_withdrawal');
    if (amount > 500000) return AppText.t('max_bill_payment');
    return null;
  }

  String? _otpValidator(String? value) {
    final digits = _onlyDigits(value ?? '');
    if (digits.length != 6) return AppText.t('invalid_otp');
    return null;
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

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
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppText.t('wallet_withdrawal_header'),
              style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletProviderSelector extends StatelessWidget {
  const _WalletProviderSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final provider in walletProviders)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: provider == walletProviders.last ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: value == provider ? AppColors.financePrimary : AppColors.financeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: value == provider ? AppColors.financePrimary : AppColors.financeLine),
                  ),
                  child: Text(
                    provider,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: value == provider ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BeneficiaryStrip extends StatelessWidget {
  const _BeneficiaryStrip({required this.items, required this.onTap});

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
            final label = item['label']?.toString() ?? item['mobile_number']?.toString() ?? 'Saved wallet';
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

class _WalletSubmittedSheet extends StatelessWidget {
  const _WalletSubmittedSheet({required this.withdrawal});

  final Map<String, dynamic> withdrawal;

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
            Text(AppText.t('wallet_withdrawal_submitted'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(withdrawal['transaction_id']?.toString() ?? '-', style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500)),
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

const walletProviders = ['bKash', 'Nagad', 'Rocket'];
