import 'package:flutter/material.dart';

import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';

import 'line_state.dart';
import 'line_view.dart';
import 'line_controls.dart';

/// {@template line_plugin}
/// Плагин для линейного графика в системе плагинов графиков
/// 
/// Реализует [ChartPlugin] для типа "Линейный график".
/// {@endtemplate}
class LinePlugin extends ChartPlugin {
  /// {@macro line_plugin}
  const LinePlugin();

  @override
  ChartType get type => ChartType.linechart;

  @override
  ChartState createState() {
    return LineState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as LineState;

    return LineView(
      dataset: data.dataset,
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  ) {
    final state = data.state as LineState;

    return LineControls.build(
      data.dataset,
      state,
      refresh,
    );
  }
}