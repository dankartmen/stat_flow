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
/// - (Другие кнопки могут быть добавлены).
/// 
/// Использует Riverpod для отслеживания состояния загрузки датасета.
/// {@endtemplate}
class TopNavBar extends ConsumerWidget {
  /// {@macro top_nav_bar}
  const TopNavBar({super.key});

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
    } else {
      subtitle = 'Лабораторная не выбрана';
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text('Stat Flow', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 24),
          Expanded(child: Text(subtitle, overflow: TextOverflow.ellipsis)),
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
                // Для табличной лабораторной данные остаются как есть (очистка не требуется)
              }
            },
          ),
          if (activeLab == LabType.tabular)
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
      ),
    );
  }
}

/// Загружает сохранённый ранее идентификатор датасета изображений из SharedPreferences
/// и запрашивает его информацию с сервера.
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
    // Если сохранённый ID больше не валиден (датасет удалён на сервере) – очищаем
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