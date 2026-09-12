import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focus_app/core/services/settings_service.dart';
import 'package:focus_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  testWidgets('App launches and renders Onboarding screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final settings = await SettingsService.init();

    await tester.pumpWidget(FocusFlowApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Train Your\nConcentration.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('App renders Dashboard when onboarding completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final settings = await SettingsService.init();

    await tester.pumpWidget(FocusFlowApp(settings: settings));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
