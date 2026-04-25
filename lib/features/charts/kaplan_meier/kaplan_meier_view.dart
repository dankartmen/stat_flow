import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'kaplan_meier_data_calculator.dart';
import 'kaplan_meier_estimator.dart';
import 'kaplan_meier_models.dart';
import 'kaplan_meier_state.dart';

/// {@template kaplan_meier_view}
/// Виджет для отображения кривой выживаемости Каплан-Мейера.
/// 
/// Строит ступенчатый график (step-line) вероятности выживания от времени.
/// Поддерживает:
/// - Одну или несколько кривых (при группировке)
/// - Тултипы с подробной информацией о точке
/// - Настройку толщины линии и отображения цензурированных меток
/// - Автоматическое форматирование осей
/// 
/// Данные подготавливаются через [KaplanMeierDataCalculator].
/// {@endtemplate}
class KaplanMeierView extends StatefulWidget {
  /// Датасет с данными для анализа выживаемости.
  final Dataset dataset;
  
  /// Состояние с настройками отображения.
  final KaplanMeierState state;

  /// {@macro kaplan_meier_view}
  const KaplanMeierView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<KaplanMeierView> createState() => _KaplanMeierViewState();
}

/// Состояние виджета [KaplanMeierView].
/// Управляет подготовкой данных и обновлением графика.
class _KaplanMeierViewState extends State<KaplanMeierView> {
  /// Подготовленные данные для графика.
  KaplanMeierChartData? _data;
  
  /// Сообщение об ошибке (если есть).
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant KaplanMeierView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пересчитываем данные при изменении ключевых параметров
    if (oldWidget.state.timeColumn != widget.state.timeColumn ||
        oldWidget.state.eventColumn != widget.state.eventColumn ||
        oldWidget.state.groupByColumn != widget.state.groupByColumn ||
        oldWidget.dataset != widget.dataset) {
      _prepareData();
    }
  }

  /// Подготавливает данные через [KaplanMeierDataCalculator].
  void _prepareData() {
    final result = KaplanMeierDataCalculator.calculate(
      dataset: widget.dataset,
      state: widget.state,
    );
    setState(() {
      _data = result.data;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Отображение ошибки
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    // Состояние ожидания выбора колонок
    if (_data == null) {
      return const Center(child: Text("Выберите колонки времени и события"));
    }

    final theme = Theme.of(context);
    final colors = Colors.primaries;

    // TODO: Добавить поддержку доверительных интервалов (showConfidenceIntervals)
    // TODO: Добавить маркеры цензурирования (showCensoredMarks)
    return SfCartesianChart(
      legend: Legend(isVisible: _data!.curves.length > 1),
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: NumericAxis(
        title: const AxisTitle(text: 'Время'),
        minimum: 0,
      ),
      primaryYAxis: NumericAxis(
        title: const AxisTitle(text: 'Выживаемость'),
        minimum: 0,
        maximum: 1,
        interval: 0.2,
        numberFormat: NumberFormat('0.00'),
      ),
      series: _data!.curves.asMap().entries.map((entry) {
        final i = entry.key;
        final curve = entry.value;
        final color = colors[i % colors.length];

        return StepLineSeries<KaplanMeierPoint, double>(
          dataSource: curve.points,
          xValueMapper: (point, _) => point.time,
          yValueMapper: (point, _) => point.survival,
          name: curve.groupName,
          color: color,
          width: widget.state.lineWidth,
          // Маркеры не используются (включим позже с showCensoredMarks)
          markerSettings: const MarkerSettings(
            isVisible: false,
          ),
          enableTooltip: true,
        );
      }).toList(),
    );
  }
}