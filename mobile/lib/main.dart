import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/storage/app_database.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce iOS portrait orientation (portraitUp only on notched iPhones)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (e) {
    debugPrint('setPreferredOrientations warning: $e');
  }

  // Set system UI overlay style to iOS dark icons on light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SQLite database and user preferences safely
  SettingsService? settings;
  try {
    settings = await SettingsService.init();
  } catch (e) {
    debugPrint('SettingsService.init warning: $e');
  }

  try {
    await AppDatabase.instance;
  } catch (e) {
    debugPrint('AppDatabase init warning: $e');
  }

  runApp(FocusFlowApp(settings: settings));
}

class FocusFlowApp extends StatelessWidget {
  final SettingsService? settings;

  const FocusFlowApp({super.key, this.settings});

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;
    if (settings == null) {
      homeScreen = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (settings!.onboardingCompleted) {
      homeScreen = DashboardScreen(settings: settings!);
    } else {
      homeScreen = OnboardingScreen(settings: settings!);
    }

    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeScreen,
    );
  }
}
