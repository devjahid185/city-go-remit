import 'package:flutter/services.dart';

class LinkLauncher {
  const LinkLauncher();

  static const _channel = MethodChannel('city_go_remit/links');

  Future<bool> open(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    try {
      return await _channel.invokeMethod<bool>('openUrl', {'url': trimmed}) ?? false;
    } catch (_) {
      return false;
    }
  }
}
