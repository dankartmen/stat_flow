import 'package:flutter/material.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import '../color/heatmap_color_mapper.dart';
import '../color/heatmap_palette.dart';
import '../model/heatmap_state.dart';

/// {@template heatmap_controls}
/// Фабрика для создания элементов управления тепловой картой
///
/// Предоставляет статические методы для построения UI-компонентов,
/// управляющих отображением тепловой карты. Все настройки сгруппированы
/// в логические секции: режим, оси, агрегация, нормализация, сортировка,
/// проценты, цвет, отображение.
/// {@endtemplate}
class HeatmapControls {
  /// Строит список виджетов управления на основе состояния
  ///
  /// Принимает:
  /// - [state] — текущее состояние тепловой карты
  /// - [onChanged] — колбэк для обновления состояния
  /// - [dataset] — датасет для получения списка колонок
  ///
  /// Возвращает список виджетов, которые можно разместить в панели настроек.
  static List<Widget> build({
    required HeatmapState state,
    required ValueChanged<HeatmapState> onChanged,
    required Dataset dataset,
  }) {
    final isCorrelationMode = state.xColumn == null && state.yColumn == null;
    final numericColumns = dataset.columns.whereType<NumericColumn>().toList();

    return [
      // Режим (корреляция / оси)
      _buildSection(
        title: 'Режим',
        child: Column(
          children: [
            RadioListTile<bool>(
              title: const Text('Корреляция всех числовых полей'),
              value: true,
              groupValue: isCorrelationMode,
              onChanged: (_) => onChanged(state.copyWith(xColumn: null, yColumn: null)),
            ),
            RadioListTile<bool>(
              title: const Text('Выбрать оси'),
              value: false,
              groupValue: isCorrelationMode,
              onChanged: (_) => onChanged(state.copyWith(xColumn: '', yColumn: '')),
            ),
          ],
        ),
      ),

      // Выбор осей (только если не корреляция)
      if (!isCorrelationMode) ...[
        _buildSection(
          title: 'Оси',
          child: Column(
            children: [
              _buildDropdown<String>(
                label: 'X ось',
                value: state.xColumn!,
                items: dataset.columns.map((c) => c.name).toList(),
                onChanged: (value) => onChanged(state.copyWith(xColumn: value)),
              ),
              const SizedBox(height: 12),
              _buildDropdown<String>(
                label: 'Y ось',
                value: state.yColumn!,
                items: dataset.columns.map((c) => c.name).toList(),
                onChanged: (value) => onChanged(state.copyWith(yColumn: value)),
              ),
            ],
          ),
        ),

        // === Агрегация (только если Y числовая) ===
        if (state.yColumn != null && _isNumericColumn(dataset, state.yColumn))
          _buildSection(
            title: 'Метрика',
            child: _buildDropdown<AggregationType>(
              label: 'Агрегация',
              value: state.aggregationType,
              items: AggregationType.values,
              onChanged: (value) => onChanged(state.copyWith(aggregationType: value!)),
              displayName: (type) => _aggregationName(type),
            ),
          ),
      ],

      // Нормализация
      _buildSection(
        title: 'Нормализация',
        child: _buildDropdown<NormalizeMode>(
          label: 'Тип',
          value: state.normalizeMode,
          items: NormalizeMode.values,
          onChanged: (value) => onChanged(state.copyWith(normalizeMode: value!)),
          displayName: (mode) => _normalizeModeName(mode),
        ),
      ),

      // Сортировка
      _buildSection(
        title: 'Сортировка',
        child: Column(
          children: [
            _buildDropdown<SortMode>(
              label: 'Сортировка X (строки)',
              value: state.sortX,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortX: value!)),
              displayName: (mode) => _sortModeName(mode),
            ),
            const SizedBox(height: 12),
            _buildDropdown<SortMode>(
              label: 'Сортировка Y (столбцы)',
              value: state.sortY,
              items: SortMode.values,
              onChanged: (value) => onChanged(state.copyWith(sortY: value!)),
              displayName: (mode) => _sortModeName(mode),
            ),
          ],
        ),
      ),

      // Проценты
      _buildSection(
        title: 'Проценты',
        child: _buildDropdown<PercentageMode>(
          label: 'Режим',
          value: state.percentageMode,
          items: PercentageMode.values,
          onChanged: (value) => onChanged(state.copyWith(percentageMode: value!)),
          displayName: (mode) => _percentageModeName(mode),
        ),
      ),

      // Цвет
      _buildSection(
        title: 'Цвет',
        child: Column(
          children: [
            _buildDropdown<HeatmapPalette>(
              label: 'Палитра',
              value: state.palette,
              items: HeatmapPalette.values,
              onChanged: (value) => onChanged(state.copyWith(palette: value!)),
              displayName: (p) => p.name,
            ),
            const SizedBox(height: 12),
            _buildDropdown<HeatmapColorMode>(
              label: 'Режим раскраски',
              value: state.colorMode,
              items: HeatmapColorMode.values,
              onChanged: (value) => onChanged(state.copyWith(colorMode: value!)),
              displayName: (mode) => mode == HeatmapColorMode.discrete ? 'Дискретный' : 'Градиент',
            ),
            if (state.colorMode == HeatmapColorMode.discrete) ...[
              const SizedBox(height: 12),
              _buildDropdown<int>(
                label: 'Сегментов',
                value: state.segments,
                items: const [5, 10, 20],
                onChanged: (value) => onChanged(state.copyWith(segments: value!)),
                displayName: (seg) => '$seg сегментов',
              ),
            ],
          ],
        ),
      ),

      //Отображение
      _buildSection(
        title: 'Отображение',
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Подписи осей'),
              value: state.showAxisLabels,
              onChanged: (value) => onChanged(state.copyWith(showAxisLabels: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Значения в ячейках'),
              value: state.showValues,
              onChanged: (value) => onChanged(state.copyWith(showValues: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Только верхний треугольник'),
              value: state.triangleMode,
              onChanged: (value) => onChanged(state.copyWith(triangleMode: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Кластеризация'),
              value: state.clusterEnabled,
              onChanged: (value) => onChanged(state.copyWith(clusterEnabled: value ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ];
  }

  /// Строит секцию с заголовком и разделителем.
  ///
  /// Используется для группировки связанных элементов управления.
  static Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        child,
        const Divider(),
      ],
    );
  }

  /// Строит выпадающий список с меткой.
  ///
  /// Поддерживает обобщённый тип [T] и опциональную функцию форматирования
  /// отображаемого текста.
  static Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? displayName,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        DropdownButton<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(displayName != null ? displayName(item) : item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }


  /// Возвращает локализованное название типа агрегации.
  static String _aggregationName(AggregationType type) {
    switch (type) {
      case AggregationType.count: return 'Количество';
      case AggregationType.sum: return 'Сумма';
      case AggregationType.avg: return 'Среднее';
      case AggregationType.min: return 'Минимум';
      case AggregationType.max: return 'Максимум';
      case AggregationType.median: return 'Медиана';
    }
  }

  /// Возвращает локализованное название режима нормализации.
  static String _normalizeModeName(NormalizeMode mode) {
    switch (mode) {
      case NormalizeMode.none: return 'Нет';
      case NormalizeMode.row: return 'По строкам';
      case NormalizeMode.column: return 'По столбцам';
      case NormalizeMode.total: return 'Общая';
    }
  }

  /// Возвращает локализованное название режима сортировки.
  static String _sortModeName(SortMode mode) {
    switch (mode) {
      case SortMode.none: return 'Нет';
      case SortMode.alphabetic: return 'По алфавиту';
      case SortMode.byValueAsc: return 'По возрастанию';
      case SortMode.byValueDesc: return 'По убыванию';
    }
  }

  /// Возвращает локализованное название режима процентов.
  static String _percentageModeName(PercentageMode mode) {
    switch (mode) {
      case PercentageMode.none: return 'Нет';
      case PercentageMode.row: return 'От строки';
      case PercentageMode.column: return 'От столбца';
      case PercentageMode.total: return 'От итога';
    }
  }

  /// Проверяет, является ли колонка числовой.
  static bool _isNumericColumn(Dataset dataset, String? columnName) {
    if (columnName == null) return false;
    final col = dataset.column(columnName);
    return col is NumericColumn;
  }
}