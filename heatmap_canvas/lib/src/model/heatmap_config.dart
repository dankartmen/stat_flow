import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../controller/heatmap_legend_controller.dart';
import '../model/legend_tooltip_info.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import 'fl_line.dart';
import 'touch_data.dart';

/// Режим нормализации данных тепловой карты.
/// 
/// Определяет способ приведения значений к единому масштабу:
/// - [none] — без изменений
/// - [row] — сумма значений в строке = 1
/// - [column] — сумма значений в столбце = 1
/// - [total] — сумма всех значений = 1
enum NormalizeMode { none, row, column, total }

/// Режим сортировки строк или столбцов тепловой карты.
/// 
/// - [none] — без сортировки
/// - [alphabetic] — по алфавиту меток
/// - [byValueAsc] — по возрастанию суммы значений
/// - [byValueDesc] — по убыванию суммы значений
enum SortMode { none, alphabetic, byValueAsc, byValueDesc }

/// Режим агрегации (для справки, может использоваться при подготовке данных)
enum AggregationType { count, sum, avg, min, max, median }

/// Режим отображения значений в процентах.
/// 
/// - [none] — без преобразования
/// - [row] — процент от суммы по строке
/// - [column] — процент от суммы по столбцу
/// - [total] — процент от общей суммы
enum PercentageMode { none, row, column, total }

/// Расположение легенды на тепловой карте.
/// 
/// - [bottom] — внизу под графиком
/// - [topRight] — в правом верхнем углу (поверх графика)
enum LegendPosition { bottom, topRight }


/// {@template heatmap_axis_data}
/// Конфигурация отображения осей тепловой карты.
/// 
/// Управляет подписями строк и столбцов: их видимостью, стилем текста,
/// поворотом и форматированием.
/// {@endtemplate}
class HeatmapAxisData with EquatableMixin {
  /// Показывать ли подписи на осях.
  final bool showLabels;
  
  /// Стиль текста для подписей осей.
  final TextStyle? textStyle;
  
  /// Угол поворота подписей столбцов в радианах.
  /// 
  /// Полезно при длинных названиях столбцов:
  /// - 0 — горизонтально
  /// - π/4 (0.785) — наклонно
  /// - π/2 (1.57) — вертикально
  final double labelRotation;
  
  /// Форматтер для кастомного преобразования текста подписей.
  /// 
  /// Пример: `(label) => label.substring(0, min(10, label.length))`
  final String Function(String label)? labelFormatter;

  const HeatmapAxisData({
    this.showLabels = true,
    this.textStyle,
    this.labelRotation = 0,
    this.labelFormatter,
  });
  
  /// Создаёт копию [HeatmapAxisData] с изменёнными полями.
  HeatmapAxisData copyWith({
    bool? showLabels,
    TextStyle? textStyle,
    double? labelRotation,
    String Function(String label)? labelFormatter,
  }) {
    return HeatmapAxisData(
      showLabels: showLabels ?? this.showLabels,
      textStyle: textStyle ?? this.textStyle,
      labelRotation: labelRotation ?? this.labelRotation,
      labelFormatter: labelFormatter ?? this.labelFormatter,
    );
  }
  
  @override
  List<Object?> get props => [
        showLabels,
        textStyle,
        labelRotation,
        labelFormatter,
      ];
}

/// {@template heatmap_legend_data}
/// Конфигурация отображения легенды (цветовой шкалы) тепловой карты.
/// 
/// Управляет положением, размерами, форматированием меток и кастомными тултипами.
/// {@endtemplate}
class HeatmapLegendData with EquatableMixin {
  /// Расположение легенды: снизу или поверх графика справа сверху.
  final LegendPosition position;
  
  /// Минимальная ширина легенды в пикселях.
  final double? minWidth;
  
  /// Максимальная ширина легенды в пикселях.
  final double? maxWidth;

  /// Билдер кастомного тултипа при наведении на легенду.
  final Widget Function(BuildContext context, LegendTooltipInfo?)? tooltipBuilder;
  
  /// Форматтер для значений на шкале легенды.
  /// 
  /// Пример: `(value) => '${value.toStringAsFixed(2)}°C'`
  final String Function(double value)? labelFormatter;
  
  /// Пользовательские деления на шкале.
  /// 
  /// Если заданы (например, `[0, 0.25, 0.5, 0.75, 1]`),
  /// автоматические деления не генерируются.
  final List<double>? customTicks;
  
  /// Кастомный виджет для отображения метки шкалы вместо текста.
  final Widget Function(double value)? tickBuilder;

  const HeatmapLegendData({
    this.position = LegendPosition.topRight,
    this.minWidth = 140,
    this.maxWidth = 250,
    this.tooltipBuilder,
    this.labelFormatter,
    this.customTicks,
    this.tickBuilder,
  });

  HeatmapLegendData copyWith({
    LegendPosition? position,
    double? minWidth,
    double? maxWidth,
    Widget Function(BuildContext context, LegendTooltipInfo?)? tooltipBuilder,
    String Function(double value)? labelFormatter,
    List<double>? customTicks,
    Widget Function(double value)? tickBuilder,
  }) {
    return HeatmapLegendData(
      position: position ?? this.position,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      tooltipBuilder: tooltipBuilder ?? this.tooltipBuilder,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      customTicks: customTicks ?? this.customTicks,
      tickBuilder: tickBuilder ?? this.tickBuilder,
    );
  }
  
  @override
  List<Object?> get props => [
        position,
        minWidth,
        maxWidth,
        tooltipBuilder,
        labelFormatter,
        customTicks,
        tickBuilder,
      ];
}


/// {@template heatmap_config}
/// Конфигурация отображения тепловой карты (immutable).
/// 
/// Содержит все настройки визуализации: цвета, сортировку, подписи,
/// обработку касаний и кастомные рендеры ячеек.
/// 
/// Является иммутабельным — для изменения настроек используется [copyWith].
/// {@endtemplate}
class HeatmapConfig with EquatableMixin{
  // --- Цвет ---
  /// Предустановленная палитра цветов для тепловой карты.
  final HeatmapPalette palette;
  
  /// Пользовательские цвета для палитры.
  /// 
  /// Если указаны, переопределяют стандартные цвета [palette].
  final List<Color>? customPaletteColors;
  
  /// Режим цветовой шкалы: дискретный (сегментированный) или градиентный.
  final HeatmapColorMode colorMode;
  
  /// Количество сегментов при дискретном режиме [colorMode].
  final int segments;
  
  // --- Сортировка и кластеризация ---
  /// Режим сортировки столбцов (по оси X).
  final SortMode sortX;
  
  /// Режим сортировки строк (по оси Y).
  final SortMode sortY;
  
  /// Включена ли кластеризация (применяется через Transformer).
  final bool clusterEnabled;

  // --- Отображение ---
  /// Показывать ли числовые значения внутри ячеек.
  final bool showValues;
  
  /// Режим отображения только нижней треугольной матрицы.
  /// 
  /// Полезен для корреляционных матриц, где верхняя половина дублирует нижнюю.
  final bool triangleMode;

  // --- Масштаб ---
  /// Минимальный масштаб при зуме.
  final double minScale;
  
  /// Максимальный масштаб при зуме.
  final double maxScale;

  // --- Кастомизация ячеек ---
  /// Переопределяет цвет ячейки.
  /// 
  /// Принимает:
  /// - [cell] — данные ячейки (значение, метки, индексы)
  /// Возвращает:
  /// - Color — если возвращает не null, используется этот цвет
  /// - null — используется стандартный цвет на основе [colorMode]
  final Color? Function(HeatmapCell cell)? getCellColor;

  /// Переопределяет текст внутри ячейки.
  /// 
  /// Принимает:
  /// - [cell] — данные ячейки
  /// Возвращает:
  /// - String — если возвращает не null, отображается этот текст
  /// - null — используется [cellValueFormatter] или стандартное форматирование
  final String? Function(HeatmapCell cell)? getCellLabel;

  /// Фильтр для отображения подписей осей.
  /// 
  /// Принимает:
  /// - [label] — текст подписи
  /// - [axis] — ось (Axis.horizontal или Axis.vertical)
  /// Возвращает:
  /// - true — подпись показывается
  /// - false — подпись скрывается
  final bool Function(String label, Axis axis)? checkToShowAxisLabel;

  /// Кастомная обводка ячейки.
  /// 
  /// Принимает:
  /// - [cell] — данные ячейки
  /// Возвращает:
  /// - FlLine — обводка рисуется с указанными параметрами
  /// - null — обводка не рисуется
  final FlLine? Function(HeatmapCell cell)? getCellBorder;

  /// Форматирование значения в ячейке.
  /// 
  /// Пример: `(value) => value.toStringAsFixed(2)`
  final String Function(double value)? cellValueFormatter;

  /// Форматирование подписи оси.
  /// 
  /// Принимает:
  /// - [label] — исходная подпись
  /// Возвращает:
  /// - отформатированную строку
  final String Function(String label)? axisLabelFormatter;

  /// Билдер кастомного тултипа при наведении на ячейку.
  /// 
  /// Если задан, полностью заменяет стандартный тултип.
  final Widget Function(BuildContext context, HeatmapCell cell)? cellTooltipBuilder;

  /// Билдер кастомного тултипа для легенды.
  final Widget Function(BuildContext context, LegendTooltipInfo?)? legendTooltipBuilder;

  /// Билдер для полной кастомизации виджета легенды.
  /// 
  /// Позволяет полностью заменить встроенную легенду на кастомную.
  final Widget Function(BuildContext context, HeatmapLegendController controller)? legendBuilder;

  /// Полная замена рендеринга ячейки.
  /// 
  /// Если задан, стандартная отрисовка (цвет, текст, обводка) не выполняется.
  /// Вся отрисовка ячейки перекладывается на этот колбэк.
  final void Function(Canvas canvas, Rect rect, HeatmapCell cell)? cellRenderer;
  
  // Группировки настроек
  final HeatmapAxisData axis;
  final HeatmapLegendData legend;
  final HeatmapTouchData touchData;

  const HeatmapConfig({
    this.palette = HeatmapPalette.redBlue,
    this.customPaletteColors,
    this.colorMode = HeatmapColorMode.discrete,
    this.segments = 10,
    this.sortX = SortMode.none,
    this.sortY = SortMode.none,
    this.clusterEnabled = false,
    this.showValues = false,
    this.triangleMode = false,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.cellValueFormatter,
    this.axisLabelFormatter,
    this.cellTooltipBuilder,
    this.legendTooltipBuilder,
    this.cellRenderer,
    this.legendBuilder,
    this.getCellColor,
    this.getCellLabel,
    this.checkToShowAxisLabel,
    this.getCellBorder,
    HeatmapAxisData? axis,
    HeatmapLegendData? legend,
    HeatmapTouchData? touchData,
  }) : axis = axis ?? const HeatmapAxisData(),
       legend = legend ?? const HeatmapLegendData(),
       touchData = touchData ?? const HeatmapTouchData();

  HeatmapConfig copyWith({
    HeatmapPalette? palette,
    final List<Color>? customPaletteColors,
    HeatmapColorMode? colorMode,
    int? segments,
    SortMode? sortX,
    SortMode? sortY,
    bool? clusterEnabled,
    bool? showValues,
    bool? triangleMode,
    double? minScale,
    double? maxScale,
    String Function(double value)? cellValueFormatter,
    Widget Function(BuildContext context, HeatmapCell cell)? cellTooltipBuilder,
    Widget Function(BuildContext context, LegendTooltipInfo? value)? legendTooltipBuilder,
    void Function(Canvas canvas, Rect rect, HeatmapCell cell)? cellRenderer,
    Widget Function(BuildContext context, HeatmapLegendController controller)? legendBuilder,
    Color? Function(HeatmapCell cell)? getCellColor,
    String? Function(HeatmapCell cell)? getCellLabel,
    bool Function(String label, Axis axis)? checkToShowAxisLabel,
    FlLine? Function(HeatmapCell cell)? getCellBorder,
    HeatmapAxisData? axis,
    HeatmapLegendData? legend,
    HeatmapTouchData? touchData,
  }) {
    return HeatmapConfig(
      palette: palette ?? this.palette,
      customPaletteColors: customPaletteColors ?? this.customPaletteColors,
      colorMode: colorMode ?? this.colorMode,
      segments: segments ?? this.segments,
      sortX: sortX ?? this.sortX,
      sortY: sortY ?? this.sortY,
      clusterEnabled: clusterEnabled ?? this.clusterEnabled,
      showValues: showValues ?? this.showValues,
      triangleMode: triangleMode ?? this.triangleMode,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      cellValueFormatter: cellValueFormatter ?? this.cellValueFormatter,
      cellTooltipBuilder: cellTooltipBuilder ?? this.cellTooltipBuilder,
      legendTooltipBuilder: legendTooltipBuilder ?? this.legendTooltipBuilder,
      cellRenderer: cellRenderer ?? this.cellRenderer,
      legendBuilder: legendBuilder ?? this.legendBuilder,
      getCellColor: getCellColor ?? this.getCellColor,
      getCellLabel: getCellLabel ?? this.getCellLabel,
      checkToShowAxisLabel: checkToShowAxisLabel ?? this.checkToShowAxisLabel,
      getCellBorder: getCellBorder ?? this.getCellBorder,
      axis: axis ?? this.axis,
      legend: legend ?? this.legend,
      touchData: touchData ?? this.touchData,
    );
  }
  @override
  List<Object?> get props => [
        palette,
        customPaletteColors,
        colorMode,
        segments,
        sortX,
        sortY,
        clusterEnabled,
        showValues,
        triangleMode,
        minScale,
        maxScale,
        cellValueFormatter,
        axisLabelFormatter,
        cellTooltipBuilder,
        legendTooltipBuilder,
        cellRenderer,
        legendBuilder,
        getCellColor,
        getCellLabel,
        checkToShowAxisLabel,
        getCellBorder,
        axis,
        legend,
        touchData,
      ];
}

/// {@template heatmap_cell}
/// Данные о ячейке тепловой карты для тултипов и кастомного рендеринга.
/// 
/// Содержит значение и метаинформацию о позиции ячейки.
/// {@endtemplate}
class HeatmapCell {
  /// Числовое значение в ячейке.
  final double value;
  
  /// Метка строки.
  final String rowLabel;
  
  /// Метка столбца.
  final String colLabel;
  
  /// Индекс строки (0-based).
  final int rowIndex;
  
  /// Индекс столбца (0-based).
  final int colIndex;

  const HeatmapCell({
    required this.value,
    required this.rowLabel,
    required this.colLabel,
    required this.rowIndex,
    required this.colIndex,
  });
}