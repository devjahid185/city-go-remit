class GeoLocation {
  const GeoLocation({
    required this.countryName,
    required this.countryCode,
    required this.dialCode,
    required this.flag,
    this.city,
    this.ip,
  });

  final String countryName;
  final String countryCode;
  final String dialCode;
  final String flag;
  final String? city;
  final String? ip;

  String get addressHint {
    final resolvedCity = city == null || city!.isEmpty ? countryName : city!;
    return '$resolvedCity, $countryName';
  }

  factory GeoLocation.fallback() {
    return const GeoLocation(
      countryName: 'Bangladesh',
      countryCode: 'BD',
      dialCode: '+880',
      flag: '🇧🇩',
      city: 'Dhaka',
    );
  }
}
