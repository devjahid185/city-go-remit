import 'dart:convert';

import 'package:flutter_apps/src/services/api_result.dart';
import 'package:flutter_apps/src/services/internet_guard.dart';
import 'package:http/http.dart' as http;

class SokherBazarPaymentApi {
  const SokherBazarPaymentApi({
    this.baseUrl = 'https://sokherbazar.shop/api/v4',
  });

  final String baseUrl;

  Future<ApiResult> initAddMoney({
    required String amount,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String country,
  }) async {
    if (!await InternetGuard.ensureOnline()) {
      return const ApiResult(
        ok: false,
        message: 'No internet connection. Please check your connection and try again.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/city-go-remit/add-money/init'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'amount': amount,
              'name': name,
              'email': email,
              'phone': phone,
              'address': address,
              'country': country,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 &&
            response.statusCode < 300 &&
            body['success'] == true,
        message: _safeMessage(body['message']?.toString(), 'Payment initialized.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the payment gateway. Please try again.',
      );
    }
  }

  String _safeMessage(String? message, String fallback) {
    final cleaned = (message ?? fallback)
        .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), 'the server')
        .replaceAll(RegExp(r'\b(?:[a-z0-9-]+\.)+[a-z]{2,}(?:\/\S*)?', caseSensitive: false), 'the server')
        .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?(?:\/\S*)?'), 'the server')
        .replaceAll(RegExp(r'\bAPI URL\b', caseSensitive: false), 'server connection')
        .replaceAll(RegExp(r'\bbase URL\b', caseSensitive: false), 'server connection')
        .trim();

    return cleaned.isEmpty ? fallback : cleaned;
  }
}
