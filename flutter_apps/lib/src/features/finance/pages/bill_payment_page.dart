import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class BillPaymentPage extends StatefulWidget {
  const BillPaymentPage({super.key});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _contact = TextEditingController();
  final _amount = TextEditingController();
  final _otp = TextEditingController();
  final _api = AuthApi();

  AppSession? _session;
  List<dynamic> _beneficiaries = [];
  BillCategory _category = billCategories.first;
  late BillProvider _provider = _category.providers.first;
  String _billType = 'Postpaid';
  late String _billingPeriod = _billingPeriods.first;
  bool _loading = false;
  bool _otpSent = false;
  double _charge = 0;
  double _total = 0;

  static final _billingPeriods = _buildBillingPeriods();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await const SessionStore().load();
    if (!mounted) return;
    setState(() => _session = session);
    _loadBeneficiaries(session.userEmail);
  }

  Future<void> _loadBeneficiaries(String email) async {
    if (email.trim().isEmpty) return;
    final result = await _api.beneficiaries(email: email, type: 'bill');
    if (!mounted || !result.ok) return;
    setState(() {
      _beneficiaries = result.data['beneficiaries'] as List<dynamic>? ?? [];
    });
  }

  @override
  void dispose() {
    _account.dispose();
    _contact.dispose();
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
        ? await _api.confirmBillPayment(
            email: email,
            category: _category.key,
            provider: _provider.name,
            billType: _billType,
            accountNumber: _account.text.trim(),
            contactNumber: _contact.text.trim(),
            billingPeriod: _billingPeriod,
            amount: _amount.text.trim(),
            otp: _otp.text.trim(),
          )
        : await _api.requestBillPaymentOtp(
            email: email,
            category: _category.key,
            provider: _provider.name,
            billType: _billType,
            accountNumber: _account.text.trim(),
            contactNumber: _contact.text.trim(),
            billingPeriod: _billingPeriod,
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
    _showSubmittedSheet(result.data['bill_payment'] as Map<String, dynamic>? ?? {});
  }

  Future<void> _saveBeneficiary(String email) async {
    await _api.saveBeneficiary(
      email: email,
      type: 'bill',
      label: '${_provider.name} Bill',
      provider: _provider.name,
      accountName: '',
      accountNumber: _account.text.trim(),
      mobileNumber: _contact.text.trim(),
      isFavorite: _beneficiaries.isEmpty,
    );
  }

  void _applyBeneficiary(Map<String, dynamic> item) {
    final providerName = item['provider']?.toString() ?? '';
    for (final category in billCategories) {
      for (final provider in category.providers) {
        if (provider.name == providerName) {
          setState(() {
            _category = category;
            _provider = provider;
            _billType = category.types.first;
            _account.text = item['account_number']?.toString() ?? '';
            _contact.text = item['mobile_number']?.toString() ?? '';
            _otpSent = false;
            _otp.clear();
          });
          return;
        }
      }
    }

    setState(() {
      _account.text = item['account_number']?.toString() ?? '';
      _contact.text = item['mobile_number']?.toString() ?? '';
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

  void _showSubmittedSheet(Map<String, dynamic> bill) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BillSubmittedSheet(bill: bill),
    );
  }

  void _changeCategory(BillCategory category) {
    setState(() {
      _category = category;
      _provider = category.providers.first;
      _billType = category.types.first;
      _otpSent = false;
      _otp.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final types = _category.types;
    if (!types.contains(_billType)) _billType = types.first;

    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(AppText.t('bill_payment_title'), style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const _BillHeader(),
          const SizedBox(height: 16),
          _CategorySelector(selected: _category, onChanged: _changeCategory),
          const SizedBox(height: 14),
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
                  _DropdownField<BillProvider>(
                    label: AppText.t('bill_provider'),
                    value: _provider,
                    items: _category.providers,
                    itemLabel: (item) => item.name,
                    onChanged: (value) => setState(() => _provider = value),
                  ),
                  _BeneficiaryStrip(
                    items: _beneficiaries,
                    onTap: _applyBeneficiary,
                  ),
                  const SizedBox(height: 12),
                  _DropdownField<String>(
                    label: AppText.t('bill_type'),
                    value: _billType,
                    items: types,
                    itemLabel: (item) => item,
                    onChanged: (value) => setState(() => _billType = value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _account,
                    label: _provider.accountLabel,
                    hint: _provider.accountHint,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _contact,
                    label: AppText.t('contact_number'),
                    hint: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _DropdownField<String>(
                    label: AppText.t('billing_period'),
                    value: _billingPeriod,
                    items: _billingPeriods,
                    itemLabel: (item) => item,
                    onChanged: (value) => setState(() => _billingPeriod = value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amount,
                    label: AppText.t('amount'),
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
                    label: _otpSent ? AppText.t('confirm_bill_payment') : AppText.t('send_otp'),
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

  String? _amountValidator(String? value) {
    final amount = num.tryParse(value?.trim() ?? '');
    if (amount == null) return AppText.t('invalid_amount');
    if (amount < 10) return AppText.t('min_recharge');
    if (amount > 500000) return AppText.t('max_bill_payment');
    return null;
  }

  String? _otpValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return AppText.t('invalid_otp');
    return null;
  }
}

class _BillHeader extends StatelessWidget {
  const _BillHeader();

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
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppText.t('bill_payment_header'),
              style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onChanged});

  final BillCategory selected;
  final ValueChanged<BillCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = billCategories[index];
          final active = category == selected;
          return InkWell(
            onTap: () => onChanged(category),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.financePrimary : Colors.white,
                border: Border.all(color: active ? AppColors.financePrimary : AppColors.financeLine),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                category.label,
                style: TextStyle(color: active ? Colors.white : AppColors.financeMuted, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: billCategories.length,
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
            final label = item['label']?.toString() ?? item['provider']?.toString() ?? 'Saved bill';
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(itemLabel(item))),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.financeSurfaceLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

class _BillSubmittedSheet extends StatelessWidget {
  const _BillSubmittedSheet({required this.bill});

  final Map<String, dynamic> bill;

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
            Text(AppText.t('bill_request_submitted'), style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(bill['transaction_id']?.toString() ?? '-', style: const TextStyle(color: AppColors.financeMuted, fontWeight: FontWeight.w500)),
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

class BillCategory {
  const BillCategory(this.key, this.label, this.providers, this.types);

  final String key;
  final String label;
  final List<BillProvider> providers;
  final List<String> types;
}

class BillProvider {
  const BillProvider(this.name, this.accountLabel, this.accountHint);

  final String name;
  final String accountLabel;
  final String accountHint;
}

const billCategories = [
  BillCategory('electricity', 'Electricity', [
    BillProvider('BPDB', 'Meter / Account Number', 'Meter or bill account'),
    BillProvider('DESCO', 'Meter / Account Number', 'DESCO account'),
    BillProvider('DPDC', 'Meter / Account Number', 'DPDC account'),
    BillProvider('Palli Bidyut', 'SMS / Meter Number', 'SMS or meter number'),
    BillProvider('NESCO', 'Meter / Account Number', 'NESCO account'),
    BillProvider('West Zone Power', 'Meter / Account Number', 'WZPDCL account'),
  ], ['Prepaid', 'Postpaid']),
  BillCategory('gas', 'Gas', [
    BillProvider('Titas Gas', 'Customer Code', 'Customer code'),
    BillProvider('Jalalabad Gas', 'Customer Code', 'Customer code'),
    BillProvider('Karnaphuli Gas', 'Customer Code', 'Customer code'),
    BillProvider('Sundarban Gas', 'Customer Code', 'Customer code'),
    BillProvider('Bakhrabad Gas', 'Customer Code', 'Customer code'),
  ], ['Postpaid']),
  BillCategory('water', 'Water', [
    BillProvider('Dhaka WASA', 'Customer Number', 'WASA customer number'),
    BillProvider('Chattogram WASA', 'Customer Number', 'WASA customer number'),
    BillProvider('Rajshahi WASA', 'Customer Number', 'WASA customer number'),
    BillProvider('Khulna WASA', 'Customer Number', 'WASA customer number'),
  ], ['Postpaid']),
  BillCategory('internet', 'Internet', [
    BillProvider('Broadband Internet', 'Subscriber ID', 'Subscriber ID'),
    BillProvider('ISP / WiFi Bill', 'Customer ID', 'Customer ID'),
  ], ['Monthly']),
  BillCategory('telephone', 'Telephone', [
    BillProvider('BTCL', 'Telephone Number', 'Landline number'),
    BillProvider('Postpaid Mobile', 'Mobile Number', 'Postpaid number'),
  ], ['Postpaid']),
  BillCategory('tv', 'TV', [
    BillProvider('Cable TV', 'Subscriber ID', 'Subscriber ID'),
    BillProvider('DTH / Akash', 'Subscriber ID', 'Subscriber ID'),
  ], ['Monthly']),
  BillCategory('credit_card', 'Credit Card', [
    BillProvider('Visa Credit Card', 'Card Last 4 / Account', 'Card reference'),
    BillProvider('AMEX Credit Card', 'Card Last 4 / Account', 'Card reference'),
    BillProvider('Bank Credit Card', 'Card Last 4 / Account', 'Card reference'),
  ], ['Statement']),
  BillCategory('education', 'Education', [
    BillProvider('School Fee', 'Student ID', 'Student ID'),
    BillProvider('College Fee', 'Student ID', 'Student ID'),
    BillProvider('University Fee', 'Student ID', 'Student ID'),
  ], ['Tuition', 'Admission', 'Exam']),
  BillCategory('insurance', 'Insurance', [
    BillProvider('Life Insurance', 'Policy Number', 'Policy number'),
    BillProvider('Health Insurance', 'Policy Number', 'Policy number'),
  ], ['Premium']),
  BillCategory('government', 'Government', [
    BillProvider('City Corporation', 'Holding / Reference', 'Holding or reference'),
    BillProvider('Land Fee', 'Holding / Mutation ID', 'Holding or mutation ID'),
    BillProvider('BRTA Fee', 'Reference Number', 'Reference number'),
  ], ['Fee', 'Tax']),
  BillCategory('loan', 'Loan / EMI', [
    BillProvider('Loan Repayment', 'Loan Account', 'Loan account'),
    BillProvider('EMI Payment', 'EMI Reference', 'EMI reference'),
  ], ['Installment']),
  BillCategory('donation', 'Donation', [
    BillProvider('Donation', 'Reference', 'Reference'),
    BillProvider('Charity', 'Reference', 'Reference'),
  ], ['Donation']),
];

List<String> _buildBillingPeriods() {
  final now = DateTime.now();

  return [
    for (var offset = -6; offset <= 3; offset++)
      _periodLabel(DateTime(now.year, now.month + offset)),
  ].reversed.toList();
}

String _periodLabel(DateTime date) {
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${monthNames[date.month - 1]} ${date.year}';
}
