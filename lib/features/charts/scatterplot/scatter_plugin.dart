import 'package:flutter/material.dart';

import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';

import 'scatter_state.dart';
import 'scatter_view.dart';
import 'scatter_controls.dart';

/// {@template scatter_plugin}
/// Плагин для диаграммы рассеяния в системе плагинов графиков
/// 
/// Реализует [ChartPlugin] для типа "Scatter plot".
/// Предоставляет:
/// - Создание начального состояния [ScatterState]
/// - Построение виджета диаграммы рассеяния [ScatterView]
/// - Построение панели управления [ScatterControls]
/// 
/// Используется для интеграции scatter plot в общую систему
/// плавающих графиков с единым интерфейсом управления.
/// {@endtemplate}
class ScatterPlugin extends ChartPlugin {
  /// {@macro scatter_plugin}
  const ScatterPlugin();

  @override
  ChartType get type => ChartType.scatter;

  @override
  ChartState createState() {
    return ScatterState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as ScatterState;

    return ScatterView(
      dataset: data.dataset,
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  ) {
    final state = data.state as ScatterState;

    return ScatterControls.build(
      data.dataset,
      state,
      refresh,
    );
  }
}