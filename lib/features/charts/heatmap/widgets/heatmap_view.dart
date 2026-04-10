import 'dart:math' show min;
import 'dart:developer' show log;
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:stat_flow/features/charts/heatmap/widgets/heatmap_legend.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../../core/dataset/dataset.dart';
import '../calculator/heatmap_data_builder.dart';
import '../model/correlation_clusterer.dart';
import '../color/heatmap_color_mapper.dart';
import '../model/correlation_matrix.dart';
import '../model/heatmap_data.dart';
import '../model/heatmap_state.dart';
import '../model/hover_range.dart';
import '../painter/heatmap_painter.dart';
import '../color/heatmap_palette.dart';

/// {@template heatmap_view}
/// Основной виджет для отображения интерактивной тепловой карты
/// с поддержкой настройки цветов, кластеризации и анимации.
///
/// Особенности:
/// - Интерактивное масштабирование через InteractiveViewer
/// - Подсветка ячейки при наведении мыши
/// - Плавная анимация при смене цветовых схем
/// - Кластеризация матрицы для выявления паттернов
/// - Автоматическое обновление при изменении параметров
/// - Компактная легенда под картой
/// {@endtemplate}
class HeatmapView extends StatefulWidget {
  /// Данные для отображения тепловой карты, включая значения и метки
  final Dataset dataset;

  /// Состояние тепловой карты, содержащее настройки отображения
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

class _HeatmapViewState extends State<HeatmapView>
    with SingleTickerProviderStateMixin {
  /// Индекс строки под курсором мыши (для подсветки)
  int? hoverRow;

  /// Индекс колонки под курсором мыши (для подсветки)
  int? hoverCol;

  /// Текущий маппер цветов на основе настроек (палитра, сегменты, режим)
  late HeatmapColorMapper _currentMapper;

  /// Контроллер анимации для плавных переходов между цветовыми схемами
  late AnimationController _controller;

  /// Предыдущий маппер для интерполяции во время анимации
  late HeatmapColorMapper _previousMapper;

  /// Контроллер трансформации для масштабирования
  final TransformationController _zoomController = TransformationController();

  /// Матрица трансформации на последнем кадре для оптимизации вычисления видимой области
  Matrix4? _lastMatrix;

  /// Видимая область в координатах строк/столбцов для оптимизации отрисовки больших матриц
  Rect? _visibleRect;

  /// Данные, подготовленные для отображения (после кластеризации, сортировки, нормализации)
  late HeatmapData? _displayData;


  /// Кэш ключа данных
  String? _currentDataKey;

  /// Кэш ключа стиля 
  String? _currentStyleKey;

  /// Future для асинхронного вычисления данных  
  Future<HeatmapData>? _computeFuture;
  /// Диапазон значений, соответствующий наведению на легенду.
  /// Используется для подсветки ячеек с близкими значениями.
  HoverRange? _hoverRange;
  
  /// Операция для отмены текущего вычисления данных, если параметры изменились до его завершения.
  CancelableOperation<HeatmapData>? _currentOperation;

  /// Флаг для отслеживания, был ли виджет уже удалён, чтобы избежать обновления состояния после dispose.
  bool _disposed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _startComputation();
  }

  @override
  void didUpdateWidget(covariant HeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newDataKey = _computeDataKey();
    final newStyleKey = _computeStyleKey();

    // Если изменились данные – пересчитываем всё
    if (_currentDataKey != newDataKey) {
      _currentDataKey = newDataKey;
      _startComputation();
    }
    // Если изменились только стили – обновляем цвета и запускаем анимацию
    else if (_currentStyleKey != newStyleKey && _displayData != null) {
      _currentStyleKey = newStyleKey;
      _previousMapper = _currentMapper;
      _currentMapper = _createMapper();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _currentOperation?.cancel();
    _currentOperation = null;
    _controller.dispose();
    _zoomController.dispose();
    _disposed = true;
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    if (_displayData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Вычисление данных тепловой карты...'),
          ],
        ),
      );
    }
    return _buildHeatmap();
  }

  /// Генерирует ключ для кэширования данных на основе настроек, влияющих на значения ячеек
  String _computeDataKey() {
    return '${widget.state.useCorrelation}_'
        '${widget.state.xColumn}_${widget.state.yColumn}_'
        '${widget.state.aggregationType}_'
        '${widget.state.clusterEnabled}_'
        '${widget.state.sortX}_${widget.state.sortY}_'
        '${widget.state.normalizeMode}_'
        '${widget.state.percentageMode}';
  }

  /// Генерирует ключ для кэширования стилей на основе настроек, влияющих на отображение (цветовая схема, сегменты, режим цветов)
  String _computeStyleKey() {
    return '${widget.state.palette}_'
        '${widget.state.segments}_'
        '${widget.state.colorMode}';
  }


  /// Обработчик готовности данных. Устанавливает [_displayData] и обновляет мапперы цветов.
  HeatmapData _onDataReady(HeatmapData data) {
      if (_disposed || !mounted) return data;
      setState(() {
        _displayData = data;
        _currentMapper = _createMapper();
        _previousMapper = _currentMapper; // сброс анимации
        _controller.value = 0;
        _currentStyleKey = _computeStyleKey();
      });

      if (data.wasTrimmed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Некоторые категории были скрыты из-за большого количества уникальных значений (показаны топ-50)'),
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
      return data;
    }

  /// Запускает вычисление данных тепловой карты.
  ///
  /// Если данные уже вычислены для текущего ключа, пропускает.
  /// В противном случае вычисляет синхронно (для корреляции) или асинхронно (для выбранных осей).
  void _startComputation() async{
    // Отменяем предыдущий расчёт, если он ещё идёт
    _currentOperation?.cancel();

    // Сбрасываем текущие данные
    setState(() {
      _displayData = null;
    });

    late final Future<HeatmapData> future;
    if (widget.state.useCorrelation) {
      future = _loadCorrelationData();
    } else {
      final builder = HeatmapDataBuilder(
        dataset: widget.dataset,
        state: widget.state
      );
      future = builder.buildAsync();
    }

    _currentOperation = CancelableOperation.fromFuture(
      future,
      onCancel: () => debugPrint('Heatmap computation cancelled'),
    );
    _currentOperation?.value.then(_onDataReady).catchError((e) {
      log(e, name: "HeatmapView");
      if (!_disposed && mounted) {
        _onDataReady(HeatmapData(rowLabels: [], columnLabels: [], values: []));
      }
    });
  }
    

  

  Future<HeatmapData> _loadCorrelationData() async {
    final matrix = await CorrelationMatrix.fromDatasetAsync(widget.dataset);
    if (matrix.wasTrimmed && mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Было выбрано только 100 числовых колонок с наибольшей дисперсией для построения корреляционной матрицы'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }
    var data = HeatmapData.fromCorrelation(matrix);
    // Применяем трансформации (они уже асинхронные)
    data = await _applyTransformations(data);
    return data;
  }
  /// Применяет к данным все трансформации: кластеризацию, сортировку, нормализацию, проценты.
  Future<HeatmapData> _applyTransformations(HeatmapData data) async {
    // Кластеризация только для корреляционной матрицы
    if (widget.state.clusterEnabled &&
        widget.state.useCorrelation) {
      data = CorrelationClusterer.clusterHeatmapData(data);
    }

    // Сортировка
    if (widget.state.sortX != SortMode.none) {
      data = data.sortRows(widget.state.sortX);
    }
    if (widget.state.sortY != SortMode.none) {
      data = data.sortCols(widget.state.sortY);
    }

    // Нормализация
    if (widget.state.normalizeMode != NormalizeMode.none) {
      data = data.normalize(widget.state.normalizeMode);
    }

    // Проценты
    if (widget.state.percentageMode != PercentageMode.none) {
      data = data.toPercentages(widget.state.percentageMode);
    }

    return data;
  }


  /// Обновляет [_visibleRect] на основе текущей трансформации и размера виджета.
  /// Вычисляет, какие строки и столбцы видимы в данный момент, чтобы оптимизировать отрисовку больших матриц.
  /// Параметры:
  /// - [axisOffset]: отступ для осевых меток
  /// - [cellWidth]: ширина одной ячейки
  /// - [cellHeight]: высота одной ячейки
  /// - [colCount]: общее количество столбцов
  /// - [rowCount]: общее количество строк
  /// 
  /// Логика:
  /// 1. Получаем текущую матрицу трансформации от InteractiveViewer
  /// 2. Инвертируем её, чтобы преобразовать координаты виджета в координаты тепловой карты
  /// 3. Вычисляем координаты верхнего левого и нижнего правого углов видимой области
  /// 4. Преобразуем эти координаты в индексы строк и столбцов, учитывая отступ для осевых меток
  /// 5. Сохраняем видимую область в виде Rect, где left=столбец начала, top=строка начала, right=столбец конца, bottom=строка конца
  void _updateVisibleRect({
    required double axisOffset, 
    required double cellWidth, 
    required double cellHeight,
    required int colCount,
    required int rowCount
  }) {
    if (_displayData == null) return;
    final matrix = _zoomController.value;
    if (_lastMatrix == matrix) return;
    _lastMatrix = matrix;

    // Получаем размер холста (контейнера)
    final size = context.size;
    if (size == null) return;

    // Вычисляем видимую область в координатах тепловой карты
    final inverted = Matrix4.inverted(matrix);
    final topLeft = Vector4(0, 0, 0, 1);
    final bottomRight = Vector4(size.width, size.height, 0, 1);
    final topLeftTransformed = inverted.transform(topLeft);
    final bottomRightTransformed = inverted.transform(bottomRight);

    double left = topLeftTransformed.x;
    double top = topLeftTransformed.y;
    double right = bottomRightTransformed.x;
    double bottom = bottomRightTransformed.y;

    // Преобразуем в индексы строк/столбцов с учётом axisOffset
    final startCol = ((left - axisOffset) / cellWidth).floor().clamp(0, colCount - 1);
    final endCol = ((right - axisOffset) / cellWidth).ceil().clamp(0, colCount - 1);
    final startRow = ((top - axisOffset) / cellHeight).floor().clamp(0, rowCount - 1);
    final endRow = ((bottom - axisOffset) / cellHeight).ceil().clamp(0, rowCount - 1);

    setState(() {
      _visibleRect = Rect.fromLTRB(startCol.toDouble(), startRow.toDouble(), endCol.toDouble(), endRow.toDouble());
    });
  }
  /// Создание маппера цветов на основе текущих настроек.
  ///
  /// Поддерживает два режима:
  /// - [HeatmapColorMode.discrete]: равномерные сегменты с четкими границами
  ///   (полезно для выявления точных значений)
  /// - [HeatmapColorMode.gradient]: плавный переход между цветами
  ///   (лучше для визуального восприятия общей структуры)
  HeatmapColorMapper _createMapper() {
    final paletteColors = HeatmapPaletteFactory.baseColors(widget.state.palette);
    final min = _displayData?.min ?? -1.0;
    final max = _displayData?.max ?? 1.0;
    if (widget.state.colorMode == HeatmapColorMode.discrete) {      
      return DiscreteColorMapper(
        min: min,
        max: max,
        segments: widget.state.segments,
        baseColors: paletteColors,
      );
    } else {
      return GradientColorMapper(
        paletteType: widget.state.palette,
        min: min,
        max: max,
      );
    }
  }

  /// Обработчик наведения на легенду. Обновляет [_hoverRange] для подсветки ячеек.
  void _onLegendHover(HoverRange? range) {
    setState(() => _hoverRange = range);
  }

  /// Построение виджета тепловой карты с поддержкой масштабирования.
  ///
  /// Использует [InteractiveViewer] для обеспечения:
  /// - Панорамирования (перетаскивания) по большой матрице
  /// - Масштабирования жестами или двойным щелчком
  /// - Плавного скроллинга
  ///
  /// Также реализует интерактивную подсветку ячеек при наведении мыши
  /// (для десктопных и веб-версий).
  Widget _buildHeatmap() {
    final rowCount = _displayData!.rowLabels.length;
    final colCount = _displayData!.columnLabels.length;
    if (rowCount == 0 || colCount == 0) {
      return const Center(child: Text('Нет данных для отображения'));
    }
    final axisOffset = widget.state.showAxisLabels ? 40.0 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints){
        final availableWidth = constraints.maxWidth - axisOffset - 16; // Учитываем отступы и место для легенды
        final availableHeight = constraints.maxHeight - axisOffset - 60; // Учитываем место для легенды
      
        double cellSizeByWidth = availableWidth / colCount;
        double cellSizeByHeight = availableHeight / rowCount;

        cellSizeByWidth = cellSizeByWidth.clamp(0.0, 200.0);
        cellSizeByHeight = cellSizeByHeight.clamp(0.0, 200.0);

        final showValues = min(cellSizeByWidth, cellSizeByHeight) > 35;

        final totalWidth = colCount * cellSizeByWidth + axisOffset;
        final totalHeight = rowCount * cellSizeByHeight + axisOffset;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InteractiveViewer(
                transformationController: _zoomController,
                onInteractionUpdate: (details) => _updateVisibleRect(
                  axisOffset: axisOffset,
                  cellHeight: cellSizeByHeight,
                  cellWidth: cellSizeByWidth,
                  colCount: colCount,
                  rowCount: rowCount
                ),
                constrained: false,
                minScale: 0.5, // Минимальное увеличение
                maxScale: 5.0, // Максимальное увеличение
                boundaryMargin: const EdgeInsets.all(8), // Отступы от границ для удобства
          
                child: MouseRegion(
                  // Отслеживание мыши для интерактивной подсветки
                  onHover: (event) {
                    final localPos = event.localPosition;
          
                    // Вычисляем индекс ячейки под курсором.
                    // Вычитаем cellSize для учета отступа под подписи осей,
                    // который добавляется в HeatmapPainter.
                    final row = ((localPos.dy - axisOffset) / cellSizeByHeight).floor();
                    final col = ((localPos.dx - axisOffset) / cellSizeByWidth).floor();
          
                    // Проверяем, что курсор находится в пределах матрицы
                    if (row >= 0 && row < rowCount && col >= 0 && col < colCount) {
                      if (row != hoverRow || col != hoverCol) {
                        setState(() {
                          hoverRow = row;
                          hoverCol = col;
                        });
                      }
                    } else {
                      if (hoverRow != null) {
                        setState(() {
                          hoverRow = null;
                          hoverCol = null;
                        });
                      }
                    }
                  },
                  // Сброс подсветки при уходе мыши с виджета
                  onExit: (_) {
                    setState(() {
                      hoverRow = null;
                      hoverCol = null;
                    });
                  },
          
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return CustomPaint(
                        size: Size(totalWidth, totalHeight),
                        painter: HeatmapPainter(
                          data: _displayData!,
                          axisOffset: axisOffset,
                          colorMapper: _currentMapper,
                          previousMapper: _previousMapper,
                          animationValue: _controller.value,
                          cellWidth: cellSizeByWidth,
                          cellHeight: cellSizeByHeight,
                          showValues: showValues,
                          showAxisLabels: false,
                          triangleMode: widget.state.triangleMode,
                          hoverRow: hoverRow,
                          hoverCol: hoverCol,
                          hoverRange: _hoverRange,
                          percentageMode: widget.state.percentageMode,
                          visibleRect: _visibleRect,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            HeatmapLegend(
              mapper: _currentMapper,
              min: _displayData!.min,
              max: _displayData!.max,
              segments: widget.state.segments,
              onHover: _onLegendHover,
              colorMode: widget.state.colorMode,
            ),
          ],
        );
      }
    );
  }
}