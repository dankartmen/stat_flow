import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'insight_generator.dart';

/// {@template insights_panel}
/// Панель для отображения аналитических инсайтов на основе данных.
/// 
/// Генерирует список [Insight] с помощью [InsightGenerator] и отображает их в виде карточек.
/// Каждый инсайт имеет:
/// - Цветовую индикацию в зависимости от значимости (зелёный/оранжевый/серый/нейтральный)
/// - Иконку, соответствующую типу вывода
/// - Текст и, при наличии, p-value
/// 
/// Используется в интерфейсе аналитики после загрузки датасета.
/// 
/// TODO: Добавить возможность фильтрации инсайтов по типу значимости
/// {@endtemplate}
class InsightsPanel extends StatelessWidget {
  /// Датасет для анализа и генерации инсайтов.
  final Dataset dataset;

  /// {@macro insights_panel}
  const InsightsPanel({super.key, required this.dataset});

  @override
  Widget build(BuildContext context) {
    final insights = InsightGenerator.generate(dataset);
    final theme = Theme.of(context);

    if (insights.isEmpty) {
      return const Center(child: Text('Нет данных для анализа'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _colorForType(insight.type, theme),
          child: ListTile(
            leading: _iconForType(insight.type),
            title: Text(
              insight.text,
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: insight.significance != null
                ? Text('p = ${insight.significance!.toStringAsFixed(3)}')
                : null,
          ),
        );
      },
    );
  }

  /// Возвращает цвет фона карточки в зависимости от типа инсайта.
  ///
  /// Принимает:
  /// - [type] — тип значимости.
  /// - [theme] — текущая тема (используется для информационного цвета).
  ///
  /// Возвращает:
  /// - цвет с прозрачностью 0.1 (кроме информационного, который использует цвет темы).
  Color _colorForType(InsightType type, ThemeData theme) {
    switch (type) {
      case InsightType.strong:
        return Colors.green.withValues(alpha: 0.1);
      case InsightType.moderate:
        return Colors.orange.withValues(alpha: 0.1);
      case InsightType.weak:
        return Colors.grey.withValues(alpha: 0.1);
      case InsightType.info:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  /// Возвращает иконку в зависимости от типа инсайта.
  ///
  /// Принимает:
  /// - [type] — тип значимости.
  ///
  /// Возвращает:
  /// - соответствующий [Icon] виджет.
  Widget _iconForType(InsightType type) {
    switch (type) {
      case InsightType.strong:
        return const Icon(Icons.priority_high, color: Colors.green);
      case InsightType.moderate:
        return const Icon(Icons.trending_up, color: Colors.orange);
      case InsightType.weak:
        return const Icon(Icons.info, color: Colors.grey);
      case InsightType.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
    }
  }
}