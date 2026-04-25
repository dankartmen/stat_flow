import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../settings/settings_screen.dart';
import '../training/model_training_screen.dart';

/// {@template top_nav_bar}
/// Верхняя навигационная панель приложения.
///
/// Содержит:
/// - Логотип приложения.
/// - Переключатели между основными экранами (графики / данные), доступные только после загрузки датасета.
/// - Кнопку загрузки датасета.
/// - Кнопку информации о приложении.
/// - Кнопку настроек.
/// - Кнопку для перехода к обучению нейросети.
/// 
/// Использует Riverpod для отслеживания состояния загрузки датасета.
/// {@endtemplate}
class TopNavBar extends ConsumerWidget {
  /// Колбэк для загрузки датасета.
  final VoidCallback onLoadDataset;

  /// Колбэк для отображения информационного диалога.
  final VoidCallback onShowInfo;

  /// Текущий активный экран (канвас или таблица данных).
  final ScreenType currentScreen;

  /// Колбэк для изменения активного экрана.
  final ValueChanged<ScreenType> onScreenChanged;

  /// {@macro top_nav_bar}
  const TopNavBar({
    super.key,
    required this.onLoadDataset,
    required this.onShowInfo,
    required this.currentScreen,
    required this.onScreenChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDatasetLoaded = ref.watch(datasetProvider) != null;
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Логотип или название приложения
          Text(
            'Stat Flow',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 32),
          // Переключатели экранов (доступны только если датасет загружен)
          if (isDatasetLoaded) ...[
            _ScreenToggleButton(
              label: 'Графики',
              icon: Icons.dashboard,
              isActive: currentScreen == ScreenType.canvas,
              onTap: () => onScreenChanged(ScreenType.canvas),
            ),
            const SizedBox(width: 8),
            _ScreenToggleButton(
              label: 'Данные',
              icon: Icons.table_chart,
              isActive: currentScreen == ScreenType.data,
              onTap: () => onScreenChanged(ScreenType.data),
            ),
          ],
          const Spacer(),
          // Кнопка загрузки датасета
          IconButton(
            tooltip: 'Загрузить датасет',
            icon: const Icon(Icons.upload_file),
            onPressed: onLoadDataset,
          ),
          const SizedBox(width: 8),
          // Кнопка информации о приложении
          IconButton(
            tooltip: 'О приложении',
            icon: const Icon(Icons.info_outline),
            onPressed: onShowInfo,
          ),
          // Кнопка настроек
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          // Кнопка для перехода к обучению нейросети
          IconButton(
            tooltip: 'Обучение нейросети',
            icon: const Icon(Icons.model_training),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelTrainingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// {@template screen_toggle_button}
/// Кнопка-переключатель между экранами в верхней панели.
///
/// Используется для навигации между основными режимами работы:
/// - Режим графиков (канвас)
/// - Режим просмотра данных (таблица)
///
/// Отображается с иконкой и текстом. Активная кнопка имеет цвет темы и фоновую подсветку.
/// {@endtemplate}
class _ScreenToggleButton extends StatelessWidget {
  /// Текст кнопки.
  final String label;

  /// Иконка для кнопки.
  final IconData icon;

  /// Флаг активного состояния (выбран ли этот экран).
  final bool isActive;

  /// Колбэк при нажатии.
  final VoidCallback onTap;

  /// {@macro screen_toggle_button}
  const _ScreenToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        backgroundColor: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
      ),
    );
  }
}