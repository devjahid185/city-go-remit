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
        message: body['message']?.toString() ?? 'Payment initialized.',
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to Sokher Bazar payment server.',
      );
    }
  }
}
