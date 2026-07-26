import 'dart:io';

import 'package:admin_chat_app/src/core/app_colors.dart';
import 'package:admin_chat_app/src/services/admin_api.dart';
import 'package:admin_chat_app/src/services/app_navigator.dart';
import 'package:admin_chat_app/src/services/session_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class AdminPushNotificationService {
  AdminPushNotificationService._();

  static final instance = AdminPushNotificationService._();

  static const _nativeNotifications = MethodChannel('city_go_remit_admin_chat/notifications');

  final _api = AdminApi();
  bool _initialized = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(adminFirebaseMessagingBackgroundHandler);
      await _requestPermission();
      await _configureForegroundBehavior();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        final session = await const SessionStore().load();
        if (session.isLoggedIn) {
          await _registerToken(session, token);
        }
      });

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString() ?? 'New message';
        final body = notification?.body ?? message.data['body']?.toString() ?? '';

        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        _showSystemNotification(title: title, body: body);
        _showForegroundNotice(title: title, body: body);
      });
    } catch (_) {
      debugPrint('Admin notification setup skipped.');
    }
  }

  Future<void> registerSessionToken(AdminSession session) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _registerToken(session, token);
    } catch (_) {
      debugPrint('Admin notification token registration skipped.');
    }
  }

  Future<void> unregisterCurrentToken(AdminSession session) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _api.removeNotificationToken(
        adminToken: session.token,
        fcmToken: token,
      );
    } catch (_) {
      debugPrint('Admin notification token removal skipped.');
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _configureForegroundBehavior() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _registerToken(AdminSession session, String token) async {
    await _api.registerNotificationToken(
      adminToken: session.token,
      fcmToken: token,
      platform: _platform,
      deviceName: _deviceName,
    );
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String get _deviceName {
    if (kIsWeb) return 'Admin Web';
    if (Platform.isAndroid) return 'Admin Android Device';
    if (Platform.isIOS) return 'Admin iOS Device';
    return 'Admin Device';
  }

  void _showForegroundNotice({
    required String title,
    required String body,
  }) {
    final context = AppNavigator.context;
    if (context == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_chat_unread_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    if (body.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _showSystemNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await _nativeNotifications.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {
      debugPrint('Admin foreground system notification skipped.');
    }
  }
}
