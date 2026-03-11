import 'package:flutter/material.dart';

/// {@template welcome_dialog}
/// Приветственный диалог, отображаемый при первом запуске приложения
/// 
/// Предлагает пользователю:
/// - Загрузить датасет для начала работы
/// - Пропустить загрузку и начать с пустым рабочим пространством
/// 
/// Диалог имеет привлекательный дизайн с логотипом и кратким описанием приложения.
/// {@endtemplate}
class WelcomeDialog extends StatelessWidget {
  /// Callback при нажатии "Пропустить"
  final VoidCallback onStart;

  /// Callback при нажатии "Загрузить датасет"
  final VoidCallback onLoadDataset;

  /// {@macro welcome_dialog}
  const WelcomeDialog({
    super.key,
    required this.onStart,
    required this.onLoadDataset,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Логотип приложения
            const Icon(
              Icons.analytics,
              size: 64,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Название приложения
            const Text(
              'Stat Flow',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Описание приложения
            const Text(
              'Визуализация и анализ данных',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // Приглашение к действию
            const Text(
              'Загрузите CSV файл для начала работы',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Кнопка загрузки датасета
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onLoadDataset();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Загрузить датасет'),
            ),

            // Кнопка пропуска
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onStart();
              },
              child: const Text('Пропустить'),
            ),
          ],
        ),
      ),
    );
  }
}