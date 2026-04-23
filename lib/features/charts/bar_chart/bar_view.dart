import 'package:flutter/material.dart' hide DataColumn;
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/dataset/dataset.dart';
import 'bar_data_calculator.dart';
import 'bar_models.dart';
import 'bar_state.dart';

/// Максимальное количество точек для отображения на графике (используется в калькуляторе).
const int _kMaxChartPoints = 5000;

/// {@template bar_view}
/// Виджет для отображения столбчатой диаграммы.
/// 
/// Использует SyncFusion Charts для построения интерактивной столбчатой диаграммы
/// с поддержкой:
/// - Отображения распределения категориальных данных (частоты)
/// - Группировки числовых данных в интервалы (гистограмма)
/// - Подписей значений на столбцах
/// - Настраиваемой ширины столбцов
/// - Сэмплирования для больших наборов данных
/// 
/// Автоматически определяет тип данных и строит соответствующее представление.
/// {@endtemplate}
class BarView extends StatefulWidget {
  /// Датасет с данными для отображения.
  final Dataset dataset;

  /// Состояние столбчатой диаграммы с настройками.
  final BarState state;

  /// {@macro bar_view}
  const BarView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<BarView> createState() => _BarViewState();
}

/// Состояние виджета [BarView].
/// Отвечает за подготовку данных и построение графика.
class _BarViewState extends State<BarView> {
  /// Данные для отображения в виде списка серий (каждая серия — список категорий со значениями).
  List<BarSeriesData> _seriesData = [];

  /// Флаг, указывающий, что данные были сэмплированы.
  bool _isSampled = false;

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  void didUpdateWidget(covariant BarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем данные только если изменились параметры, влияющие на расчёт
    if (oldWidget.dataset != widget.dataset ||
        oldWidget.state.columnName != widget.state.columnName ||
        oldWidget.state.groupByColumn != widget.state.groupByColumn ||
        oldWidget.state.binCount != widget.state.binCount ||
        oldWidget.state.maxCategories != widget.state.maxCategories ||
        oldWidget.state.sortDescending != widget.state.sortDescending) {
      _updateData();
    }
  }

  /// Обновляет данные на основе выбранной колонки.
  /// 
  /// - Определяет тип колонки и обрабатывает данные соответствующим образом.
  /// - Для числовых данных выполняет группировку в интервалы (гистограмма).
  /// - Для категориальных и текстовых данных считает частоты.
  /// - Выполняет сэмплирование, если количество данных превышает порог.
  void _updateData() {    
    final result = BarDataCalculator.calculate(
      dataset: widget.dataset,
      state: widget.state,
    );

    setState(() {
      _seriesData = result.seriesData;
      _isSampled = result.isSampled;
    });
  }

  /// Очищает данные при отсутствии выбранной колонки.
  void _clearData() {
    setState(() {
      _seriesData = [];
      _isSampled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_seriesData.isEmpty) {
      return const Center(
        child: Text("Нет данных для отображения"),
      );
    }
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SfCartesianChart(
            legend: Legend(isVisible: _seriesData.length > 1),
            plotAreaBorderWidth: 0,
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              tooltipSettings: const InteractiveTooltip(format: 'point.x : point.y'),
            ),
            tooltipBehavior: TooltipBehavior(enable: false, duration: 2500),
            primaryXAxis: CategoryAxis(
              labelRotation: 45,
              labelIntersectAction: AxisLabelIntersectAction.multipleRows,
            ),
            primaryYAxis: const NumericAxis(),
            series: _buildSeries(theme),
          ),
        ),
      ],
    );
  }

  /// Строит список серий для отображения на диаграмме.
  ///
  /// Принимает:
  /// - [theme] — текущая тема для получения цветов
  ///
  /// Возвращает:
  /// - список серий ([BarSeries] или [StackedBarSeries])
  List<CartesianSeries> _buildSeries(ThemeData theme) {
    final List<CartesianSeries> seriesList = [];
    
    // Используем предопределённые цвета для групп
    final colors = Colors.primaries;
    
    for (int i = 0; i < _seriesData.length; i++) {
      final seriesData = _seriesData[i];
      final color = colors[i % colors.length];
      
      // В stacked режиме используем StackedBarSeries
      if (widget.state.groupByColumn != null) {
        seriesList.add(StackedBarSeries<BarData, String>(
          dataSource: seriesData.bars,
          xValueMapper: (data, _) => data.category,
          yValueMapper: (data, _) => data.value,
          name: seriesData.groupName,
          color: color,
          width: widget.state.barWidth,
          spacing: widget.state.spacing,
          borderRadius: BorderRadius.circular(widget.state.borderRadius),
          borderWidth: widget.state.borderWidth,
          borderColor: color,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.state.showValues,
          ),
        ));
      } else {
        // Обычная группированная столбчатая диаграмма
        seriesList.add(BarSeries<BarData, String>(
          dataSource: seriesData.bars,
          xValueMapper: (data, _) => data.category,
          yValueMapper: (data, _) => data.value,
          name: seriesData.groupName,
          color: color,
          width: widget.state.barWidth,
          spacing: widget.state.spacing,
          borderRadius: BorderRadius.circular(widget.state.borderRadius),
          borderWidth: widget.state.borderWidth,
          borderColor: color,
          isTrackVisible: widget.state.showTrack,
          trackColor: theme.colorScheme.surfaceContainerHighest,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.state.showValues,
            alignment: _getBarAlignment(widget.state.alignment),
          ),
        ));
      }
    }
    return seriesList;
  }

  /// Преобразует [BarAlignment] в [ChartAlignment] для SyncFusion.
  ///
  /// Принимает:
  /// - [alignment] — внутреннее перечисление выравнивания
  ///
  /// Возвращает:
  /// - соответствующее значение [ChartAlignment]
  ChartAlignment _getBarAlignment(BarAlignment alignment) {
    switch (alignment) {
      case BarAlignment.far:
        return ChartAlignment.far;
      case BarAlignment.near:
        return ChartAlignment.near;
      case BarAlignment.center:
        return ChartAlignment.center;
    }
  }
}