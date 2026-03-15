import 'package:flutter/material.dart';
import 'chart_registry.dart';
import 'floating_chart/floating_chart_data.dart';

/// {@template chart_renderer}
/// Рендерер для построения виджетов графиков
/// 
/// Использует систему плагинов ([ChartRegistry]) для получения
/// специфичного для конкретного типа графика виджета.
/// 
/// Позволяет динамически создавать графики на основе типа
/// без жесткой привязки к конкретным реализациям.
/// {@endtemplate}
class ChartRenderer {
  /// Строит виджет графика для указанных данных
  /// 
  /// Принимает:
  /// - [chart] — данные плавающего графика
  /// 
  /// Возвращает:
  /// - [Widget] — виджет для отображения в плавающем окне
  /// 
  /// Особенности:
  /// - Автоматически определяет тип графика и получает соответствующий плагин
  /// - Делегирует создание виджета плагину через метод [ChartPlugin.buildChart]
  /// - Позволяет добавлять новые типы графиков без изменения этого класса
  static Widget build(FloatingChartData chart) {
    final plugin = ChartRegistry.get(chart.type);
    return plugin.buildChart(chart);
  }
}