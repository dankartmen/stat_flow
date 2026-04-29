import 'package:flutter/material.dart';

import '../../core/services/image_api_service.dart';

/// {@template dataset_info_card}
/// Карточка с информацией о датасете для классификации изображений.
/// Отображает название датасета, общее количество изображений
/// и количество изображений каждого класса (птицы и дроны).
/// {@endtemplate}
class DatasetInfoCard extends StatelessWidget {
  /// Информация о датасете, полученная от API.
  final DatasetInfo info;

  /// {@macro dataset_info_card}
  const DatasetInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Датасет: ${info.name}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Всего изображений: ${info.totalImages}'),
            const SizedBox(height: 4),
            // Динамически отображаем количество для каждого класса
            ...['bird', 'drone'].map((cls) =>
                Text('  $cls: ${info.classCounts[cls] ?? 0} шт.')),
          ],
        ),
      ),
    );
  }
}