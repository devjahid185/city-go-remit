import 'package:admin_chat_app/src/core/app_theme.dart';
import 'package:admin_chat_app/src/features/auth/login_page.dart';
import 'package:admin_chat_app/src/features/chat/chat_list_page.dart';
import 'package:admin_chat_app/src/services/app_navigator.dart';
import 'package:admin_chat_app/src/services/push_notification_service.dart';
import 'package:admin_chat_app/src/services/session_store.dart';
import 'package:flutter/material.dart';

class AdminChatApp extends StatelessWidget {
  const AdminChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      title: 'CGR Admin Chat',
      theme: AppTheme.light(),
      home: FutureBuilder<AdminSession>(
        future: const SessionStore().load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final session = snapshot.data;
          if (session != null && session.isLoggedIn) {
            AdminPushNotificationService.instance.registerSessionToken(session);
            return ChatListPage(session: session);
          }
          return const LoginPage();
        },
      ),
    );
  }
}
