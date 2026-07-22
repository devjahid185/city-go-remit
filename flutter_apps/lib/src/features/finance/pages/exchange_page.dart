import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  final _api = AuthApi();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _api.exchangeRates();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rates = result.ok
          ? List<Map<String, dynamic>>.from(result.data['rates'] as List? ?? [])
          : [];
    });
    if (!result.ok) showAppMessage(context, result.message);
  }

  List<Map<String, dynamic>> get _filteredRates {
    final keyword = _search.text.trim().toLowerCase();
    if (keyword.isEmpty) return _rates;

    return _rates.where((rate) {
      final text = [
        rate['country_name'],
        rate['country_code'],
        rate['currency_code'],
        rate['currency_name'],
      ].join(' ').toLowerCase();
      return text.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rates = _filteredRates;

    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          AppText.t('exchange_rates_title'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.financePrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.financePrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.financePrimary.withValues(alpha: .16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.currency_exchange_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppText.t('exchange_header_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${_rates.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.financeMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: AppText.t('exchange_search_hint'),
                              hintStyle: const TextStyle(color: AppColors.financeMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rates.isEmpty)
              _EmptyRatesCard(message: AppText.t('exchange_empty'))
            else
              for (final rate in rates) _ExchangeRateCard(rate: rate),
          ],
        ),
      ),
    );
  }
}

class _ExchangeRateCard extends StatelessWidget {
  const _ExchangeRateCard({required this.rate});

  final Map<String, dynamic> rate;

  @override
  Widget build(BuildContext context) {
    final currencyCode = rate['currency_code']?.toString() ?? '';
    final currencyName = rate['currency_name']?.toString() ?? '';
    final bdtRate = double.tryParse(rate['bdt_rate']?.toString() ?? '') ?? 0;
    final serviceFee = double.tryParse(rate['service_fee']?.toString() ?? '') ?? 0;
    final deliveryTime = rate['delivery_time']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rate['country_flag']?.toString().isNotEmpty == true
                      ? rate['country_flag'].toString()
                      : '🏳️',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate['country_name']?.toString() ?? 'Country',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$currencyCode ${currencyName.isEmpty ? '' : '• $currencyName'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.financeMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BDT ${bdtRate.toStringAsFixed(bdtRate < 10 ? 4 : 2)}',
                    style: const TextStyle(
                      color: AppColors.financePrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '1 $currencyCode',
                    style: const TextStyle(
                      color: AppColors.financeMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(label: AppText.t('service_fee'), value: 'BDT ${serviceFee.toStringAsFixed(2)}'),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: AppText.t('delivery_time'),
                  value: deliveryTime.isEmpty ? 'Standard' : deliveryTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.financeMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyRatesCard extends StatelessWidget {
  const _EmptyRatesCard({required this.message});

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
      child: Column(
        children: [
          const Icon(Icons.currency_exchange_rounded, color: AppColors.financePrimary, size: 34),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.financeMuted)),
        ],
      ),
    );
  }
}
