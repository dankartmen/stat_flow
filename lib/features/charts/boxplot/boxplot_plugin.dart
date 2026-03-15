import 'package:flutter/material.dart';

import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';

import 'boxplot_state.dart';
import 'boxplot_view.dart';
import 'boxplot_controls.dart';

/// {@template boxplot_plugin}
/// Плагин для ящика с усами (box plot) в системе плагинов графиков
/// 
/// Реализует [ChartPlugin] для типа "Ящик с усами".
/// Предоставляет:
/// - Создание начального состояния [BoxPlotState]
/// - Построение виджета ящика с усами [BoxPlotView]
/// - Построение панели управления [BoxPlotControls]
/// 
/// Используется для интеграции ящика с усами в общую систему
/// плавающих графиков с единым интерфейсом управления.
/// {@endtemplate}
class BoxPlotPlugin extends ChartPlugin {
  /// {@macro boxplot_plugin}
  const BoxPlotPlugin();

  @override
  ChartType get type => ChartType.boxplot;

  @override
  ChartState createState() {
    return BoxPlotState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as BoxPlotState;

    return BoxPlotView(
      dataset: data.dataset,
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  ) {
    final state = data.state as BoxPlotState;

    return BoxPlotControls.build(
      data.dataset,
      state,
      refresh,
    );
  }
}