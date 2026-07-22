import 'package:flutter/material.dart';

class AppNavigator {
  const AppNavigator._();

  static final key = GlobalKey<NavigatorState>();

  static BuildContext? get context => key.currentContext;
}
