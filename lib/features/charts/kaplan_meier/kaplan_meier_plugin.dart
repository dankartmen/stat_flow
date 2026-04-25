import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stat_flow/features/charts/kaplan_meier/kaplan_meier_controls.dart';
import 'package:stat_flow/features/charts/kaplan_meier/kaplan_meier_state.dart';
import '../../../core/providers/providers.dart';
import '../chart_plugin.dart';
import '../chart_state.dart';
import '../chart_type.dart';
import '../floating_chart/floating_chart_data.dart';
import 'kaplan_meier_view.dart';

/// {@template kaplan_meier_plugin}
/// Плагин для кривой выживаемости Каплан-Мейера в системе плагинов графиков.
///
/// Реализует [ChartPlugin] для типа "Kaplan-Meier".
/// Предоставляет:
/// - Создание начального состояния [KaplanMeierState]
/// - Виджет отображения [KaplanMeierView]
/// - Панель управления [KaplanMeierControls]
/// {@endtemplate}
class KaplanMeierPlugin extends ChartPlugin {
  /// {@macro kaplan_meier_plugin}
  const KaplanMeierPlugin();

  @override
  ChartType get type => ChartType.kaplanmeier;

  @override
  ChartState createState() => KaplanMeierState();

  @override
  Widget buildChart(FloatingChartData data) {
    final state = data.state as KaplanMeierState;
    return KaplanMeierView(dataset: data.dataset, state: state);
  }

  @override
  List<Widget> buildControls(
    FloatingChartData data,
    VoidCallback refresh,
    WidgetRef ref,
  ) {
    final state = data.state as KaplanMeierState;

    return KaplanMeierControls.build(
      context: ref.context,
      dataset: data.dataset,
      state: state,
      onChanged: (newState) {
        ref.read(chartsProvider.notifier).updateChartState(data.id, newState);
      },
    );
  }
}