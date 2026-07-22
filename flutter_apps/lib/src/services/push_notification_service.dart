import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_navigator.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _api = AuthApi();
  bool _initialized = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _requestPermission();
      await _configureForegroundBehavior();
      await registerSavedUserToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await _registerToken(token);
      });

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.mediumImpact();
          _showForegroundNotice(
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
          );
        }
      });
    } catch (error) {
      debugPrint('Firebase notification setup skipped: $error');
    }
  }

  Future<void> registerSavedUserToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _registerToken(token);
    } catch (error) {
      debugPrint('Could not register notification token: $error');
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _api.removeNotificationToken(token: token);
    } catch (error) {
      debugPrint('Could not remove notification token: $error');
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

  Future<void> _registerToken(String token) async {
    final session = await const SessionStore().load();
    final email = session.userEmail.trim();
    if (email.isEmpty) return;

    await _api.registerNotificationToken(
      email: email,
      token: token,
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
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'Unknown Device';
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
          backgroundColor: Colors.white,
          elevation: 8,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.financeLine),
          ),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.financePrimary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.financePrimary,
                ),
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
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (body.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.financeMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
}
