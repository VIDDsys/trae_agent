import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette extracted from TRAE APK analysis
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF1E2A4A);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color backgroundSurface = Color(0xFF16213E);
  static const Color backgroundCard = Color(0xFF1E2A4A);
  static const Color backgroundInput = Color(0xFF0F3460);
  static const Color backgroundHover = Color(0xFF233554);
  static const Color backgroundCode = Color(0xFF0D1117);

  // Accent colors
  static const Color accentBlue = Color(0xFF4079FF);
  static const Color accentBlueLight = Color(0xFF6B9BFF);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPurpleLight = Color(0xFFA855F7);

  // Text colors
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textCode = Color(0xFFE6EDF3);

  // Status colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);

  // Border
  static const Color border = Color(0xFF2D3748);
  static const Color borderLight = Color(0xFF374151);
  static const Color divider = Color(0xFF1F2937);

  // Chat specific
  static const Color userBubble = Color(0xFF4079FF);
  static const Color userBubbleText = Colors.white;
  static const Color aiBubble = Color(0xFF1E2A4A);
  static const Color aiBubbleText = Color(0xFFE8E8E8);

  // File tree
  static const Color fileTreeBg = Color(0xFF111827);
  static const Color fileIcon = Color(0xFF6B7280);
  static const Color folderIcon = Color(0xFFFBBF24);
  static const Color fileSelected = Color(0xFF1E3A5F);

  // Terminal
  static const Color terminalBg = Color(0xFF0D1117);
  static const Color terminalText = Color(0xFF00FF00);
  static const Color terminalCursor = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4079FF), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
