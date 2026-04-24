// ignore_for_file: public_member_api_docs, sort_constructors_first
import '../chart_state.dart';

/// {@template histogram_state}
/// Состояние гистограммы для системы плагинов
///
/// Новые параметры:
/// - showNormalDistributionCurve — кривая нормального распределения
/// - binInterval — прямое управление шириной корзины (или null = авто)
/// - borderWidth, showDataLabels — кастомизация внешнего вида
/// {@endtemplate}
class HistogramState extends ChartState {
  /// Количество корзин (используется для расчёта binInterval)
  int bins;

  /// Имя выбранной числовой колонки
  String? columnName;

  /// Поле для разделения
  String? splitByColumn;

  /// Показывать кривую нормального распределения (bell curve)
  bool showNormalDistributionCurve;

  /// Ширина интервала корзины (если null — рассчитывается автоматически)
  double? binInterval;

  /// Толщина границы столбцов
  double borderWidth;

  /// Отображать значения над столбцами
  bool showDataLabels;

  /// {@macro histogram_state}
  HistogramState({
    this.bins = 15,
    this.columnName,
    this.splitByColumn,
    this.showNormalDistributionCurve = false,
    this.binInterval,
    this.borderWidth = 2.0,
    this.showDataLabels = false,
  });

  @override
  HistogramState copyWith({
    int? bins,
    String? columnName,
    String? splitByColumn,
    bool? showNormalDistributionCurve,
    double? binInterval,
    double? borderWidth,
    bool? showDataLabels,
  }) {
    return HistogramState(
      bins: bins ?? this.bins,
      columnName: columnName ?? this.columnName,
      splitByColumn: splitByColumn ?? this.splitByColumn,
      showNormalDistributionCurve: showNormalDistributionCurve ?? this.showNormalDistributionCurve,
      binInterval: binInterval ?? this.binInterval,
      borderWidth: borderWidth ?? this.borderWidth,
      showDataLabels: showDataLabels ?? this.showDataLabels,
    );
  }

  @override
  HistogramState withField(String columnName, {ColumnType? type}) {
    if (type == ColumnType.numeric) {
      return copyWith(columnName: columnName);
    }
    return this;
  }

  // Сброс splitByColumn
  HistogramState resetSplitBy() {
    return HistogramState(
      columnName: columnName,
      bins: bins,
      splitByColumn: null,
      showNormalDistributionCurve: showNormalDistributionCurve,
      binInterval: binInterval,
      borderWidth: borderWidth,
      showDataLabels: showDataLabels,
    );
  }
}
