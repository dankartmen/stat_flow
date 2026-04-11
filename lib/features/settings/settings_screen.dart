import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';

/// {@template settings_screen}
/// Экран настроек приложения.
///
/// Позволяет пользователю изменить тему оформления (светлая, тёмная, системная).
/// Настройки сохраняются через [SharedPreferences] и применяются глобально.
/// {@endtemplate}
class SettingsScreen extends ConsumerWidget {
  /// {@macro settings_screen}
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Тема оформления',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_themeModeLabel(mode)),
              value: mode,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                }
              },
            );
          }),
          const Divider(),
        ],
      ),
    );
  }

  /// Возвращает локализованное название режима темы.
  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Тёмная';
      case AppThemeMode.system:
        return 'Как в системе';
    }
  }
}