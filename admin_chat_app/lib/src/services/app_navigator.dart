import 'package:flutter/material.dart';

class AppNavigator {
  const AppNavigator._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;
}
