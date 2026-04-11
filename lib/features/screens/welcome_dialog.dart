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
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Логотип приложения
              Icon(
                Icons.analytics,
                size: 64,
                color: theme.colorScheme.primary,
              ),
          
              const SizedBox(height: 16),
          
              // Название приложения
              Text(
                'Stat Flow',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold
                ),
              ),
          
              const SizedBox(height: 8),
          
              // Описание приложения
              Text(
                'Визуализация и анализ данных',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          
              const SizedBox(height: 24),
          
              // Приглашение к действию
              Text(
                'Загрузите CSV файл для начала работы',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
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
      ),
    );
  }
}