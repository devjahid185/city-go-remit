import 'package:flutter/material.dart';
import 'package:flutter_apps/src/app.dart';
import 'package:flutter_apps/src/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();
  runApp(const CityGoRemitApp());
}
