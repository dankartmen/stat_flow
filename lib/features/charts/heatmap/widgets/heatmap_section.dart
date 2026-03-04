import 'package:flutter/material.dart';

import '../model/correlation_matrix.dart';
import 'heatmap_view.dart';

/// {@template heatmap_section}
/// Секция страницы, содержащая тепловую карту корреляции с заголовком
/// и описанием.
/// {@endtemplate}
class HeatmapSection extends StatelessWidget {
  /// Матрица корреляции для отображения
  final CorrelationMatrix matrix;

  /// {@macro heatmap_section}
  const HeatmapSection({
    super.key,
    required this.matrix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Заголовок секции
        const Text(
          "Корреляционная тепловая карта",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Подзаголовок
        const Text(
          "Визуализация корреляций между числовыми параметрами",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 32),

        // Карточка с тепловой картой
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: HeatmapView(matrix: matrix),
          ),
        ),
      ],
    );
  }
}