import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Режимы темы оформления.
enum AppThemeMode { light, dark, system }

/// {@template theme_notifier}
/// Управляет состоянием темы оформления.
///
/// Хранит выбранный режим ([AppThemeMode]) и синхронизирует его с
/// [SharedPreferences] для сохранения между запусками приложения.
/// {@endtemplate}
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  /// Ключ для сохранения в SharedPreferences.
  static const String _prefsKey = 'app_theme_mode';

  /// {@macro theme_notifier}
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadFromPrefs();
  }

  /// Загружает сохранённый режим темы из SharedPreferences.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved != null) {
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
      state = mode;
    }
  }

  /// Устанавливает новый режим темы и сохраняет его.
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

/// Провайдер для доступа к текущему режиму темы.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Провайдер для получения готовой [ThemeData] с учётом системных настроек.
///
/// Возвращает светлую или тёмную тему в зависимости от выбранного режима.
/// Для режима `system` учитывается яркость платформы.
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  final platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case AppThemeMode.light:
      return AppTheme.light();
    case AppThemeMode.dark:
      return AppTheme.dark();
    case AppThemeMode.system:
      return platformBrightness == Brightness.dark
          ? AppTheme.dark()
          : AppTheme.light();
  }
});