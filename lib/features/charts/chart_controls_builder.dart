import 'package:flutter/material.dart';
import 'chart_registry.dart';
import 'floating_chart/floating_chart_data.dart';

/// {@template chart_controls_builder}
/// Строитель панели управления для графиков
/// 
/// Использует систему плагинов ([ChartRegistry]) для получения
/// специфичных для конкретного типа графика элементов управления.
/// 
/// Позволяет динамически создавать панель управления на основе
/// типа выбранного графика без жесткой привязки к конкретным реализациям.
/// {@endtemplate}
class ChartControlsBuilder {
  /// Строит список виджетов управления для указанного графика
  /// 
  /// Принимает:
  /// - [chart] — данные плавающего графика
  /// - [refresh] — callback для обновления UI после изменения состояния
  /// 
  /// Возвращает:
  /// - [List<Widget>] — список виджетов для размещения в панели управления
  /// 
  /// Особенности:
  /// - Автоматически определяет тип графика и получает соответствующий плагин
  /// - Делегирует создание управления плагину через метод [ChartPlugin.buildControls]
  /// - Позволяет добавлять новые типы графиков без изменения этого класса
  static List<Widget> build(
      FloatingChartData chart,
      VoidCallback refresh
  ) {
    final plugin = ChartRegistry.get(chart.type);
    return plugin.buildControls(chart, refresh);
  }
}