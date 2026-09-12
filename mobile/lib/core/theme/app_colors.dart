import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTranslucent = Color(0xE6FFFFFF); // 90% opacity for glass effect
  static const Color secondarySurface = Color(0xFFF1F5F9);

  // Accents & Brand (iOS Blue & Calm Focus Tones)
  static const Color primary = Color(0xFF007AFF); // Apple Blue
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFFEBF5FF);
  
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Rose
  static const Color errorLight = Color(0xFFFEF2F2);
  
  // Neutral Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Stimulus Colors (High contrast, distinguishable alongside shapes)
  static const Color targetBlue = Color(0xFF2563EB);
  static const Color targetRed = Color(0xFFDC2626);
  static const Color targetGreen = Color(0xFF16A34A);
  static const Color targetYellow = Color(0xFFCA8A04);
  static const Color targetPurple = Color(0xFF9333EA);
  static const Color targetOrange = Color(0xFFEA580C);
}
