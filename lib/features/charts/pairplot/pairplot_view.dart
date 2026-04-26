import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'pairplot_data_calculator.dart';
import 'pairplot_models.dart';
import 'pairplot_state.dart';

/// {@template pairplot_view}
/// Виджет для отображения Pair Plot (матрицы рассеяния).
/// 
/// Строит сетку графиков, где:
/// - На диагонали: гистограммы распределения (или названия колонок)
/// - Вне диагонали: scatter plots для всех пар колонок
/// 
/// Поддерживает:
/// - Отображение коэффициента корреляции в каждой ячейке
/// - Настройку размера и прозрачности точек
/// - Тултипы с координатами
/// - Клик по ячейке для создания отдельного scatter plot (через onCellTap)
/// {@endtemplate}
class PairPlotView extends StatefulWidget {
  /// Датасет с данными для отображения.
  final Dataset dataset;
  
  /// Состояние Pair Plot с настройками.
  final PairPlotState state;
  
  /// Колбэк при тапе на недиагональную ячейку.
  final void Function(String xCol, String yCol)? onCellTap;

  /// {@macro pairplot_view}
  const PairPlotView({
    super.key,
    required this.dataset,
    required this.state,
    this.onCellTap,
  });

  @override
  State<PairPlotView> createState() => _PairPlotViewState();
}

/// Состояние виджета [PairPlotView].
/// Отвечает за подготовку данных и построение сетки графиков.
class _PairPlotViewState extends State<PairPlotView> {
  /// Данные для отображения.
  PairPlotData? _data;
  
  /// Сообщение об ошибке (если есть).
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant PairPlotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Пересчитываем данные только при изменении выбора колонок или лимита точек,
    // так как остальные параметры (размер, прозрачность) влияют только на отрисовку.
    if (oldWidget.dataset != widget.dataset ||
        oldWidget.state.selectedColumns != widget.state.selectedColumns ||
        oldWidget.state.maxPoints != widget.state.maxPoints) {
      _prepareData();
    }
  }

  /// Подготавливает данные через [PairPlotDataCalculator].
  void _prepareData() {
    final result = PairPlotDataCalculator.calculate(
      dataset: widget.dataset,
      state: widget.state,
    );
    if (result.error != null) {
      setState(() {
        _error = result.error;
        _data = null;
      });
    } else {
      setState(() {
        _data = result.data;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final n = _data!.columnNames.length;
    final enableTooltips = n <= widget.state.maxColumnsForTooltips;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 16) / n;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: List.generate(n, (row) {
                return SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(n, (col) {
                      final cellData = _data!.matrix[row][col];
                      return SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: GestureDetector(
                            onTap: () {
                              if (!cellData.isDiagonal && widget.onCellTap != null) {
                                widget.onCellTap!(cellData.xColumn, cellData.yColumn);
                              }
                            },
                            child: _buildCell(cellData, theme, enableTooltips),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  /// Строит виджет для одной ячейки матрицы.
  ///
  /// Принимает:
  /// - [cellData] — данные ячейки
  /// - [theme] — тема для цветов
  /// - [enableTooltips] — включать ли тултипы
  ///
  /// Возвращает:
  /// - гистограмму для диагонали (если showHistogramOnDiagonal)
  /// - название колонки для диагонали (иначе)
  /// - scatter plot для недиагональных ячеек
  Widget _buildCell(PairPlotCellData cellData, ThemeData theme, bool enableTooltips) {
    if (cellData.isDiagonal && widget.state.showHistogramOnDiagonal) {
      return _buildHistogramCell(cellData, theme, enableTooltips);
    } else if (cellData.isDiagonal) {
      return Center(
        child: Text(
          cellData.xColumn,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    return _buildScatterCell(cellData, theme, enableTooltips);
  }

  /// Строит виджет гистограммы для диагональной ячейки.
  Widget _buildHistogramCell(PairPlotCellData cellData, ThemeData theme, bool enableTooltips) {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(isVisible: false),
      primaryYAxis: NumericAxis(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: enableTooltips),
      series: <HistogramSeries<double, double>>[
        HistogramSeries<double, double>(
          dataSource: cellData.xValues,
          yValueMapper: (v, _) => v,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          borderColor: theme.colorScheme.primary,
          borderWidth: 1,
        ),
      ],
    );
  }

  /// Строит виджет scatter plot для недиагональной ячейки.
  /// В зависимости от наличия и типа hue-колонки выбирает соответствующую реализацию.
  Widget _buildScatterCell(PairPlotCellData cellData, ThemeData theme, bool enableTooltips) {
    // Преобразуем данные для SyncFusion
    final points = <_SPoint>[];
    for (int i = 0; i < cellData.xValues.length; i++) {
      points.add(_SPoint(cellData.xValues[i], cellData.yValues[i]));
    }
    // Если окраска не используется или нет данных – обычный scatter
    final useHue = cellData.hueValues != null && cellData.hueValues!.isNotEmpty;
    if (!useHue) {
      return _buildSimpleScatter(cellData, points, theme, enableTooltips);
    }

    // Определяем палитру и маппер в зависимости от типа hue
    if (cellData.hueIsNumeric) {
      return _buildNumericHueScatter(cellData, points, theme, enableTooltips);
    } else {
      return _buildCategoricalHueScatter(cellData, points, theme, enableTooltips);
    }
  }
  
  /// Scatter plot без окраски (одноточечный цвет).
  Widget _buildSimpleScatter(PairPlotCellData cellData, List<_SPoint> points, ThemeData theme, bool enableTooltips) {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(isVisible: false),
      primaryYAxis: NumericAxis(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: enableTooltips),
      series: <ScatterSeries<_SPoint, double>>[
        ScatterSeries<_SPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: theme.colorScheme.primary.withValues(alpha: widget.state.pointOpacity),
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: widget.state.pointSize,
            height: widget.state.pointSize,
          ),
        ),
      ],
    );
  }

  /// Scatter plot с непрерывной цветовой шкалой (числовая hue-колонка).
  /// Цвет точки линейно интерполируется между синим (min) и красным (max).
  Widget _buildNumericHueScatter(PairPlotCellData cellData, List<_SPoint> points, ThemeData theme, bool enableTooltips) {
    final hueValues = cellData.hueValues!.cast<double>();
    final minHue = hueValues.reduce((a,b) => a < b ? a : b);
    final maxHue = hueValues.reduce((a,b) => a > b ? a : b);
    final range = maxHue - minHue;
    
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(isVisible: false),
      primaryYAxis: NumericAxis(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: enableTooltips),
      series: <ScatterSeries<_SPoint, double>>[
        ScatterSeries<_SPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, index) {
            final hue = hueValues[index];
            final t = range == 0 ? 0.5 : (hue - minHue) / range; // нормализация от 0 до 1
            // Градиент от синего (0) к красному (1)
            return Color.lerp(Colors.blue, Colors.red, t)!;
          },
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: widget.state.pointSize,
            height: widget.state.pointSize,
          ),
        ),
      ],
    );
  }

  /// Scatter plot с дискретной цветовой шкалой (категориальная hue-колонка).
  /// Каждой уникальной категории назначается цвет из фиксированного списка.
  Widget _buildCategoricalHueScatter(PairPlotCellData cellData, List<_SPoint> points, ThemeData theme, bool enableTooltips) {
    final rawHue = cellData.hueValues!.cast<String>();
    final uniqueCategories = rawHue.toSet().toList();
    final colorMap = <String, Color>{};
    // Предопределённая палитра для категорий
    final presetColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.brown, Colors.indigo, Colors.cyan,
    ];
    for (int i = 0; i < uniqueCategories.length; i++) {
      colorMap[uniqueCategories[i]] = presetColors[i % presetColors.length];
    }
    
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(isVisible: false),
      primaryYAxis: NumericAxis(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: enableTooltips),
      series: <ScatterSeries<_SPoint, double>>[
        ScatterSeries<_SPoint, double>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, index) {
            final cat = rawHue[index];
            return colorMap[cat] ?? Colors.grey;
          },
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: widget.state.pointSize,
            height: widget.state.pointSize,
          ),
        ),
      ],
    );
  }

  /// Вычисляет коэффициент корреляции Пирсона между двумя наборами данных.
  ///
  /// Принимает:
  /// - [x] — значения по оси X
  /// - [y] — значения по оси Y
  ///
  /// Возвращает:
  /// - коэффициент корреляции в диапазоне [-1, 1]
  /// - 0, если данные пусты или не совпадают по длине
  double _correlation(List<double> x, List<double> y) {
    if (x.isEmpty || y.isEmpty || x.length != y.length) return 0;
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double cov = 0, varX = 0, varY = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      cov += dx * dy;
      varX += dx * dx;
      varY += dy * dy;
    }

    if (varX == 0 || varY == 0) return 0;
    return cov / (sqrt(varX * varY));
  }

  /// Реализация квадратного корня с защитой от отрицательных значений.
  /// Используется метод Ньютона для вычисления.
  /// Написана вручную, чтобы избежать возможных конфликтов импорта dart:math
  /// и обеспечить безопасность при отрицательном аргументе (возвращает 0).
  double sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }
}

/// Вспомогательный класс для хранения точки (x, y) для SyncFusion.
class _SPoint {
  final double x;
  final double y;
  _SPoint(this.x, this.y);
}