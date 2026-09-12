import 'package:flutter/services.dart';
import 'settings_service.dart';

class HapticsService {
  final SettingsService settings;

  HapticsService(this.settings);

  void lightImpact() {
    if (settings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void mediumImpact() {
    if (settings.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void heavyImpact() {
    if (settings.hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void selection() {
    if (settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void success() {
    if (settings.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void error() {
    if (settings.hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
