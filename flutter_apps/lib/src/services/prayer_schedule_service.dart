import 'dart:convert';

import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/services/internet_guard.dart';
import 'package:flutter_apps/src/services/location_service.dart';
import 'package:http/http.dart' as http;

class PrayerScheduleService {
  const PrayerScheduleService({LocationService locationService = const LocationService()})
      : _locationService = locationService;

  final LocationService _locationService;

  Future<PrayerSchedule?> loadToday() async {
    final online = await InternetGuard.ensureOnline();
    if (!online) return null;

    final location = await _locationService.detect();
    final city = _safeLocationValue(location.city) ?? location.countryName;
    final country = location.countryCode.trim().isNotEmpty
        ? location.countryCode
        : location.countryName;

    try {
      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': city,
        'country': country,
        'method': '2',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final timings = data['timings'] as Map<String, dynamic>? ?? {};
      final readableDate =
          (data['date'] as Map<String, dynamic>?)?['readable']?.toString() ?? '';

      final prayers = <PrayerTime>[
        PrayerTime(name: 'Fajr', time: _cleanTime(timings['Fajr'])),
        PrayerTime(name: 'Sunrise', time: _cleanTime(timings['Sunrise'])),
        PrayerTime(name: 'Dhuhr', time: _cleanTime(timings['Dhuhr'])),
        PrayerTime(name: 'Asr', time: _cleanTime(timings['Asr'])),
        PrayerTime(name: 'Maghrib', time: _cleanTime(timings['Maghrib'])),
        PrayerTime(name: 'Isha', time: _cleanTime(timings['Isha'])),
      ].where((prayer) => prayer.time.isNotEmpty).toList();

      if (prayers.isEmpty) return null;

      return PrayerSchedule(
        location: location,
        dateLabel: readableDate,
        prayers: prayers,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _safeLocationValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _cleanTime(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.split(' ').first.trim();
  }
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.location,
    required this.dateLabel,
    required this.prayers,
  });

  final GeoLocation location;
  final String dateLabel;
  final List<PrayerTime> prayers;

  int get activePrayerIndex {
    final now = DateTime.now();
    var activeIndex = prayers.isEmpty ? -1 : prayers.length - 1;

    for (var index = 0; index < prayers.length; index++) {
      final time = prayers[index].asDateTime(now);
      if (time == null) continue;
      if (now.isBefore(time)) return activeIndex;
      activeIndex = index;
    }

    return activeIndex;
  }
}

class PrayerTime {
  const PrayerTime({
    required this.name,
    required this.time,
  });

  final String name;
  final String time;

  DateTime? asDateTime(DateTime base) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }
}
