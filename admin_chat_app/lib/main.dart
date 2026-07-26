import 'package:admin_chat_app/src/app.dart';
import 'package:admin_chat_app/src/services/push_notification_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminPushNotificationService.instance.initialize();
  runApp(const AdminChatApp());
}
