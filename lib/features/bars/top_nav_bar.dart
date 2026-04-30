import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/dataset/dataset.dart';
import '../../core/providers/providers.dart';
import '../../core/services/image_api_service.dart';
import '../screens/welcome_dialog.dart';
import '../table/widget/table_preview_screen.dart';

/// {@template top_nav_bar}
/// Верхняя навигационная панель приложения.
///
/// Содержит:
/// - Логотип приложения.
/// - Подзаголовок с информацией о текущем датасете.
/// - Кнопку смены лабораторной работы.
/// - Кнопку загрузки CSV (только для табличной лабораторной).
/// - Кнопки переключения между режимами "Графики" и "Данные" (только для табличной лабораторной).
///
/// Использует Riverpod для отслеживания состояния загрузки датасета.
/// {@endtemplate}
class TopNavBar extends ConsumerWidget {
  /// Текущий активный экран (канвас или таблица данных).
  final ScreenType? currentScreen;

  /// Колбэк для изменения активного экрана.
  final ValueChanged<ScreenType>? onScreenChanged;

  /// {@macro top_nav_bar}
  const TopNavBar({
    super.key,
    this.currentScreen,
    this.onScreenChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLab = ref.watch(activeLabProvider);
    final tabularDataset = ref.watch(tabularDatasetProvider);
    final imageInfo = ref.watch(imageDatasetInfoProvider);

    // Формируем подзаголовок в зависимости от активной лабораторной
    String subtitle = '';
    if (activeLab == LabType.tabular && tabularDataset != null) {
      subtitle = 'Таблица: ${tabularDataset.name} (${tabularDataset.rowCount} строк)';
    } else if (activeLab == LabType.image && imageInfo != null) {
      subtitle = 'Изображения: ${imageInfo.name} (${imageInfo.totalImages} шт.)';
    } else if (activeLab == LabType.tabular) {
      // Для табличной лабораторной, но датасет ещё не загружен
      subtitle = 'Датасет не выбран';
    } else {
      subtitle = 'Лабораторная не выбрана';
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text('Stat Flow', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 24),
          if (activeLab == LabType.tabular) ...[
            // Кнопки переключения между канвасом и таблицей отображаются только если датасет загружен
            if (tabularDataset != null) ...[
              _ScreenToggleButton(
                label: 'Графики',
                icon: Icons.dashboard,
                isActive: currentScreen == ScreenType.canvas,
                onTap: () => onScreenChanged!(ScreenType.canvas),
              ),
              const SizedBox(width: 8),
              _ScreenToggleButton(
                label: 'Данные',
                icon: Icons.table_chart,
                isActive: currentScreen == ScreenType.data,
                onTap: () => onScreenChanged!(ScreenType.data),
              ),
              const Spacer(),
            ],
            // Кнопка загрузки CSV (активна всегда для табличной лабы)
            IconButton(
              tooltip: 'Загрузить CSV',
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TablePreviewScreen()),
                );
                if (result != null && result is Dataset) {
                  ref.read(tabularDatasetProvider.notifier).state = result;
                }
              },
            ),
          ],
          if (activeLab == LabType.image) ...[
            // Для лаборатории изображений отображаем название датасета (если загружен)
            Expanded(
              child: Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Кнопка смены лабораторной – всегда доступна
          IconButton(
            tooltip: 'Сменить лабораторную',
            icon: const Icon(Icons.switch_account),
            onPressed: () async {
              final newLab = await WelcomeDialog.show(context);
              if (newLab != null) {
                ref.read(activeLabProvider.notifier).state = newLab;
                // При переключении на изображения пробуем загрузить сохранённый датасет
                if (newLab == LabType.image) {
                  await _loadSavedImageDataset(ref);
                }
                // При переключении на табличную лабораторную данные остаются как есть (очистка не требуется)
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Загружает сохранённый ранее идентификатор датасета изображений из SharedPreferences
/// и запрашивает его информацию с сервера.
///
/// Принимает:
/// - [ref] – объект [WidgetRef] для обновления провайдеров.
///
/// При успехе обновляет провайдеры [imageDatasetInfoProvider] и [imageDatasetIdProvider].
/// При ошибке (датасет удалён на сервере) очищает сохранённый ID и провайдеры.
///
/// Используется при переключении на лабораторную с изображениями.
Future<void> _loadSavedImageDataset(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('image_dataset_id');
  if (savedId == null) return;

  try {
    final api = ImageApiService();
    final info = await api.getDatasetInfo(savedId);
    ref.read(imageDatasetInfoProvider.notifier).state = info;
    ref.read(imageDatasetIdProvider.notifier).state = savedId;
  } catch (e) {
    // Если сохранённый ID больше не валиден (датасет удалён на сервере) – очищаем хранилище
    debugPrint('Ошибка загрузки сохранённого датасета: $e');
    await prefs.remove('image_dataset_id');
    ref.read(imageDatasetInfoProvider.notifier).state = null;
    ref.read(imageDatasetIdProvider.notifier).state = null;
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