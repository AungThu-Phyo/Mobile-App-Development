import 'package:flutter/material.dart';

abstract class AppColors {
  static bool _isDarkMode = false;

  static bool get isDarkMode => _isDarkMode;

  static void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // Light palette
  static const Color lightPrimaryBlue = Color(0xFF0A7EA4);
  static const Color lightPrimaryBlueDark = Color(0xFF085C78);
  static const Color lightPrimaryBlueLight = Color(0xFFDDF3FB);
  static const Color lightBackground = Color(0xFFF7F7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFEFFFD);
  static const Color lightSuccessGreen = Color(0xFF2E9B5F);
  static const Color lightSuccessGreenLight = Color(0xFFE6F6EC);
  static const Color lightWarningOrange = Color(0xFFE07A2D);
  static const Color lightWarningOrangeLight = Color(0xFFFFF1E5);
  static const Color lightErrorRed = Color(0xFFD64545);
  static const Color lightErrorRedSoft = Color(0xFFFFEBEE);
  static const Color lightGrey100 = Color(0xFFF2F3EE);
  static const Color lightGrey200 = Color(0xFFE5E7DE);
  static const Color lightGrey400 = Color(0xFFB2B7AA);
  static const Color lightGrey600 = Color(0xFF5F665C);
  static const Color lightGrey700 = Color(0xFF3E463D);
  static const Color lightTagSilentBackground = Color(0xFFE4F5FB);
  static const Color lightTagSilentText = Color(0xFF0A7EA4);
  static const Color lightTagSocialBackground = Color(0xFFEAF8EE);
  static const Color lightTagSocialText = Color(0xFF2E9B5F);
  static const Color lightTagColabBackground = Color(0xFFFFF2E8);
  static const Color lightTagColabText = Color(0xFFB76024);
  static const Color lightTextPrimary = Color(0xFF172018);
  static const Color lightTextSecondary = Color(0xFF596158);
  static const Color lightTextHint = Color(0xFF9EA59A);

  // Dark palette
  static const Color darkPrimaryBlue = Color(0xFF67C7E6);
  static const Color darkPrimaryBlueDark = Color(0xFFB5EEFF);
  static const Color darkPrimaryBlueLight = Color(0xFF143744);
  static const Color darkBackground = Color(0xFF0D1417);
  static const Color darkSurface = Color(0xFF121B1F);
  static const Color darkCardBackground = Color(0xFF162227);
  static const Color darkSuccessGreen = Color(0xFF61D096);
  static const Color darkSuccessGreenLight = Color(0xFF153124);
  static const Color darkWarningOrange = Color(0xFFF3A456);
  static const Color darkWarningOrangeLight = Color(0xFF392717);
  static const Color darkErrorRed = Color(0xFFFF8686);
  static const Color darkErrorRedSoft = Color(0xFF3B1F24);
  static const Color darkGrey100 = Color(0xFF1A2529);
  static const Color darkGrey200 = Color(0xFF273338);
  static const Color darkGrey400 = Color(0xFF6E7C81);
  static const Color darkGrey600 = Color(0xFFA5B1B5);
  static const Color darkGrey700 = Color(0xFFD9E0E3);
  static const Color darkTagSilentBackground = Color(0xFF12313C);
  static const Color darkTagSilentText = Color(0xFF8DDEF7);
  static const Color darkTagSocialBackground = Color(0xFF143022);
  static const Color darkTagSocialText = Color(0xFF86E0AE);
  static const Color darkTagColabBackground = Color(0xFF3A2816);
  static const Color darkTagColabText = Color(0xFFFFC58F);
  static const Color darkTextPrimary = Color(0xFFF1F6F7);
  static const Color darkTextSecondary = Color(0xFFA7B4B8);
  static const Color darkTextHint = Color(0xFF75848A);

  static Color get primaryBlue =>
      _isDarkMode ? darkPrimaryBlue : lightPrimaryBlue;
  static Color get primaryBlueDark =>
      _isDarkMode ? darkPrimaryBlueDark : lightPrimaryBlueDark;
  static Color get primaryBlueLight =>
      _isDarkMode ? darkPrimaryBlueLight : lightPrimaryBlueLight;
  static Color get background => _isDarkMode ? darkBackground : lightBackground;
  static Color get surface => _isDarkMode ? darkSurface : lightSurface;
  static Color get cardBackground =>
      _isDarkMode ? darkCardBackground : lightCardBackground;
  static Color get successGreen =>
      _isDarkMode ? darkSuccessGreen : lightSuccessGreen;
  static Color get successGreenLight =>
      _isDarkMode ? darkSuccessGreenLight : lightSuccessGreenLight;
  static Color get warningOrange =>
      _isDarkMode ? darkWarningOrange : lightWarningOrange;
  static Color get warningOrangeLight =>
      _isDarkMode ? darkWarningOrangeLight : lightWarningOrangeLight;
  static Color get errorRed => _isDarkMode ? darkErrorRed : lightErrorRed;
  static Color get errorRedSoft =>
      _isDarkMode ? darkErrorRedSoft : lightErrorRedSoft;
  static Color get grey100 => _isDarkMode ? darkGrey100 : lightGrey100;
  static Color get grey200 => _isDarkMode ? darkGrey200 : lightGrey200;
  static Color get grey400 => _isDarkMode ? darkGrey400 : lightGrey400;
  static Color get grey600 => _isDarkMode ? darkGrey600 : lightGrey600;
  static Color get grey700 => _isDarkMode ? darkGrey700 : lightGrey700;
  static Color get tagSilentBackground =>
      _isDarkMode ? darkTagSilentBackground : lightTagSilentBackground;
  static Color get tagSilentText =>
      _isDarkMode ? darkTagSilentText : lightTagSilentText;
  static Color get tagSocialBackground =>
      _isDarkMode ? darkTagSocialBackground : lightTagSocialBackground;
  static Color get tagSocialText =>
      _isDarkMode ? darkTagSocialText : lightTagSocialText;
  static Color get tagColabBackground =>
      _isDarkMode ? darkTagColabBackground : lightTagColabBackground;
  static Color get tagColabText =>
      _isDarkMode ? darkTagColabText : lightTagColabText;
  static Color get textPrimary =>
      _isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => _isDarkMode ? darkTextHint : lightTextHint;

  static List<Color> get authBackgroundGradient => _isDarkMode
      ? const [Color(0xFF081216), Color(0xFF0E1E24), Color(0xFF1A1610)]
      : const [Color(0xFFEAF8FF), Color(0xFFF7F7F2), Color(0xFFFFF9F0)];

  static List<Color> get heroGradientCoolToWarm => _isDarkMode
      ? const [Color(0xFF12262E), Color(0xFF241D15)]
      : const [Color(0xFFE3F7FF), Color(0xFFFFF4E8)];

  static List<Color> get heroGradientWarmToCool => _isDarkMode
      ? const [Color(0xFF241D15), Color(0xFF12262E)]
      : const [Color(0xFFFFF4E8), Color(0xFFEAF8FF)];

  static Color get heroPanel => _isDarkMode
      ? darkCardBackground.withValues(alpha: 0.92)
      : lightSurface.withValues(alpha: 0.84);

  static Color get heroPanelStrong => _isDarkMode
      ? darkSurface.withValues(alpha: 0.96)
      : lightSurface.withValues(alpha: 0.9);

  static Color get heroIconSurface => _isDarkMode
      ? darkSurface.withValues(alpha: 0.96)
      : lightSurface.withValues(alpha: 0.88);

  static Color get heroBadgeSurface => _isDarkMode
      ? darkSurface.withValues(alpha: 0.72)
      : lightSurface.withValues(alpha: 0.22);

  // Unread notification card background — deep tinted blue
  static Color get notifUnreadBg =>
      _isDarkMode ? const Color(0xFF0A2233) : const Color(0xFFECF6FD);
}
