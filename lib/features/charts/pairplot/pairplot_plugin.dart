import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';
import 'pairplot_controls.dart';
import 'pairplot_state.dart';
import 'pairplot_view.dart';

/// {@template pairplot_plugin}
/// Плагин для Pair Plot (матрицы рассеяния) в системе плагинов графиков.
///
/// Реализует [ChartPlugin] для типа "Pair Plot".
/// Предоставляет:
/// - Создание начального состояния [PairPlotState]
/// - Виджет отображения [PairPlotView]
/// - Панель управления [PairPlotControls]
/// {@endtemplate}
class PairPlotPlugin extends ChartPlugin {
  /// {@macro pairplot_plugin}
  const PairPlotPlugin();

  @override
  ChartType get type => ChartType.pairplotchart;

  @override
  ChartState createState() => PairPlotState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as PairPlotState;
    return PairPlotView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as PairPlotState;

    return PairPlotControls.build(
      context: ref.context,
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}