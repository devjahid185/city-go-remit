import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';

class AppRuntimeSettings {
  AppRuntimeSettings._();

  static final instance = AppRuntimeSettings._();

  final _api = AuthApi();
  Map<String, ServiceRuntimeSetting> _services = _defaults;

  Future<Map<String, ServiceRuntimeSetting>> load() async {
    final result = await _api.appSettings();
    if (!result.ok) return _services;

    final settings = result.data['settings'] as Map<String, dynamic>? ?? {};
    final services = settings['services'] as Map<String, dynamic>? ?? {};
    _services = {
      ..._defaults,
      for (final entry in services.entries)
        entry.key: ServiceRuntimeSetting.fromJson(
          entry.value as Map<String, dynamic>? ?? {},
          fallback: _defaults[entry.key] ?? ServiceRuntimeSetting.defaultValue(),
        ),
    };

    return _services;
  }

  ServiceRuntimeSetting service(String key) {
    return _services[key] ?? ServiceRuntimeSetting.defaultValue();
  }

  String? amountError(String key, double amount) {
    final setting = service(key);
    if (amount <= 0) return AppText.t('invalid_amount');
    if (amount < setting.minAmount || amount > setting.maxAmount) {
      return AppText.t('amount_limit_message')
          .replaceFirst(':min', setting.minAmount.toStringAsFixed(2))
          .replaceFirst(':max', setting.maxAmount.toStringAsFixed(2));
    }
    return null;
  }

  static const _defaults = {
    'add_money': ServiceRuntimeSetting(minAmount: 10, maxAmount: 500000),
    'mobile_recharge': ServiceRuntimeSetting(minAmount: 10, maxAmount: 50000),
    'bill_payment': ServiceRuntimeSetting(minAmount: 10, maxAmount: 500000),
    'bank_transfer': ServiceRuntimeSetting(minAmount: 100, maxAmount: 500000),
    'wallet_withdrawal': ServiceRuntimeSetting(minAmount: 50, maxAmount: 500000),
  };
}

class ServiceRuntimeSetting {
  const ServiceRuntimeSetting({
    this.enabled = true,
    this.charge = 0,
    this.minAmount = 10,
    this.maxAmount = 500000,
  });

  final bool enabled;
  final double charge;
  final double minAmount;
  final double maxAmount;

  factory ServiceRuntimeSetting.defaultValue() {
    return const ServiceRuntimeSetting();
  }

  factory ServiceRuntimeSetting.fromJson(
    Map<String, dynamic> json, {
    required ServiceRuntimeSetting fallback,
  }) {
    return ServiceRuntimeSetting(
      enabled: json['enabled'] != false,
      charge: double.tryParse(json['charge']?.toString() ?? '') ?? fallback.charge,
      minAmount: double.tryParse(json['min_amount']?.toString() ?? '') ?? fallback.minAmount,
      maxAmount: double.tryParse(json['max_amount']?.toString() ?? '') ?? fallback.maxAmount,
    );
  }
}
