import 'package:flutter/material.dart';

/// {@template fl_line}
/// Конфигурация линии для обводки ячеек тепловой карты.
/// 
/// Позволяет задать цвет, толщину и пунктирный стиль линии.
/// Используется в [HeatmapConfig.getCellBorder] для кастомизации обводки ячеек.
/// {@endtemplate}
class FlLine {
  /// Цвет линии. По умолчанию [Colors.black].
  final Color color;
  
  /// Толщина линии в пикселях. По умолчанию 1.0.
  final double strokeWidth;
  
  /// Массив для создания пунктирной линии.
  /// 
  /// Формат: [длина_штриха, длина_промежутка, длина_штриха, ...].
  /// Пример: [5, 5] — штрих 5px, промежуток 5px.
  /// Если null, линия рисуется сплошной.
  final List<double>? dashArray;

  /// {@macro fl_line}
  const FlLine({
    this.color = Colors.black, 
    this.strokeWidth = 1.0, 
    this.dashArray,
  });
}