import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'histogram_state.dart';

/// {@template histogram_view}
/// Виджет для отображения гистограммы распределения данных
/// 
/// Использует SyncFusion Charts для построения интерактивной гистограммы
/// с поддержкой:
/// - Автоматического расчета интервалов на основе количества корзин
/// - Всплывающих подсказок (tooltips) при нажатии на столбец
/// - Адаптивного отображения под разные размеры
/// 
/// Требует выбранную числовую колонку в [HistogramState].
/// {@endtemplate}
class HistogramView extends StatefulWidget {
  /// Датасет с данными для отображения
  final Dataset dataset;

  /// Состояние гистограммы с настройками
  final HistogramState state;
  const HistogramView({super.key, required this.dataset, required this.state});

  /// {@macro histogram_view}
  @override
  State<HistogramView> createState() => _HistogramViewState();
}

class _HistogramViewState extends State<HistogramView> {
  late List<double> _values;
  late double _min;
  late double _max;
  late double _binInterval;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant HistogramView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.dataset != widget.dataset ||
        oldWidget.state.bins != widget.state.bins ||
        oldWidget.state.binInterval != widget.state.binInterval) {
      _prepareData();
    }
  }

  /// Подготавливает данные для отображения на гистограмме
  /// - Извлекает числовые значения из выбранной колонки
  /// - Вычисляет минимум и максимум для определения диапазона
  /// - Рассчитывает интервал корзин на основе количества корзин или заданного интервала
  /// Приоритет: если задан binInterval – используем его, иначе рассчитываем по bins
  /// Если данных нет, устанавливает разумные значения по умолчанию для предотвращения ошибок отображения
  /// Обеспечивает, что при отсутствии данных гистограмма не будет пытаться отобразить пустой набор, а вместо этого покажет сообщение "Нет данных"
  void _prepareData() {
    final columnName = widget.state.columnName;
    if (columnName == null) {
      _values = [];
      _min = 0;
      _max = 0;
      _binInterval = 1;
      return;
    }

    final column = widget.dataset.numeric(columnName);
    _values = column.data.whereType<double>().toList();

    if (_values.isEmpty) {
      _min = 0;
      _max = 0;
      _binInterval = 1;
      return;
    }

    _min = column.min() ?? _values.first;
    _max = column.max() ?? _values.first;

    // Приоритет: если задан binInterval – используем его, иначе рассчитываем по bins
    if (widget.state.binInterval != null) {
      _binInterval = widget.state.binInterval!;
    } else {
      _binInterval = (_max - _min) / widget.state.bins;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.columnName == null) {
      return const Center(child: Text("Выберите колонку"));
    }
    if (_values.isEmpty) {
      return const Center(child: Text("Нет данных"));
    }

    final theme = Theme.of(context);
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      crosshairBehavior: CrosshairBehavior(enable: true, lineDashArray: const [8, 4]),
      // Настройка всплывающих подсказок
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2500,
        header: widget.state.columnName,
        activationMode: ActivationMode.singleTap,
      ),

      // Настройка осей
      primaryXAxis: NumericAxis(
        labelStyle: const TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(fontSize: 12),
      ),

      // Серия данных - гистограмма
      series: <HistogramSeries<double, double>>[
        HistogramSeries<double, double>(
          dataSource: _values,
          yValueMapper: (v, _) => v,
          binInterval: _binInterval,
          borderWidth: widget.state.borderWidth,
          borderColor: theme.colorScheme.primary,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          showNormalDistributionCurve: widget.state.showNormalDistributionCurve,
          curveColor: theme.colorScheme.secondary,
          curveWidth: 2.0,
          enableTooltip: true,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.state.showDataLabels,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
        ),
      ],
    );
  }
}