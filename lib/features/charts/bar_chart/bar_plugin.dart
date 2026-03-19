import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';

import 'bar_state.dart';
import 'bar_view.dart';
import 'bar_controls.dart';

/// {@template bar_plugin}
/// Плагин для столбчатой диаграммы в системе плагинов графиков
/// {@endtemplate}
class BarPlugin extends ChartPlugin {
  const BarPlugin();

  @override
  ChartType get type => ChartType.barchart;

  @override
  ChartState createState() {
    return BarState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as BarState;

    return BarView(
      dataset: data.dataset,
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref
  ) {
    final state = data.state as BarState;

    return BarControls.build(
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}