import 'package:flutter/material.dart';

/// {@template app_theme}
/// Определяет светлую и тёмную темы приложения.
///
/// Содержит:
/// - Цветовую схему (ColorScheme)
/// - Стили текста (TextTheme)
/// - Стили кнопок, карточек, AppBar и других компонентов Material 3
/// {@endtemplate}
class AppTheme {
  /// Основной синий цвет бренда.
  static const Color primaryBlue = Color(0xFF0052FF);

  /// Цвет при наведении на интерактивные элементы.
  static const Color hoverBlue = Color(0xFF578BFA);

  /// Цвет ссылок.
  static const Color linkBlue = Color(0xFF0667D0);

  /// Почти чёрный цвет (используется для текста на светлой теме).
  static const Color nearBlack = Color(0xFF0A0B0D);

  /// Цвет карточек в тёмной теме.
  static const Color darkCard = Color(0xFF282B31);

  /// Светло-серый цвет фона.
  static const Color coolGray = Color(0xFFEEF0F3);

  /// Приглушённый синий (используется с прозрачностью для границ).
  static const Color mutedBlue = Color(0xFF5B616E);

  /// Возвращает светлую тему.
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: hoverBlue,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: nearBlack,
      surfaceContainerHighest: coolGray,
      outline: mutedBlue.withValues(alpha: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: null,
      textTheme: _buildTextTheme(colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _sansStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(colorScheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(56),
          ),
          side: BorderSide(color: colorScheme.primary),
          foregroundColor: colorScheme.primary,
          textStyle: _sansStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: colorScheme.primary,
            letterSpacing: 0.16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: _sansStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: colorScheme.primary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
    );
  }

  /// Возвращает тёмную тему.
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: hoverBlue,
      onSecondary: Colors.white,
      surface: nearBlack,
      onSurface: Colors.white,
      surfaceContainerHighest: darkCard,
      outline: mutedBlue.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: null,
      textTheme: _buildTextTheme(Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _sansStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(colorScheme).copyWith(
          backgroundColor: WidgetStateProperty.all(darkCard),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(56),
          ),
          side: BorderSide(color: colorScheme.primary),
          foregroundColor: Colors.white,
          textStyle: _sansStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.16,
            height: 1.2,
            color: Colors.white,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: _sansStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: colorScheme.primary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
    );
  }

  //  Вспомогательные методы 

  /// Стиль для основных кнопок (ElevatedButton).
  static ButtonStyle _primaryButtonStyle(ColorScheme scheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: coolGray,
      foregroundColor: nearBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(56),
      ),
      textStyle: _sansStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: nearBlack,
        letterSpacing: 0.16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return hoverBlue.withValues(alpha: 0.1);
        }
        return null;
      }),
    );
  }

  /// Строит TextTheme.
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Hero заголовки
      displayLarge: _displayStyle(
        fontSize: 80,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: textColor,
      ),
      displayMedium: _displayStyle(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: textColor,
      ),
      displaySmall: _displayStyle(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: textColor,
      ),
      // Заголовки секций
      headlineLarge: _sansStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.11,
        color: textColor,
      ),
      headlineMedium: _sansStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.13,
        color: textColor,
      ),
      headlineSmall: _sansStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: textColor,
      ),
      // Основной текст
      bodyLarge: _textStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.56,
        color: textColor,
      ),
      bodyMedium: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodySmall: _sansStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textColor,
      ),
      // Кнопки и навигация
      titleMedium: _sansStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.16,
        color: textColor,
      ),
      titleSmall: _sansStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.23,
        color: textColor,
      ),
      labelLarge: _sansStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.16,
        color: textColor,
      ),
    );
  }

  /// Стиль для крупных заголовков.
  static TextStyle _displayStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: -0.01,
    );
  }

  /// Стиль для шрифта с полужирным начертанием (Sans).
  static TextStyle _sansStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
    double letterSpacing = 0.0,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Стиль для обычного текста.
  static TextStyle _textStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }
}