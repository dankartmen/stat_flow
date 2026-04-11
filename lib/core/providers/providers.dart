import 'dart:developer';

import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/charts/chart_type.dart';
import 'package:stat_flow/features/charts/floating_chart/floating_chart_data.dart';

import '../../features/charts/bar_chart/bar_state.dart';
import '../../features/charts/boxplot/boxplot_state.dart';
import '../../features/charts/chart_state.dart';
import '../../features/charts/histogram/histogram_state.dart';
import '../../features/charts/line_chart/line_state.dart';
import '../../features/charts/scatterplot/scatter_state.dart';

/// Тип текущего отображаемого экрана
enum ScreenType { canvas, data }

final _sampledCache = <Dataset, Dataset>{};

/// Провайдер для хранения текущего загруженного датасета
/// 
/// Изначально равен `null`. Устанавливается после успешной загрузки CSV-файла
/// через [CsvLoader]. Используется всеми компонентами приложения для доступа
/// к данным и их визуализации.
final datasetProvider = StateProvider<Dataset?>((ref) => null);

/// Провайдер для доступа к "выборке" датасета
/// Предоставляет оптимизированную версию датасета для быстрого отображения в графиках и таблицах.
final sampledDatasetProvider = Provider<Dataset?>((ref) {
  final full = ref.watch(datasetProvider);
  if (full == null) {
    // Очищаем кэш при выгрузке датасета
    _sampledCache.clear();
    return null;
  }

  if (_sampledCache.containsKey(full)) {
    return _sampledCache[full]!;
  }

  final sampledColumns = full.columns.map<DataColumn<dynamic>>((col) {
    if ((col is NumericColumn || col is CategoricalColumn || col is DateTimeColumn) && col.length > 1000) {
      final sampledData = col.data.sample(800);
      if (col is NumericColumn) return NumericColumn(col.name, sampledData.cast<double?>());
      if (col is CategoricalColumn) return CategoricalColumn(col.name, sampledData.cast<String?>());
      if (col is DateTimeColumn) return DateTimeColumn(col.name, sampledData.cast<DateTime?>());
    }
    return col;
  }).toList();

  final sampled = Dataset(name: full.name, columns: sampledColumns);
  _sampledCache[full] = sampled;
  return sampled;
});

/// Провайдер для доступа к полному датасету
/// Используется в компонентах, которым необходим полный набор данных для анализа 
final fullDatasetProvider = Provider<Dataset?>((ref) => ref.watch(datasetProvider));

/// Провайдер для управления состоянием правой панели с данными
/// 
/// Определяет, развернута ли правая панель (`true`) или свернута (`false`).
/// Используется для анимации сворачивания/разворачивания панели с колонками датасета.
final rightPanelExpandedProvider = StateProvider<bool>((ref) => true);

/// Провайдер для хранения идентификатора выбранного графика
/// 
/// Хранит `id` текущего активного графика. Используется для:
/// - Подсветки выбранного графика
/// - Отображения контекстной панели управления (TopControlPanel)
/// - Определения, какой график получает фокус при взаимодействии
final selectedChartIdProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Провайдер для получения списка идентификаторов всех графиков
/// Используется для:
/// - Быстрой проверки наличия графиков на канвасе
/// - Управления порядком отображения графиков (выбор/фокус)
/// - Определения занятых полей в датасете (через usedFieldsProvider)
/// При загрузке нового графика автоматически обновляется список идентификаторов.
/// При удалении графика его идентификатор удаляется из списка.
final chartIdsProvider = Provider<List<int>>((ref) {
  final charts = ref.watch(chartsProvider);
  return charts.map((c) => c.id).toList();
});

/// Провайдер текущего экрана
/// 
/// Хранит тип текущего отображаемого экрана (канвас или данные). Используется для
/// переключения между основным рабочим пространством (канвасом) и панелью с данными (список колонок, предпросмотр данных).
/// При загрузке приложения по умолчанию установлен на `ScreenType.canvas`.
final currentScreenProvider = StateProvider.autoDispose<ScreenType>((ref) => ScreenType.canvas);


/// {@template charts_notifier}
/// Управляет списком плавающих графиков на канвасе
/// 
/// Отвечает за:
/// - Добавление новых графиков
/// - Удаление существующих графиков
/// - Обновление позиции и размера графиков при перетаскивании
/// - Обновление состояния графиков (выбранные колонки, настройки)
/// - Изменение порядка графиков (выбор/фокус)
/// {@endtemplate}
class ChartsNotifier extends StateNotifier<List<FloatingChartData>> {
  /// {@macro charts_notifier}
  ChartsNotifier() : super([]);

  /// Добавляет новый график в список
  void addChart(FloatingChartData chart, WidgetRef ref) {
    final sampled = ref.read(sampledDatasetProvider);

    FloatingChartData updatedChart;
    if (chart.type == ChartType.heatmap){
      log("Передан полный датасет");
      updatedChart = chart.copyWith(dataset: chart.dataset);
    }
    else{
      log("Передан сэплированный датасет");
      updatedChart = chart.copyWith(dataset: sampled ?? chart.dataset);
    }
    state = [...state, updatedChart];
  }

  /// Удаляет график с указанным идентификатором
  void removeChart(int id) {
    state = state.where((c) => c.id != id).toList();
  }

  /// Обновляет позицию графика на канвасе
  void updatePosition(int id, Offset position) {
    state = [
      for (final chart in state)
        if (chart.id == id) chart.copyWith(position: position) else chart
    ];
  }

  /// Обновляет размер графика
  void updateSize(int id, Size size) {
    state = [
      for (final chart in state)
        if (chart.id == id) chart.copyWith(size: size) else chart
    ];
  }

  /// Обновляет внутреннее состояние графика (выбранные колонки, параметры)
  void updateChartState(int id, ChartState newState) {
    state = [
      for (final chart in state)
        if (chart.id == id) chart.copyWith(state: newState) else chart
    ];
  }

  /// Перемещает график в конец списка (делает его выбранным/поверх других)
  void selectChart(int id) {
    final index = state.indexWhere((c) => c.id == id);
    if (index == -1 || index == state.length - 1) return;
    final chart = state[index];
    state = [...state.where((c) => c.id != id), chart];
  }
}

/// Провайдер для доступа к списку графиков
/// 
/// Предоставляет методы для управления графиками через [ChartsNotifier].
/// Используется всеми компонентами, которым необходимо:
/// - Отображать графики на канвасе
/// - Добавлять новые визуализации
/// - Обновлять параметры существующих графиков
final chartsProvider = StateNotifierProvider<ChartsNotifier, List<FloatingChartData>>((ref) {
  return ChartsNotifier();
});

/// {@template used_fields_provider}
/// Провайдер для вычисления множества полей датасета, используемых в графиках
/// 
/// Анализирует все текущие графики и собирает имена колонок, которые:
/// - Используются как основная переменная (гистограмма, ящик с усами)
/// - Используются как переменные X/Y (диаграмма рассеяния, линейный график)
/// - Используются для категоризации (столбчатая диаграмма)
/// 
/// Используется в правой панели для визуальной индикации занятых полей.
/// {@endtemplate}
final usedFieldsProvider = Provider.autoDispose<Set<String>>((ref) {
  final charts = ref.watch(chartsProvider.select((list) => list));
  final used = <String>{};
  for (final chart in charts) {
    final state = chart.state;
    if (state is HistogramState && state.columnName != null) {
      used.add(state.columnName!);
    } else if (state is BoxPlotState && state.columnName != null) {
      used.add(state.columnName!);
    } else if (state is ScatterState) {
      if (state.firstColumnName != null) used.add(state.firstColumnName!);
      if (state.secondColumnName != null) used.add(state.secondColumnName!);
    } else if (state is LineState && state.columnName != null) {
      used.add(state.columnName!);
    } else if (state is BarState && state.columnName != null) {
      used.add(state.columnName!);
    }
  }
  return used;
});