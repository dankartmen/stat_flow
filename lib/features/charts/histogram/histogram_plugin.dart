import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';
import 'histogram_state.dart';
import 'histogram_view.dart';
import 'histogram_controls.dart';

/// {@template histogram_plugin}
/// Плагин для гистограммы в системе плагинов графиков
///
/// Реализует [ChartPlugin] для типа "Гистограмма".
/// {@endtemplate}
class HistogramPlugin extends ChartPlugin {
  const HistogramPlugin();

  @override
  ChartType get type => ChartType.histogram;

  @override
  ChartState createState() => HistogramState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as HistogramState;
    return HistogramView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as HistogramState;

    return HistogramControls.build(
      context: ref.context,
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}