import 'package:flutter/material.dart';

/// {@template correlation_color_range}
/// Диапазон цвета для значения корреляции
/// {@endtemplate}
class CorrelationColorRange {
  /// Нижняя граница (включительно)
  final double min;

  /// Верхняя граница (исключительно)
  final double max;

  /// Цвет диапазона
  final Color color;

  /// Подпись для легенды
  final String label;

  /// {@macro correlation_color_range}
  const CorrelationColorRange({
    required this.min,
    required this.max,
    required this.color,
    required this.label,
  });

  /// Проверка попадания значения в диапазон
  bool contains(double value) => value >= min && value < max;
}

/// Глобальная цветовая шкала корреляции
const List<CorrelationColorRange> correlationColorScale = [
  CorrelationColorRange(
    min: -1.0,
    max: -0.8,
    color: Color(0xFF08306B),
    label: 'Очень сильная отрицательная',
  ),
  CorrelationColorRange(
    min: -0.8,
    max: -0.6,
    color: Color(0xFF2171B5),
    label: 'Сильная отрицательная',
  ),
  CorrelationColorRange(
    min: -0.6,
    max: -0.4,
    color: Color(0xFF6BAED6),
    label: 'Средняя отрицательная',
  ),
  CorrelationColorRange(
    min: -0.4,
    max: -0.2,
    color: Color(0xFFBDD7E7),
    label: 'Слабая отрицательная',
  ),
  CorrelationColorRange(
    min: -0.2,
    max: 0.2,
    color: Color(0xFFE0E0E0),
    label: 'Нет корреляции',
  ),
  CorrelationColorRange(
    min: 0.2,
    max: 0.4,
    color: Color(0xFFFCAE91),
    label: 'Слабая положительная',
  ),
  CorrelationColorRange(
    min: 0.4,
    max: 0.6,
    color: Color(0xFFFB6A4A),
    label: 'Средняя положительная',
  ),
  CorrelationColorRange(
    min: 0.6,
    max: 0.8,
    color: Color(0xFFDE2D26),
    label: 'Сильная положительная',
  ),
  CorrelationColorRange(
    min: 0.8,
    max: 1.01,
    color: Color(0xFFA50F15),
    label: 'Очень сильная положительная',
  ),
];
