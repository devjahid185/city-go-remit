import 'dart:convert';

import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:http/http.dart' as http;

class LocationService {
  const LocationService();

  static const _dialCodes = {
    'BD': '+880',
    'IN': '+91',
    'PK': '+92',
    'US': '+1',
    'GB': '+44',
    'AE': '+971',
    'SA': '+966',
    'MY': '+60',
    'SG': '+65',
    'CA': '+1',
    'AU': '+61',
  };

  Future<GeoLocation> detect() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final countryCode =
          data['country_code']?.toString().toUpperCase() ?? 'BD';
      return GeoLocation(
        countryName: data['country_name']?.toString() ?? 'Bangladesh',
        countryCode: countryCode,
        dialCode: _dialCodes[countryCode] ?? '+880',
        flag: _flagFromCountryCode(countryCode),
        city: data['city']?.toString(),
        ip: data['ip']?.toString(),
      );
    } catch (_) {
      return GeoLocation.fallback();
    }
  }

  String _flagFromCountryCode(String countryCode) {
    if (countryCode.length != 2) return '🇧🇩';
    final first = countryCode.codeUnitAt(0) - 65 + 0x1F1E6;
    final second = countryCode.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }
}
