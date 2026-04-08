import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';
import '../chart_state.dart';
import 'model/heatmap_state.dart';
import 'widgets/heatmap_controls.dart';
import 'widgets/heatmap_view.dart';

/// {@template heatmap_plugin}
/// Плагин для тепловой карты (heatmap)
/// {@endtemplate}
class HeatmapPlugin extends ChartPlugin {
  
  @override
  ChartType get type => ChartType.heatmap;

  /// Создает начальное состояние для тепловой карты
  @override
  ChartState createState() => HeatmapState();

  /// Строит виджет тепловой карты на основе данных
  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as HeatmapState;
    return HeatmapView(
      dataset: data.dataset, 
      state: state
    );
  }

  /// Строит панель управления для тепловой карты
  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as HeatmapState;

    return HeatmapControls.build(
      context: ref.context,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
      dataset: data.dataset,
    );
  }
}