import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/auth/producer_login_screen.dart';
import 'package:buyer_section/producer_section/auth/producer_signup_screen.dart';

void main() {
  testWidgets('ProducerLoginScreen renders all required fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProducerLoginScreen(),
      ),
    );

    expect(find.text('Producer Login'), findsOneWidget);
    expect(find.text('I Make & Sell Products'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In as Producer'), findsOneWidget);
    expect(find.text('Create Producer Account'), findsOneWidget);

    // Trigger validation with empty fields
    await tester.tap(find.text('Sign In as Producer'));
    await tester.pump();

    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('ProducerSignupScreen renders all fields and validates inputs',
      (WidgetTester tester) async {
    // Set test surface size so entire form is visible
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ProducerSignupScreen(),
      ),
    );

    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    final submitButton = find.widgetWithText(ElevatedButton, 'Create Producer Account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please create a password'), findsOneWidget);
  });
}
