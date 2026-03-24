import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';
import '../chart_state.dart';
import 'calculator/heatmap_data_builder.dart';
import 'model/heatmap_state.dart';
import 'widgets/heatmap_controls.dart';
import 'widgets/heatmap_view.dart';

class HeatmapPlugin extends ChartPlugin {
  @override
  ChartType get type => ChartType.heatmap;

  @override
  ChartState createState() => HeatmapState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as HeatmapState;
    final heatmapData = HeatmapDataBuilder(data.dataset, state).build();
    return HeatmapView(
      dataset: data.dataset, 
      state: state
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as HeatmapState;

    return HeatmapControls.build(
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
      dataset: data.dataset,
    );
  }
}