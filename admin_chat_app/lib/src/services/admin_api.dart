import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_chat_app/src/models/chat_models.dart';
import 'package:admin_chat_app/src/services/api_result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminApi {
  AdminApi({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://cgr.sohojbazar.com/api',
    ),
  });

  final String baseUrl;

  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return _post('/admin/login', {'email': email, 'password': password});
  }

  Future<ApiResult<List<ChatConversation>>> conversations({
    required String token,
    String search = '',
    String status = '',
  }) async {
    final result = await _get('/admin/chats', token: token, query: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
    });

    if (!result.ok) return ApiResult(ok: false, message: result.message);
    final data = result.data?['conversations'] as Map<String, dynamic>? ?? {};
    final list = data['data'] is List ? data['data'] as List : const [];
    return ApiResult(
      ok: true,
      message: result.message,
      data: list
          .map((item) => ChatConversation.fromJson(
                item as Map<String, dynamic>? ?? {},
                baseUrl: baseUrl,
              ))
          .toList(),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> conversation({
    required String token,
    required int id,
  }) {
    return _get('/admin/chats/$id', token: token);
  }

  Future<ApiResult<Map<String, dynamic>>> sendMessage({
    required String token,
    required int id,
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (imageBytes == null || imageName == null) {
      return _post('/admin/chats/$id/messages', {'message': message}, token: token);
    }

    return _multipart(
      '/admin/chats/$id/messages',
      token: token,
      fields: {'message': message},
      fileField: 'image',
      fileName: imageName,
      fileBytes: imageBytes,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> typing({
    required String token,
    required int id,
  }) {
    return _post('/admin/chats/$id/typing', const {}, token: token);
  }

  Future<ApiResult<Map<String, dynamic>>> updateStatus({
    required String token,
    required int id,
    required String status,
  }) {
    return _put('/admin/chats/$id', {'status': status}, token: token);
  }

  Future<ApiResult<Map<String, dynamic>>> toggleChatBan({
    required String token,
    required int id,
    required bool banned,
  }) {
    return _put('/admin/chats/$id', {'chat_banned': banned ? '1' : '0'}, token: token);
  }

  Future<ApiResult<Map<String, dynamic>>> logout({required String token}) {
    return _post('/admin/logout', const {}, token: token);
  }

  Future<ApiResult<Map<String, dynamic>>> registerNotificationToken({
    required String adminToken,
    required String fcmToken,
    required String platform,
    required String deviceName,
  }) {
    return _post('/admin/notification-token', {
      'token': fcmToken,
      'platform': platform,
      'device_name': deviceName,
    }, token: adminToken);
  }

  Future<ApiResult<Map<String, dynamic>>> removeNotificationToken({
    required String adminToken,
    required String fcmToken,
  }) {
    return _delete('/admin/notification-token', {
      'token': fcmToken,
    }, token: adminToken);
  }

  Future<ApiResult<Map<String, dynamic>>> _get(
    String path, {
    String? token,
    Map<String, String> query = const {},
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return _response(response);
    } catch (_) {
      debugPrint('AdminApi GET request failed.');
      return _connectionError();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _post(
    String path,
    Map<String, String> payload, {
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return _response(response);
    } catch (_) {
      debugPrint('AdminApi POST request failed.');
      return _connectionError();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _put(
    String path,
    Map<String, String> payload, {
    required String token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return _response(response);
    } catch (_) {
      debugPrint('AdminApi PUT request failed.');
      return _connectionError();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _delete(
    String path,
    Map<String, String> payload, {
    required String token,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return _response(response);
    } catch (_) {
      debugPrint('AdminApi DELETE request failed.');
      return _connectionError();
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _multipart(
    String path, {
    required String token,
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      request.headers.addAll(_headers(token, json: false));
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
      );
      final streamed = await request.send().timeout(const Duration(seconds: 25));
      return _response(await http.Response.fromStream(streamed));
    } catch (_) {
      debugPrint('AdminApi multipart request failed.');
      return _connectionError();
    }
  }

  Map<String, String> _headers(String? token, {bool json = true}) {
    return {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  ApiResult<Map<String, dynamic>> _response(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        message: _safeMessage(body['message']?.toString(), 'Request completed.'),
        data: body,
      );
    } catch (_) {
      return ApiResult(
        ok: false,
        message: 'Server returned an invalid response.',
        data: {'status': response.statusCode},
      );
    }
  }

  ApiResult<Map<String, dynamic>> _connectionError() {
    return const ApiResult(
      ok: false,
      message: 'Could not connect to the server. Please check your internet and try again.',
    );
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
