import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/app_runtime_settings.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class MobileRechargePage extends StatefulWidget {
  const MobileRechargePage({super.key});

  @override
  State<MobileRechargePage> createState() => _MobileRechargePageState();
}

class _MobileRechargePageState extends State<MobileRechargePage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _otp = TextEditingController();
  final _api = AuthApi();
  AppSession? _session;
  List<dynamic> _beneficiaries = [];
  bool _loading = false;
  bool _otpSent = false;
  double _charge = 0;
  double _total = 0;

  static const _amounts = ['20', '50', '100', '200', '500', '1000'];

  String? get _operator => _detectOperator(_phone.text);

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _loadSession();
  }

  Future<void> _loadSession() async {
    await AppRuntimeSettings.instance.load();
    final session = await const SessionStore().load();
    if (!mounted) return;
    setState(() {
      _session = session;
    });
    _loadBeneficiaries(session.userEmail);
  }

  Future<void> _loadBeneficiaries(String email) async {
    if (email.trim().isEmpty) return;
    final result = await _api.beneficiaries(email: email, type: 'recharge');
    if (!mounted || !result.ok) return;
    setState(() {
      _beneficiaries = result.data['beneficiaries'] as List<dynamic>? ?? [];
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _session?.userEmail ?? '';
    if (email.trim().isEmpty) {
      showAppMessage(context, AppText.t('missing_recharge_email'));
      return;
    }

    final operatorName = _operator;
    if (operatorName == null) {
      showAppMessage(context, AppText.t('invalid_operator_number'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = _otpSent
        ? await _api.confirmMobileRecharge(
            email: email,
            mobileNumber: _onlyDigits(_phone.text),
            operatorName: operatorName,
            amount: _amount.text.trim(),
            otp: _otp.text.trim(),
          )
        : await _api.requestMobileRechargeOtp(
            email: email,
            mobileNumber: _onlyDigits(_phone.text),
            operatorName: operatorName,
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
        _total = double.tryParse(result.data['total_amount']?.toString() ?? '') ??
            (double.tryParse(_amount.text.trim()) ?? 0) + _charge;
      });
      showAppMessage(context, AppText.t('otp_sent_message'));
      return;
    }

    await _refreshSessionBalance();
    await _saveBeneficiary(email, operatorName);
    if (!mounted) return;
    _showSuccessSheet(result.data['recharge'] as Map<String, dynamic>? ?? {});
  }

  Future<void> _saveBeneficiary(String email, String operatorName) async {
    await _api.saveBeneficiary(
      email: email,
      type: 'recharge',
      label: '${_onlyDigits(_phone.text)} Recharge',
      provider: operatorName,
      accountName: '',
      accountNumber: '',
      mobileNumber: _onlyDigits(_phone.text),
      isFavorite: _beneficiaries.isEmpty,
    );
  }

  void _applyBeneficiary(Map<String, dynamic> item) {
    setState(() {
      _phone.text = item['mobile_number']?.toString() ?? '';
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

  void _showSuccessSheet(Map<String, dynamic> recharge) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RechargeSuccessSheet(recharge: recharge),
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
        title: Text(
          AppText.t('recharge_title'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const _RechargeHeader(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
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
                  AppTextField(
                    controller: _phone,
                    label: AppText.t('mobile_number'),
                    hint: AppText.t('mobile_number_hint'),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  _BeneficiaryStrip(
                    items: _beneficiaries,
                    onTap: _applyBeneficiary,
                  ),
                  const SizedBox(height: 10),
                  _OperatorInfo(operatorName: _operator),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _amount,
                    label: AppText.t('amount'),
                    hint: AppText.t('amount_hint'),
                    keyboardType: TextInputType.number,
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in _amounts)
                        _ChoicePill(
                          label: '৳$value',
                          selected: _amount.text == value,
                          onTap: () => setState(() => _amount.text = value),
                        ),
                    ],
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _otp,
                      label: AppText.t('otp_code'),
                      hint: AppText.t('otp_hint'),
                      keyboardType: TextInputType.number,
                      validator: _validateOtp,
                    ),
                    const SizedBox(height: 12),
                    _RechargeChargeSummary(charge: _charge, total: _total),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: _otpSent
                        ? AppText.t('confirm_recharge')
                        : AppText.t('send_otp'),
                    icon: _otpSent
                        ? Icons.verified_rounded
                        : Icons.mark_email_read_rounded,
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

  String? _validatePhone(String? value) {
    final phone = _onlyDigits(value ?? '');
    if (phone.length != 11) return AppText.t('invalid_mobile_number');
    if (_detectOperator(phone) == null) {
      return AppText.t('invalid_operator_number');
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final amount = num.tryParse(value?.trim() ?? '');
    if (amount == null) return AppText.t('invalid_amount');
    return AppRuntimeSettings.instance.amountError('mobile_recharge', amount.toDouble());
  }

  String? _validateOtp(String? value) {
    final otp = _onlyDigits(value ?? '');
    if (otp.length != 6) return AppText.t('invalid_otp');
    return null;
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String? _detectOperator(String value) {
    final phone = _onlyDigits(value);
    if (phone.length < 3) return null;
    final prefix = phone.substring(0, 3);
    return switch (prefix) {
      '013' || '017' => 'Grameenphone',
      '014' || '019' => 'Banglalink',
      '015' => 'Teletalk',
      '016' => 'Airtel',
      '018' => 'Robi',
      _ => null,
    };
  }
}

class _RechargeHeader extends StatelessWidget {
  const _RechargeHeader();

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
          const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.t('recharge_header_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppText.t('recharge_header_body'),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
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

class _OperatorInfo extends StatelessWidget {
  const _OperatorInfo({required this.operatorName});

  final String? operatorName;

  @override
  Widget build(BuildContext context) {
    final detected = operatorName != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: detected
            ? AppColors.financePrimary.withValues(alpha: .07)
            : AppColors.financeSurfaceLow,
        border: Border.all(
          color: detected ? AppColors.financePrimary : AppColors.financeLine,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            detected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: detected ? AppColors.financePrimary : AppColors.financeMuted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detected
                  ? '${AppText.t('detected_operator')}: $operatorName'
                  : AppText.t('operator_waiting'),
              style: TextStyle(
                color: detected ? AppColors.financePrimary : AppColors.financeMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
            final label = item['label']?.toString() ?? item['mobile_number']?.toString() ?? 'Saved';
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

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.financePrimary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.financePrimary : AppColors.financeLine,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RechargeChargeSummary extends StatelessWidget {
  const _RechargeChargeSummary({required this.charge, required this.total});

  final double charge;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.financePrimary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.financePrimary.withValues(alpha: .12)),
      ),
      child: Text(
        '${AppText.t('service_charge')}: BDT ${charge.toStringAsFixed(2)}  •  ${AppText.t('total')}: BDT ${total.toStringAsFixed(2)}',
        style: const TextStyle(
          color: AppColors.financePrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RechargeSuccessSheet extends StatelessWidget {
  const _RechargeSuccessSheet({required this.recharge});

  final Map<String, dynamic> recharge;

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
            const Icon(
              Icons.schedule_rounded,
              color: AppColors.financePrimary,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              AppText.t('recharge_successful'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _SuccessRow(
              label: AppText.t('transaction_id'),
              value: recharge['transaction_id']?.toString() ?? '-',
            ),
            _SuccessRow(
              label: AppText.t('operator'),
              value: recharge['operator']?.toString() ?? '-',
            ),
            _SuccessRow(
              label: AppText.t('amount'),
              value: '৳${recharge['amount'] ?? '-'}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.financeMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
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
