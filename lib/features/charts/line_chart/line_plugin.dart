import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
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
  const LinePlugin();

  @override
  ChartType get type => ChartType.linechart;

  @override
  ChartState createState() => LineState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as LineState;
    return LineView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as LineState;

    return LineControls.build(
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}