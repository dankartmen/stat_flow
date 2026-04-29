import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template welcome_dialog}
/// Диалог выбора лабораторной работы при первом запуске или по кнопке "Сменить лабу".
/// Предлагает пользователю выбрать тип работы: табличные данные (CSV) или классификация изображений.
/// После выбора сохраняет предпочтение в SharedPreferences.
/// {@endtemplate}
class WelcomeDialog extends StatelessWidget {
  /// Колбэк, вызываемый при выборе лабораторной с табличными данными.
  final VoidCallback onSelectTabular;

  /// Колбэк, вызываемый при выборе лабораторной с классификацией изображений.
  final VoidCallback onSelectImage;

  /// {@macro welcome_dialog}
  const WelcomeDialog({
    super.key,
    required this.onSelectTabular,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Stat Flow', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Выберите тип работы', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSelectTabular,
              icon: const Icon(Icons.table_chart),
              label: const Text('Табличные данные (CSV)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSelectImage,
              icon: const Icon(Icons.image),
              label: const Text('Классификация изображений (птицы / БПЛА)'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }

  /// Показывает диалог выбора лабораторной работы.
  ///
  /// Принимает:
  /// - [context] – контекст сборки, необходимый для отображения диалога.
  ///
  /// Возвращает:
  /// - [LabType] – выбранный тип лабораторной работы, или `null`, если диалог был закрыт без выбора.
  ///
  /// После выбора сохраняет тип в SharedPreferences по ключу 'active_lab'.
  static Future<LabType?> show(BuildContext context) async {
    LabType? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WelcomeDialog(
        onSelectTabular: () {
          result = LabType.tabular;
          Navigator.pop(context);
        },
        onSelectImage: () {
          result = LabType.image;
          Navigator.pop(context);
        },
      ),
    );
    // Сохраняем выбор пользователя для последующих запусков
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('active_lab', result!.name);
    }
    return result;
  }
}

/// {@template lab_type}
/// Перечисление доступных типов лабораторных работ в приложении.
/// - [tabular] – работа с табличными данными (CSV, построение графиков).
/// - [image] – классификация изображений (птицы / БПЛА).
/// {@endtemplate}
enum LabType {
  /// Работа с табличными данными (CSV).
  tabular,
  /// Классификация изображений (птицы / БПЛА).
  image,
}