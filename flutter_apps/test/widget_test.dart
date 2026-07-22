import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_apps/src/features/auth/login_page.dart';

void main() {
  testWidgets('shows modern login screen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));

    expect(find.text('Iqbal App'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
  });

  testWidgets('navigates to register and forgot screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Recover Access'), findsOneWidget);
  });
}
