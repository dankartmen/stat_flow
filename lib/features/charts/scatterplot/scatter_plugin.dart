import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
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
/// {@endtemplate}
class ScatterPlugin extends ChartPlugin {
  const ScatterPlugin();

  @override
  ChartType get type => ChartType.scatter;

  @override
  ChartState createState() => ScatterState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as ScatterState;
    return ScatterView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as ScatterState;

    return ScatterControls.build(
      dataset: data.dataset,
      state: state,
      context: ref.context,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}