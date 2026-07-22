import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class DriveOfferPage extends StatefulWidget {
  const DriveOfferPage({super.key});

  @override
  State<DriveOfferPage> createState() => _DriveOfferPageState();
}

class _DriveOfferPageState extends State<DriveOfferPage>
    with SingleTickerProviderStateMixin {
  final _api = AuthApi();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  late final TabController _tabController;
  AppSession? _session;
  List<Map<String, dynamic>> _offers = [];
  Map<String, dynamic>? _selectedOffer;
  bool _loading = true;
  bool _submitting = false;
  bool _otpSent = false;

  static const _operators = [
    'Grameenphone',
    'Robi',
    'Airtel',
    'Banglalink',
    'Teletalk',
  ];

  String? get _numberOperator => _detectOperator(_phone.text);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _operators.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _phone.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedOffer = null;
      _otpSent = false;
      _otp.clear();
    });
  }

  Future<void> _load() async {
    final session = await const SessionStore().load();
    final result = await _api.driveOffers();
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
      _offers = result.ok
          ? List<Map<String, dynamic>>.from(result.data['offers'] as List? ?? [])
          : [];
    });
    if (!result.ok) showAppMessage(context, result.message);
  }

  Future<void> _submit() async {
    final email = _session?.userEmail ?? '';
    final offer = _selectedOffer;
    final number = _onlyDigits(_phone.text);
    final detectedOperator = _numberOperator;

    if (email.trim().isEmpty) {
      showAppMessage(context, AppText.t('missing_recharge_email'));
      return;
    }
    if (offer == null) {
      showAppMessage(context, AppText.t('select_drive_offer'));
      return;
    }
    if (number.length != 11 || detectedOperator == null) {
      showAppMessage(context, AppText.t('invalid_mobile_number'));
      return;
    }
    if (detectedOperator != offer['operator']) {
      showAppMessage(context, AppText.t('offer_operator_mismatch'));
      return;
    }
    if (_otpSent && _onlyDigits(_otp.text).length != 6) {
      showAppMessage(context, AppText.t('invalid_otp'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final result = _otpSent
        ? await _api.confirmDriveOffer(
            email: email,
            driveOfferId: offer['id'].toString(),
            mobileNumber: number,
            operatorName: detectedOperator,
            otp: _onlyDigits(_otp.text),
          )
        : await _api.requestDriveOfferOtp(
            email: email,
            driveOfferId: offer['id'].toString(),
            mobileNumber: number,
            operatorName: detectedOperator,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.ok) {
      showAppMessage(context, result.message);
      return;
    }

    if (!_otpSent) {
      setState(() => _otpSent = true);
      showAppMessage(context, AppText.t('otp_sent_message'));
      return;
    }

    await _refreshSessionBalance();
    if (!mounted) return;
    _showSuccess(result.data['drive_offer_order'] as Map<String, dynamic>? ?? {});
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

  void _showSuccess(Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriveOfferSuccessSheet(order: order),
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
          AppText.t('drive_offer_title'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.financeLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.financeMuted,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.financePrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              tabs: [
                for (final operator in _operators)
                  Tab(height: 38, text: operator),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                for (final operator in _operators)
                  _OfferOperatorView(
                    operatorName: operator,
                    offers: _offers
                        .where((offer) => offer['operator'] == operator)
                        .toList(),
                    selectedOffer: _selectedOffer,
                    phone: _phone,
                    otp: _otp,
                    otpSent: _otpSent,
                    submitting: _submitting,
                    numberOperator: _numberOperator,
                    onSelectOffer: (offer) => setState(() {
                      _selectedOffer = offer;
                      _otpSent = false;
                      _otp.clear();
                    }),
                    onSubmit: _submit,
                  ),
              ],
            ),
    );
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

class _OfferOperatorView extends StatelessWidget {
  const _OfferOperatorView({
    required this.operatorName,
    required this.offers,
    required this.selectedOffer,
    required this.phone,
    required this.otp,
    required this.otpSent,
    required this.submitting,
    required this.numberOperator,
    required this.onSelectOffer,
    required this.onSubmit,
  });

  final String operatorName;
  final List<Map<String, dynamic>> offers;
  final Map<String, dynamic>? selectedOffer;
  final TextEditingController phone;
  final TextEditingController otp;
  final bool otpSent;
  final bool submitting;
  final String? numberOperator;
  final ValueChanged<Map<String, dynamic>> onSelectOffer;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final hasSelectedOffer = selectedOffer?['operator'] == operatorName;
    final numberMismatch = phone.text.trim().isNotEmpty &&
        numberOperator != null &&
        numberOperator != operatorName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Text(
              operatorName,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.financeSurfaceLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.financeLine),
              ),
              child: Text(
                '${offers.length} ${AppText.t('offers')}',
                style: const TextStyle(
                  color: AppColors.financeMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (offers.isEmpty)
          const _EmptyOffer()
        else
          ...offers.map(
            (offer) => _OfferCard(
              offer: offer,
              selected: selectedOffer?['id'] == offer['id'],
              onTap: () => onSelectOffer(offer),
            ),
          ),
        if (hasSelectedOffer) ...[
          const SizedBox(height: 10),
          _SelectedOfferForm(
            offer: selectedOffer!,
            phone: phone,
            otp: otp,
            otpSent: otpSent,
            submitting: submitting,
            numberOperator: numberOperator,
            numberMismatch: numberMismatch,
            onSubmit: onSubmit,
          ),
        ],
      ],
    );
  }
}

class _SelectedOfferForm extends StatelessWidget {
  const _SelectedOfferForm({
    required this.offer,
    required this.phone,
    required this.otp,
    required this.otpSent,
    required this.submitting,
    required this.numberOperator,
    required this.numberMismatch,
    required this.onSubmit,
  });

  final Map<String, dynamic> offer;
  final TextEditingController phone;
  final TextEditingController otp;
  final bool otpSent;
  final bool submitting;
  final String? numberOperator;
  final bool numberMismatch;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sim_card_rounded, color: AppColors.financePrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppText.t('number_after_offer'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: phone,
            label: AppText.t('mobile_number'),
            hint: AppText.t('mobile_number_hint'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _NumberOperatorStatus(
            offerOperator: offer['operator']?.toString() ?? '',
            numberOperator: numberOperator,
            mismatch: numberMismatch,
          ),
          if (otpSent) ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: otp,
              label: AppText.t('otp_code'),
              hint: AppText.t('otp_hint'),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: otpSent
                ? AppText.t('confirm_drive_offer')
                : AppText.t('send_otp'),
            icon: otpSent
                ? Icons.verified_rounded
                : Icons.mark_email_read_rounded,
            loading: submitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _NumberOperatorStatus extends StatelessWidget {
  const _NumberOperatorStatus({
    required this.offerOperator,
    required this.numberOperator,
    required this.mismatch,
  });

  final String offerOperator;
  final String? numberOperator;
  final bool mismatch;

  @override
  Widget build(BuildContext context) {
    final ready = numberOperator != null && !mismatch;
    final text = numberOperator == null
        ? AppText.t('operator_waiting')
        : mismatch
            ? AppText.t('offer_operator_mismatch')
            : '$numberOperator ${AppText.t('number_matched')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFEFFAF4) : AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready ? const Color(0xFFB9E7CD) : AppColors.financeLine,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: ready ? const Color(0xFF18884F) : AppColors.financeMuted,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ready ? const Color(0xFF16603B) : AppColors.financeMuted,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = num.tryParse(offer['total_amount']?.toString() ?? '') ??
        num.tryParse(offer['price']?.toString() ?? '') ??
        0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF4F4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.financePrimary : AppColors.financeLine,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.public_rounded, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['title']?.toString() ?? '-',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer['data_amount'] ?? '-'} · ${offer['validity'] ?? '-'}',
                      style: const TextStyle(color: AppColors.financeMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? AppColors.financePrimary : AppColors.financeMuted,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOffer extends StatelessWidget {
  const _EmptyOffer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Text(
        AppText.t('no_drive_offers'),
        style: const TextStyle(color: AppColors.financeMuted, height: 1.4),
      ),
    );
  }
}

class _DriveOfferSuccessSheet extends StatelessWidget {
  const _DriveOfferSuccessSheet({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.financeLine,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF18884F), size: 54),
          const SizedBox(height: 12),
          Text(
            AppText.t('drive_offer_submitted'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _SuccessRow(label: AppText.t('transaction_id'), value: order['transaction_id']?.toString() ?? '-'),
          _SuccessRow(label: AppText.t('operator'), value: order['operator']?.toString() ?? '-'),
          _SuccessRow(label: AppText.t('amount'), value: '৳${order['total_amount'] ?? '-'}'),
          const SizedBox(height: 20),
          AppButton(
            label: AppText.t('done'),
            icon: Icons.done_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.financeMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
