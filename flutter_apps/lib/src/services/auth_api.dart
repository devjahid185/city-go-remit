import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_apps/src/services/api_result.dart';
import 'package:flutter_apps/src/services/internet_guard.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  AuthApi({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://cgr.sohojbazar.com/api',
    ),
  });

  final String baseUrl;

  Future<ApiResult> login({required String email, required String password}) {
    return _post('/login', {
      'email': email,
      'password': password,
      'platform': 'android',
    });
  }

  Future<ApiResult> googleLogin({required String idToken}) {
    return _post('/google-login', {
      'id_token': idToken,
      'platform': 'android',
    });
  }

  Future<ApiResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String address,
    String referralCode = '',
  }) {
    return _post('/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'address': address,
      'referral_code': referralCode,
    });
  }

  Future<ApiResult> kycRegister({
    required String email,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String fatherName,
    required String motherName,
    required String phone,
    required String address,
    required String countryName,
    required String countryCode,
    required String countryFlag,
    required String documentName,
    Uint8List? documentBytes,
    required String password,
    required String passwordConfirmation,
    required String source,
    String referralCode = '',
  }) {
    final payload = {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'father_name': fatherName,
      'mother_name': motherName,
      'phone': phone,
      'address': address,
      'country_name': countryName,
      'country_code': countryCode,
      'country_flag': countryFlag,
      'government_document_name': documentName,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'source': source,
      'referral_code': referralCode,
    };

    if (documentBytes == null) return _post('/kyc-register', payload);

    return _multipart(
      '/kyc-register',
      payload,
      fileField: 'government_document',
      fileName: documentName,
      fileBytes: documentBytes,
    );
  }

  Future<ApiResult> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) {
    return _post('/register/verify-otp', {'email': email, 'otp': otp});
  }

  Future<ApiResult> forgotPassword({required String email}) {
    return _post('/forgot-password', {'email': email});
  }

  Future<ApiResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) {
    return _post('/forgot-password/verify-otp', {
      'email': email,
      'otp': otp,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<ApiResult> changePassword({
    required String email,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _post('/change-password', {
      'email': email,
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<ApiResult> profile({required String email}) {
    return _get('/profile', {'email': email});
  }

  Future<ApiResult> updateProfile({
    required String currentEmail,
    required String email,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String fatherName,
    required String motherName,
    required String phone,
    required String address,
    required String countryName,
    required String countryCode,
    required String countryFlag,
    required String documentName,
    Uint8List? documentBytes,
  }) {
    final payload = {
      'current_email': currentEmail,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'father_name': fatherName,
      'mother_name': motherName,
      'phone': phone,
      'address': address,
      'country_name': countryName,
      'country_code': countryCode,
      'country_flag': countryFlag,
      'government_document_name': documentName,
    };

    if (documentBytes == null) return _post('/profile/update', payload);

    return _multipart(
      '/profile/update',
      payload,
      fileField: 'government_document',
      fileName: documentName,
      fileBytes: documentBytes,
    );
  }

  Future<ApiResult> homeBanners() {
    return _get('/banners', const {});
  }

  Future<ApiResult> exchangeRates() {
    return _get('/exchange-rates', const {});
  }

  Future<ApiResult> appSettings() {
    return _get('/settings', const {});
  }

  Future<ApiResult> registerNotificationToken({
    required String email,
    required String token,
    required String platform,
    required String deviceName,
  }) {
    return _post('/notification-token', {
      'email': email,
      'token': token,
      'platform': platform,
      'device_name': deviceName,
    });
  }

  Future<ApiResult> removeNotificationToken({required String token}) {
    return _delete('/notification-token', {'token': token});
  }

  Future<ApiResult> requestMobileRechargeOtp({
    required String email,
    required String mobileNumber,
    required String operatorName,
    required String amount,
  }) {
    return _post('/mobile-recharge/request-otp', {
      'email': email,
      'mobile_number': mobileNumber,
      'operator': operatorName,
      'amount': amount,
    });
  }

  Future<ApiResult> confirmMobileRecharge({
    required String email,
    required String mobileNumber,
    required String operatorName,
    required String amount,
    required String otp,
  }) {
    return _post('/mobile-recharge/confirm', {
      'email': email,
      'mobile_number': mobileNumber,
      'operator': operatorName,
      'amount': amount,
      'otp': otp,
    });
  }

  Future<ApiResult> requestBillPaymentOtp({
    required String email,
    required String category,
    required String provider,
    required String billType,
    required String accountNumber,
    required String contactNumber,
    required String billingPeriod,
    required String amount,
  }) {
    return _post('/bill-payment/request-otp', {
      'email': email,
      'category': category,
      'provider': provider,
      'bill_type': billType,
      'account_number': accountNumber,
      'contact_number': contactNumber,
      'billing_period': billingPeriod,
      'amount': amount,
    });
  }

  Future<ApiResult> confirmBillPayment({
    required String email,
    required String category,
    required String provider,
    required String billType,
    required String accountNumber,
    required String contactNumber,
    required String billingPeriod,
    required String amount,
    required String otp,
  }) {
    return _post('/bill-payment/confirm', {
      'email': email,
      'category': category,
      'provider': provider,
      'bill_type': billType,
      'account_number': accountNumber,
      'contact_number': contactNumber,
      'billing_period': billingPeriod,
      'amount': amount,
      'otp': otp,
    });
  }

  Future<ApiResult> requestBankTransferOtp({
    required String email,
    required String bankName,
    required String branchName,
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String contactNumber,
    required String amount,
  }) {
    return _post('/bank-transfer/request-otp', {
      'email': email,
      'bank_name': bankName,
      'branch_name': branchName,
      'account_name': accountName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'contact_number': contactNumber,
      'amount': amount,
    });
  }

  Future<ApiResult> confirmBankTransfer({
    required String email,
    required String bankName,
    required String branchName,
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String contactNumber,
    required String amount,
    required String otp,
  }) {
    return _post('/bank-transfer/confirm', {
      'email': email,
      'bank_name': bankName,
      'branch_name': branchName,
      'account_name': accountName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'contact_number': contactNumber,
      'amount': amount,
      'otp': otp,
    });
  }

  Future<ApiResult> requestWalletWithdrawalOtp({
    required String email,
    required String walletProvider,
    required String walletNumber,
    required String accountName,
    required String contactNumber,
    required String amount,
  }) {
    return _post('/wallet-withdrawal/request-otp', {
      'email': email,
      'wallet_provider': walletProvider,
      'wallet_number': walletNumber,
      'account_name': accountName,
      'contact_number': contactNumber,
      'amount': amount,
    });
  }

  Future<ApiResult> confirmWalletWithdrawal({
    required String email,
    required String walletProvider,
    required String walletNumber,
    required String accountName,
    required String contactNumber,
    required String amount,
    required String otp,
  }) {
    return _post('/wallet-withdrawal/confirm', {
      'email': email,
      'wallet_provider': walletProvider,
      'wallet_number': walletNumber,
      'account_name': accountName,
      'contact_number': contactNumber,
      'amount': amount,
      'otp': otp,
    });
  }

  Future<ApiResult> mobileRechargeHistory({required String email}) async {
    return _get('/mobile-recharges', {'email': email});
  }

  Future<ApiResult> driveOffers({String operatorName = ''}) async {
    return _get('/drive-offers', {
      if (operatorName.trim().isNotEmpty) 'operator': operatorName,
    });
  }

  Future<ApiResult> requestDriveOfferOtp({
    required String email,
    required String driveOfferId,
    required String mobileNumber,
    required String operatorName,
  }) {
    return _post('/drive-offer/request-otp', {
      'email': email,
      'drive_offer_id': driveOfferId,
      'mobile_number': mobileNumber,
      'operator': operatorName,
    });
  }

  Future<ApiResult> confirmDriveOffer({
    required String email,
    required String driveOfferId,
    required String mobileNumber,
    required String operatorName,
    required String otp,
  }) {
    return _post('/drive-offer/confirm', {
      'email': email,
      'drive_offer_id': driveOfferId,
      'mobile_number': mobileNumber,
      'operator': operatorName,
      'otp': otp,
    });
  }

  Future<ApiResult> histories({required String email}) async {
    return _get('/histories', {'email': email});
  }

  Future<ApiResult> beneficiaries({
    required String email,
    String type = '',
  }) async {
    return _get('/beneficiaries', {
      'email': email,
      if (type.trim().isNotEmpty) 'type': type,
    });
  }

  Future<ApiResult> saveBeneficiary({
    String? id,
    required String email,
    required String type,
    required String label,
    required String provider,
    required String accountName,
    required String accountNumber,
    required String mobileNumber,
    bool isFavorite = false,
  }) {
    final payload = {
      'email': email,
      'type': type,
      'label': label,
      'provider': provider,
      'account_name': accountName,
      'account_number': accountNumber,
      'mobile_number': mobileNumber,
      'is_favorite': isFavorite ? '1' : '0',
    };

    if (id == null || id.isEmpty) return _post('/beneficiaries', payload);

    return _put('/beneficiaries/$id', payload);
  }

  Future<ApiResult> deleteBeneficiary({
    required String id,
    required String email,
  }) {
    return _delete('/beneficiaries/$id', {'email': email});
  }

  Future<ApiResult> notifications({required String email}) async {
    return _get('/notifications', {'email': email});
  }

  Future<ApiResult> markNotificationsRead({
    required String email,
    String notificationId = '',
  }) {
    return _post('/notifications/read', {
      'email': email,
      if (notificationId.trim().isNotEmpty) 'notification_id': notificationId,
    });
  }

  Future<ApiResult> deviceHistory({required String email}) async {
    return _get('/security/devices', {'email': email});
  }

  String receiptUrl({
    required String type,
    required String transactionId,
    required String email,
  }) {
    final uri = Uri.parse('$baseUrl/receipts/$type/$transactionId').replace(
      queryParameters: {'email': email, 'format': 'html'},
    );
    return uri.toString();
  }

  Future<ApiResult> receipt({
    required String type,
    required String transactionId,
    required String email,
  }) async {
    return _get('/receipts/$type/$transactionId', {
      'email': email,
      'format': 'json',
    });
  }

  Future<ApiResult> chat({required String email, bool showOfflineAlert = true}) async {
    return _get('/chat', {'email': email}, showOfflineAlert: showOfflineAlert);
  }

  Future<ApiResult> sendChatMessage({
    required String email,
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) {
    if (imageBytes != null && imageName != null) {
      return _multipart(
        '/chat/messages',
        {'email': email, 'message': message},
        fileField: 'image',
        fileName: imageName,
        fileBytes: imageBytes,
      );
    }

    return _post('/chat/messages', {'email': email, 'message': message});
  }

  Future<ApiResult> sendChatTyping({required String email, bool showOfflineAlert = true}) {
    return _post('/chat/typing', {'email': email}, showOfflineAlert: showOfflineAlert);
  }

  Future<ApiResult> markChatSeen({required String email, bool showOfflineAlert = true}) {
    return _post('/chat/seen', {'email': email}, showOfflineAlert: showOfflineAlert);
  }

  Future<ApiResult> _get(String path, Map<String, String> query, {bool showOfflineAlert = true}) async {
    if (!await _ensureOnline(showDialog: showOfflineAlert)) return _offlineResult;

    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the server. Please check your internet and try again.',
      );
    }
  }

  Future<ApiResult> _post(String path, Map<String, String> payload, {bool showOfflineAlert = true}) async {
    if (!await _ensureOnline(showDialog: showOfflineAlert)) return _offlineResult;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the server. Please check your internet and try again.',
      );
    }
  }

  Future<ApiResult> _put(String path, Map<String, String> payload, {bool showOfflineAlert = true}) async {
    if (!await _ensureOnline(showDialog: showOfflineAlert)) return _offlineResult;

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the server. Please check your internet and try again.',
      );
    }
  }

  Future<ApiResult> _delete(String path, Map<String, String> payload, {bool showOfflineAlert = true}) async {
    if (!await _ensureOnline(showDialog: showOfflineAlert)) return _offlineResult;

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the server. Please check your internet and try again.',
      );
    }
  }

  Future<ApiResult> _multipart(
    String path,
    Map<String, String> payload, {
    required String fileField,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (!await _ensureOnline()) return _offlineResult;

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(payload);
      request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 25),
      );
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return const ApiResult(
        ok: false,
        message: 'Could not connect to the server. Please check your internet and try again.',
      );
    }
  }

  Future<bool> _ensureOnline({bool showDialog = true}) {
    return InternetGuard.ensureOnline(showDialog: showDialog);
  }

  static const _offlineResult = ApiResult(
    ok: false,
    message: 'No internet connection. Please check your connection and try again.',
  );

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
