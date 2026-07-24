import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/payment_webview_page.dart';
import 'package:flutter_apps/src/services/app_runtime_settings.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/location_service.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/services/sokher_bazar_payment_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';

class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final _api = AuthApi();
  final _paymentApi = const SokherBazarPaymentApi();
  final _amount = TextEditingController();
  List<Map<String, dynamic>> _rates = [];
  Map<String, dynamic>? _selectedRate;
  String _countryCode = '';
  String _countryName = 'Bangladesh';
  bool _loading = true;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final location = await const LocationService().detect();
    final settingsFuture = AppRuntimeSettings.instance.load();
    final result = await _api.exchangeRates();
    await settingsFuture;
    if (!mounted) return;

    final rates = result.ok
        ? List<Map<String, dynamic>>.from(result.data['rates'] as List? ?? [])
        : <Map<String, dynamic>>[];
    Map<String, dynamic>? matchedRate;
    for (final rate in rates) {
      if (rate['country_code']?.toString().toUpperCase() ==
          location.countryCode.toUpperCase()) {
        matchedRate = rate;
        break;
      }
    }

    setState(() {
      _countryCode = location.countryCode;
      _countryName = location.countryName;
      _rates = rates;
      _selectedRate = matchedRate ?? (rates.isNotEmpty ? rates.first : null);
      _loading = false;
    });

    if (!result.ok) showAppMessage(context, result.message);
  }

  double get _inputAmount => double.tryParse(_amount.text.trim()) ?? 0;
  double get _rate => double.tryParse(_selectedRate?['bdt_rate']?.toString() ?? '') ?? 0;
  double get _fee => double.tryParse(_selectedRate?['service_fee']?.toString() ?? '') ?? 0;
  double get _bdtAmount => _inputAmount * _rate;
  double get _totalBdt => _bdtAmount + (_inputAmount > 0 ? _fee : 0);

  Future<void> _continuePayment() async {
    if (!AppRuntimeSettings.instance.service('add_money').enabled) {
      showAppMessage(context, AppText.t('service_unavailable'));
      return;
    }

    final amountError = AppRuntimeSettings.instance.amountError('add_money', _totalBdt);
    if (amountError != null) {
      showAppMessage(context, amountError);
      return;
    }

    setState(() => _initializing = true);
    final session = await const SessionStore().load();
    final result = await _paymentApi.initAddMoney(
      amount: _totalBdt.toStringAsFixed(2),
      name: session.userName,
      email: session.userEmail,
      phone: session.userPhone,
      address: session.userAddress,
      country: _countryName,
    );
    if (!mounted) return;
    setState(() => _initializing = false);

    if (!result.ok) {
      showAppMessage(context, result.message);
      return;
    }

    final payUrl = result.data['pay_url']?.toString() ?? '';
    if (payUrl.isEmpty) {
      showAppMessage(context, AppText.t('payment_link_unavailable'));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(
          url: payUrl,
          title: AppText.t('add_money'),
        ),
      ),
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
          AppText.t('add_money'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.financePrimary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedRate == null)
              _EmptyAddMoneyCard(message: AppText.t('exchange_empty'))
            else ...[
              _CountryRateCard(
                rates: _rates,
                selectedRate: _selectedRate!,
                countryCode: _countryCode,
                onChanged: (rate) => setState(() => _selectedRate = rate),
              ),
              const SizedBox(height: 14),
              _AmountCard(
                controller: _amount,
                rate: _selectedRate!,
                convertedAmount: _bdtAmount,
                fee: _fee,
                total: _totalBdt,
                loading: _initializing,
                onContinue: _continuePayment,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountryRateCard extends StatelessWidget {
  const _CountryRateCard({
    required this.rates,
    required this.selectedRate,
    required this.countryCode,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> rates;
  final Map<String, dynamic> selectedRate;
  final String countryCode;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final currencyCode = selectedRate['currency_code']?.toString() ?? '';
    final countryFlag = selectedRate['country_flag']?.toString() ?? '';
    final bdtRate = double.tryParse(selectedRate['bdt_rate']?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.financePrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.financePrimary.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  countryFlag.isEmpty ? countryCode : countryFlag,
                  style: const TextStyle(fontSize: 25),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRate,
                    dropdownColor: AppColors.financePrimary,
                    iconEnabledColor: Colors.white,
                    isExpanded: true,
                    items: [
                      for (final rate in rates)
                        DropdownMenuItem(
                          value: rate,
                          child: Text(
                            '${rate['country_name']}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (rate) {
                      if (rate != null) onChanged(rate);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '1 $currencyCode = BDT ${bdtRate.toStringAsFixed(bdtRate < 10 ? 4 : 2)}',
              style: const TextStyle(
                color: AppColors.financePrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.rate,
    required this.convertedAmount,
    required this.fee,
    required this.total,
    required this.loading,
    required this.onContinue,
  });

  final TextEditingController controller;
  final Map<String, dynamic> rate;
  final double convertedAmount;
  final double fee;
  final double total;
  final bool loading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final currencyCode = rate['currency_code']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: AppText.t('you_send'),
              suffixText: currencyCode,
              filled: true,
              fillColor: AppColors.financeSurfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _MoneyResultRow(
            label: AppText.t('you_get'),
            value: 'BDT ${convertedAmount.toStringAsFixed(2)}',
            highlighted: true,
          ),
          if (fee > 0) ...[
            const SizedBox(height: 8),
            _MoneyResultRow(
              label: AppText.t('service_fee'),
              value: 'BDT ${fee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _MoneyResultRow(
              label: AppText.t('total'),
              value: 'BDT ${total.toStringAsFixed(2)}',
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: loading ? null : onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.financePrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loading ? AppText.t('processing') : AppText.t('continue'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyResultRow extends StatelessWidget {
  const _MoneyResultRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF1F2) : AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
          Text(
            value,
            style: TextStyle(
              color: highlighted ? AppColors.financePrimary : AppColors.ink,
              fontSize: highlighted ? 18 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddMoneyCard extends StatelessWidget {
  const _EmptyAddMoneyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.financeMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
