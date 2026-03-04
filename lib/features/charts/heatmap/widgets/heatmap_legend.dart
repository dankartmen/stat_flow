import 'package:flutter/material.dart';

import '../color/heatmap_color_mapper.dart';

/// {@template heatmap_legend}
/// Компонент легенды для тепловой карты, отображающий соответствие
/// цветов числовым значениям корреляции.
/// {@endtemplate}
class HeatmapLegend extends StatelessWidget {
  /// Маппер цветов для отображения
  final HeatmapColorMapper mapper;
  
  /// Минимальное значение диапазона
  final double min;
  
  /// Максимальное значение диапазона
  final double max;
  
  /// Количество сегментов для разбиения легенды
  final int segments;

  /// {@macro heatmap_legend}
  const HeatmapLegend({
    super.key,
    required this.mapper,
    required this.min,
    required this.max,
    this.segments = 10,
  });

  @override
  Widget build(BuildContext context) {
    final step = (max - min) / segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Диапазоны корреляции",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: List.generate(segments, (i) {
              final value = min + step * i;

              return Expanded(
                child: Column(
                  children: [
                    // Цветовая полоса
                    Container(
                      height: 20,
                      color: mapper.map(value),
                    ),
                    const SizedBox(height: 4),
                    // Подпись значения
                    Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}