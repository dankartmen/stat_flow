import 'package:flutter/material.dart';

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
/// Предоставляет:
/// - Создание начального состояния [HistogramState]
/// - Построение виджета гистограммы [HistogramView]
/// - Построение панели управления [HistogramControls]
/// 
/// Используется для интеграции гистограммы в общую систему
/// плавающих графиков с единым интерфейсом управления.
/// {@endtemplate}
class HistogramPlugin extends ChartPlugin {
  /// {@macro histogram_plugin}
  const HistogramPlugin();

  @override
  ChartType get type => ChartType.histogram;

  @override
  ChartState createState() {
    return HistogramState();
  }

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as HistogramState;

    return HistogramView(
      dataset: data.dataset,
      state: state,
    );
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
  ) {
    final state = data.state as HistogramState;

    return HistogramControls.build(
      data.dataset,
      state,
      refresh,
    );
  }
}