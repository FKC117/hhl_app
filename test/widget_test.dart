import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hhl_application/app/app.dart';

void main() {
  testWidgets('shows the login form', (tester) async {
    await tester.pumpWidget(const HhlApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });
}
