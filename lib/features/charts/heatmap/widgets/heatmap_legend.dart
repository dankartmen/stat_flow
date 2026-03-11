import 'package:flutter/material.dart';
import '../color/heatmap_color_mapper.dart';

/// {@template heatmap_legend}
/// Компактная градиентная легенда для тепловой карты.
/// 
/// Отображает цветовую шкалу с подписями минимального, среднего
/// и максимального значения. Автоматически генерирует градиент
/// на основе текущего [HeatmapColorMapper].
/// 
/// Особенности:
/// - Плавный градиент от минимального к максимальному значению
/// - Компактный дизайн с рамкой
/// - Автоматическое форматирование подписей
/// {@endtemplate}
class HeatmapLegend extends StatelessWidget {
  /// Маппер цветов для генерации градиента
  final HeatmapColorMapper mapper;

  /// Минимальное значение шкалы
  final double min;

  /// Максимальное значение шкалы
  final double max;

  /// Количество сегментов для построения градиента
  final int segments;

  /// {@macro heatmap_legend}
  const HeatmapLegend({
    super.key,
    required this.mapper,
    required this.min,
    required this.max,
    this.segments = 20,
  });

  @override
  Widget build(BuildContext context) {
    final step = (max - min) / segments;

    final colors = List.generate(
      segments + 1,
      (i) => mapper.map(min + step * i),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Градиентная цветовая шкала
          Container(
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// Подписи значений
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(min),
              _label((min + max) / 2),
              _label(max),
            ],
          ),
        ],
      ),
    );
  }

  /// Создает виджет подписи для значения
  Widget _label(double value) {
    return Text(
      value.toStringAsFixed(1),
      style: const TextStyle(
        fontSize: 11,
        height: 1,
      ),
    );
  }
}