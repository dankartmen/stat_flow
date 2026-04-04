import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
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
/// {@endtemplate}
class BoxPlotPlugin extends ChartPlugin {
  const BoxPlotPlugin();

  @override
  ChartType get type => ChartType.boxplot;

  @override
  ChartState createState() => BoxPlotState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as BoxPlotState;
    return BoxPlotView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as BoxPlotState;

    return BoxPlotControls.build(
      context: ref.context,
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}