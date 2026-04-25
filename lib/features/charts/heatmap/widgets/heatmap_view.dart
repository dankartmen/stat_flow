import 'package:flutter/material.dart' hide DataColumn;
import 'package:heatmap_canvas/heatmap.dart';
import '../../../../core/dataset/dataset.dart';
import '../../chart_state.dart';
import '../model/heatmap_models.dart';
import '../model/heatmap_state.dart';

/// Максимальное количество уникальных категорий для отображения в таблице сопряжённости.
const int _kMaxUniqueCategories = 50;

/// {@template heatmap_view}
/// Основной виджет для отображения интерактивной тепловой карты.
///
/// Особенности:
/// - Поддержка режима корреляции всех числовых полей
/// - Поддержка ручного выбора осей (категориальная/числовая)
/// - Автоматическое определение типа колонок
/// - Построение таблиц сопряжённости для категориальных данных
/// - Агрегация числовых данных по категориям
/// - Асинхронная обработка больших объёмов данных
/// - Кластеризация, сортировка, нормализация и преобразование в проценты
/// {@endtemplate}
class HeatmapView extends StatefulWidget {
  /// Датасет, содержащий данные для построения тепловой карты.
  final Dataset dataset;

  /// Состояние тепловой карты (настройки отображения, выбранные колонки).
  final HeatmapState state;

  /// {@macro heatmap_view}
  const HeatmapView({
    super.key,
    required this.dataset,
    required this.state,
  });

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

/// {@template heatmap_view_state}
/// Состояние виджета [HeatmapView].
///
/// Управляет асинхронной загрузкой данных, кэшированием,
/// перестроением при изменении параметров и отображением тепловой карты.
/// {@endtemplate}
class _HeatmapViewState extends State<HeatmapView> {
  /// Кэшированные данные тепловой карты.
  HeatmapData? _cachedData;

  /// Ключ для идентификации текущих параметров данных.
  String? _dataKey;

  /// Флаг загрузки данных (показывает индикатор при первом запуске).
  bool _isLoadingData = false;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newDataKey = _computeDataKey(widget.state);
    final oldDataKey = _computeDataKey(oldWidget.state);

    if (newDataKey != oldDataKey) {
      _loadData();
    }

    // Принудительное обновление при изменении любых параметров состояния
    if (oldWidget.state != widget.state) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Вычисляет ключ, зависящий только от параметров, влияющих на значения ячеек.
  ///
  /// Используется для кэширования данных и определения необходимости перестроения.
  String _computeDataKey(HeatmapState state) {
    return '${state.useCorrelation}_'
        '${state.xColumn}_${state.yColumn}_'
        '${state.aggregationType}_'
        '${state.clusterEnabled}_'
        '${state.sortX}_${state.sortY}_'
        '${state.normalizeMode}_'
        '${state.percentageMode}';
  }

  /// Асинхронно загружает данные тепловой карты с кэшированием.
  Future<void> _loadData() async {
    final newKey = _computeDataKey(widget.state);

    // Если ключ не изменился и данные уже есть — ничего не делаем
    if (_dataKey == newKey && _cachedData != null) {
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      final data = await _buildData();

      if (!mounted) return;

      setState(() {
        _cachedData = data;
        _dataKey = newKey;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cachedData = HeatmapData(rowLabels: [], columnLabels: [], values: []);
        _isLoadingData = false;
      });
    }
  }

  /// Асинхронно строит данные для тепловой карты.
  ///
  /// Логика построения:
  /// - Если включён режим корреляции (`state.useCorrelation == true`),
  ///   вычисляет корреляционную матрицу для всех числовых колонок.
  /// - Иначе проверяет выбранные оси и строит данные в зависимости от типов колонок:
  ///   - Две категориальные → таблица сопряжённости
  ///   - Категориальная + числовая → агрегация по категориям
  ///   - Две числовые → не поддерживается (пустые данные)
  Future<HeatmapData> _buildData() async {
    final state = widget.state;
    final dataset = widget.dataset;

    // 1. Режим корреляции (все числовые колонки)
    if (state.useCorrelation) {
      final allColumns = <List<double?>>[];
      final columnNames = <String>[];

      for (final col in widget.dataset.columns) {
        if (col is NumericColumn) {
          allColumns.add(col.data.map((e) => e?.toDouble()).toList());
          columnNames.add(col.name);
        } else if (col is CategoricalColumn || col is TextColumn) {
          // Получаем сырые строковые значения
          final rawData = col is CategoricalColumn ? col.data : (col as TextColumn).data;
          final uniqueValues = rawData.whereType<String>().toSet().toList()..sort(); // сортируем для детерминированного порядка
          final codeMap = {for (int i = 0; i < uniqueValues.length; i++) uniqueValues[i]: i};
          final encoded = rawData.map((e) => e != null ? codeMap[e]!.toDouble() : null).toList();
          allColumns.add(encoded);
          columnNames.add(col.name);
        }
      }

      if (allColumns.length < 2) {
        return HeatmapData(rowLabels: [], columnLabels: [], values: []);
      }

      // Используем встроенный билдер корреляции (асинхронная версия для больших данных)
      final data = await HeatmapDataBuilder.pearsonCorrelationAsync(
        allColumns,
        columnNames: columnNames,
      );

      // Применяем трансформации (нормализация, сортировка, проценты, кластеризация)
      return await _applyTransformations(data);
    }

    // 2. Ручной выбор осей
    if (state.xColumn == null || state.yColumn == null) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    final xCol = dataset.column(state.xColumn!);
    final yCol = dataset.column(state.yColumn!);
    if (xCol == null || yCol == null) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    final xType = _getColumnType(xCol);
    final yType = _getColumnType(yCol);

    // Обе числовые — не поддерживаем
    if (xType == ColumnType.numeric && yType == ColumnType.numeric) {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    HeatmapData data;

    // X — категориальная (текстовая или категориальная)
    if (xType == ColumnType.text || xType == ColumnType.categorical) {
      final xCat = _toCategorical(xCol);
      if (yType == ColumnType.text || yType == ColumnType.categorical) {
        // Обе категориальные — таблица сопряжённости
        final yCat = _toCategorical(yCol);
        data = await _buildContingencyTable(xCat, yCat);
      } else if (yType == ColumnType.numeric) {
        // X категориальная, Y числовая — агрегация по X
        final yNum = yCol as NumericColumn;
        data = await _buildAggregationTable(xCat, yNum);
      } else {
        return HeatmapData(rowLabels: [], columnLabels: [], values: []);
      }
    }
    // Y — категориальная, X — числовая (меняем ролями)
    else if (yType == ColumnType.text || yType == ColumnType.categorical) {
      final yCat = _toCategorical(yCol);
      if (xType == ColumnType.numeric) {
        final xNum = xCol as NumericColumn;
        data = await _buildAggregationTable(yCat, xNum);
      } else {
        return HeatmapData(rowLabels: [], columnLabels: [], values: []);
      }
    } else {
      return HeatmapData(rowLabels: [], columnLabels: [], values: []);
    }

    // Применяем трансформации (нормализация, сортировка, проценты)
    return await _applyTransformations(data);
  }

  /// Определяет тип колонки.
  ColumnType _getColumnType(DataColumn col) {
    if (col is NumericColumn) return ColumnType.numeric;
    if (col is DateTimeColumn) return ColumnType.dateTime;
    if (col is CategoricalColumn) return ColumnType.categorical;
    if (col is TextColumn) return ColumnType.text;
    throw Exception('Неизвестный тип колонки: ${col.name}');
  }

  /// Преобразует колонку в категориальную.
  CategoricalColumn _toCategorical(DataColumn col) {
    if (col is CategoricalColumn) return col;
    if (col is TextColumn) return CategoricalColumn(col.name, col.data);
    throw Exception('Невозможно преобразовать колонку ${col.name} в категориальную');
  }

  /// Строит таблицу сопряжённости для двух категориальных колонок.
  ///
  /// Каждая ячейка содержит количество совместных появлений категорий.
  /// Количество категорий ограничено константой `_kMaxUniqueCategories`.
  Future<HeatmapData> _buildContingencyTable(CategoricalColumn x, CategoricalColumn y) async {
    final xCategories = _uniqueCategories(x.data);
    final yCategories = _uniqueCategories(y.data);

    final limitedX = xCategories.length > _kMaxUniqueCategories
        ? xCategories.sublist(0, _kMaxUniqueCategories)
        : xCategories;
    final limitedY = yCategories.length > _kMaxUniqueCategories
        ? yCategories.sublist(0, _kMaxUniqueCategories)
        : yCategories;

    final matrix = List.generate(
      limitedX.length,
      (_) => List.filled(limitedY.length, 0.0),
    );

    for (int i = 0; i < x.data.length; i++) {
      final xv = x.data[i];
      final yv = y.data[i];
      if (xv == null || yv == null) continue;
      final xi = limitedX.indexOf(xv);
      final yi = limitedY.indexOf(yv);
      if (xi != -1 && yi != -1) {
        matrix[xi][yi] += 1;
      }
    }

    return HeatmapData(
      rowLabels: limitedX,
      columnLabels: limitedY,
      values: matrix,
    );
  }

  /// Строит агрегированную таблицу для пары "категориальная + числовая".
  ///
  /// Для каждой категории вычисляется значение в зависимости от
  /// выбранного типа агрегации ([AggregationType]).
  Future<HeatmapData> _buildAggregationTable(CategoricalColumn cat, NumericColumn num) async {
    final categories = _uniqueCategories(cat.data);
    final limitedCat = categories.length > _kMaxUniqueCategories
        ? categories.sublist(0, _kMaxUniqueCategories)
        : categories;

    final aggregated = _aggregateNumerical(
      catValues: cat.data,
      numValues: num.data,
      categories: limitedCat,
      aggType: widget.state.aggregationType,
    );

    return HeatmapData(
      rowLabels: limitedCat,
      columnLabels: [widget.state.aggregationType.name],
      values: aggregated.map((v) => [v]).toList(),
    );
  }

  /// Возвращает отсортированный список уникальных значений.
  List<String> _uniqueCategories(List<String?> data) {
    final set = <String>{};
    for (final v in data) {
      if (v != null) set.add(v);
    }
    return set.toList()..sort();
  }

  /// Выполняет числовую агрегацию по категориям.
  ///
  /// Поддерживаемые типы:
  /// - [AggregationType.count] — количество значений
  /// - [AggregationType.sum] — сумма значений
  /// - [AggregationType.avg] — среднее арифметическое
  /// - [AggregationType.min] — минимальное значение
  /// - [AggregationType.max] — максимальное значение
  /// - [AggregationType.median] — медиана
  List<double> _aggregateNumerical({
    required List<String?> catValues,
    required List<double?> numValues,
    required List<String> categories,
    required AggregationType aggType,
  }) {
    final counts = List.filled(categories.length, 0);
    final sums = List.filled(categories.length, 0.0);
    final mins = List.filled(categories.length, double.infinity);
    final maxs = List.filled(categories.length, -double.infinity);
    final medians = List.generate(categories.length, (_) => <double>[]);

    for (int i = 0; i < catValues.length; i++) {
      final c = catValues[i];
      final n = numValues[i];
      if (c == null || n == null) continue;
      final idx = categories.indexOf(c);
      if (idx == -1) continue;
      counts[idx]++;
      sums[idx] += n;
      medians[idx].add(n);
      if (n < mins[idx]) mins[idx] = n;
      if (n > maxs[idx]) maxs[idx] = n;
    }

    final values = List.filled(categories.length, 0.0);
    for (int i = 0; i < categories.length; i++) {
      switch (aggType) {
        case AggregationType.count:
          values[i] = counts[i].toDouble();
          break;
        case AggregationType.sum:
          values[i] = sums[i];
          break;
        case AggregationType.avg:
          values[i] = counts[i] > 0 ? sums[i] / counts[i] : 0;
          break;
        case AggregationType.min:
          values[i] = counts[i] > 0 ? mins[i] : 0;
          break;
        case AggregationType.max:
          values[i] = counts[i] > 0 ? maxs[i] : 0;
          break;
        case AggregationType.median:
          final list = medians[i];
          if (list.isEmpty) {
            values[i] = 0;
          } else {
            list.sort();
            final mid = list.length ~/ 2;
            values[i] = list.length.isOdd
                ? list[mid]
                : (list[mid - 1] + list[mid]) / 2;
          }
          break;
      }
    }
    return values;
  }

  /// Применяет к данным все трансформации, указанные в состоянии.
  ///
  /// Включает:
  /// - Кластеризацию (только для квадратных матриц)
  /// - Сортировку строк и столбцов
  /// - Нормализацию
  /// - Преобразование в проценты
  Future<HeatmapData> _applyTransformations(HeatmapData data) async {
    final state = widget.state;

    // Кластеризация (только для квадратных матриц, обычно для корреляции)
    if (state.clusterEnabled &&
        data.rowLabels.length == data.columnLabels.length) {
      data = await HeatmapTransformer.clusterAsync(data);
    }

    // Сортировка строк и столбцов
    if (state.sortX != SortMode.none) {
      data = await HeatmapTransformer.sortRowsAsync(data, state.sortX);
    }
    if (state.sortY != SortMode.none) {
      data = await HeatmapTransformer.sortColsAsync(data, state.sortY);
    }

    // Нормализация
    if (state.normalizeMode != NormalizeMode.none) {
      data = await HeatmapTransformer.normalizeAsync(data, state.normalizeMode);
    }

    // Преобразование в проценты
    if (state.percentageMode != PercentageMode.none) {
      data = await HeatmapTransformer.toPercentagesAsync(data, state.percentageMode);
    }

    return data;
  }

  /// Строит конфигурацию отображения тепловой карты.
  HeatmapConfig _buildConfig() {
    final state = widget.state;
    // Безопасное получение min/max: если данных нет, используем 0 и 1
    final min = _cachedData?.min ?? 0.0;
    final max = _cachedData?.max ?? 1.0;

    return HeatmapConfig(
      palette: state.palette,
      colorMode: state.colorMode,
      segments: state.segments,
      axis: HeatmapAxisData(
        showLabels: state.showAxisLabels,
      ),
      legend: HeatmapLegendData(
        tooltipBuilder: _legendTooltip,
        reserveRightSpace: 18,
        reserveTopSpace: 62,
      ),
      touchData: HeatmapTouchData(),
      showValues: state.showValues,
      triangleMode: state.triangleMode,
      sortX: state.sortX,
      sortY: state.sortY,
      clusterEnabled: state.clusterEnabled,
      cellTooltipBuilder: _createCellTooltip(min: min, max: max),
    );
  }

  /// Строитель тултипа для легенды.
  Widget _legendTooltip(BuildContext context, LegendTooltipInfo? info) {
    if (info == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).focusColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.isDiscrete) ...[
            Text(
              'Диапазон:',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            Text(
              '[${info.segmentMin!.toStringAsFixed(3)} — ${info.segmentMax!.toStringAsFixed(3)}]',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Сегмент ${info.segmentIndex! + 1}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ] else ...[
            Text(
              'Значение:',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            Text(
              info.value.toStringAsFixed(3),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Создаёт универсальный тултип с прогресс-баром, нормализованным по диапазону данных.
  ///
  /// Принимает [min] и [max] через замыкание для использования в конфигурации.
  Widget Function(BuildContext, HeatmapCell) _createCellTooltip({
    required double min,
    required double max,
    HeatmapTooltipStyle style = const HeatmapTooltipStyle(),
  }) {
    return (context, cell) {
      final value = cell.value;
      final range = max - min;
      final normalized = range == 0 ? 0.5 : (value - min) / range;
      final percent = (normalized * 100).clamp(0, 100);
      final color = value >= 0 ? style.positiveColor : style.negativeColor;

      return Container(
        width: style.width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${cell.rowLabel} ⟷ ${cell.colLabel}',
              style: style.labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: normalized,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Значение: ${value.toStringAsFixed(2)}',
                  style: style.valueStyle.copyWith(color: color),
                ),
                Text(
                  '[${min.toStringAsFixed(2)} … ${max.toStringAsFixed(2)}]',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // Показываем индикатор загрузки только при первом получении данных
    if (_isLoadingData && _cachedData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Если данных нет вообще
    if (_cachedData == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    // Если данные пустые
    if (_cachedData!.rowLabels.isEmpty) {
      return const Center(child: Text('Недостаточно данных для построения тепловой карты'));
    }

    return Heatmap(
      data: _cachedData!,
      config: _buildConfig(),
    );
  }
}

