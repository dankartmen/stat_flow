import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';

import '../chart_plugin.dart';
import '../floating_chart/floating_chart_data.dart';
import '../chart_state.dart';

import 'model/heatmap_state.dart';
import 'widgets/heatmap_controls.dart';
import 'widgets/heatmap_view.dart';

class HeatmapPlugin extends ChartPlugin {

  @override
  String get type => "Тепловая карта";

  @override
  ChartState createState() {
    return HeatmapState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as HeatmapState;

    return HeatmapView(
      matrix: data.dataset.corr(),
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  ) {
    final state = data.state as HeatmapState;

    return HeatmapControls.build(state, refresh);
  }
}