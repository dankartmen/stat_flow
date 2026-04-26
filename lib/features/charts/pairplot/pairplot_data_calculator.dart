import 'package:stat_flow/core/dataset/dataset.dart';
import 'pairplot_models.dart';
import 'pairplot_state.dart';

/// {@template pairplot_data_calculator}
/// Калькулятор данных для Pair Plot (матрицы рассеяния).
/// 
/// Преобразует сырые данные из датасета в формат, пригодный для отображения
/// в матрице рассеяния. Поддерживает:
/// - Выбор подмножества числовых колонок
/// - Сэмплирование точек при превышении лимита
/// - Обработку пропущенных (null) значений
/// 
/// Возвращает [PairPlotData] с матрицей ячеек, где каждая ячейка содержит
/// пары значений (x, y) для соответствующей пары колонок.
/// {@endtemplate}
class PairPlotDataCalculator {
  /// Данные для отображения (матрица ячеек).
  final PairPlotData data;

  /// Флаг, указывающий, что данные были сэмплированы (уменьшены).
  /// TODO(developer): Использовать этот флаг для отображения предупреждения пользователю.
  final bool isSampled;

  /// Сообщение об ошибке (если есть).
  final String? error;

  PairPlotDataCalculator._(this.data, this.isSampled, this.error);

  /// Вычисляет данные на основе датасета и состояния.
  /// 
  /// Принимает:
  /// - [dataset] — исходный датасет
  /// - [state] — настройки отображения (выбранные колонки, maxPoints и т.д.)
  /// 
  /// Возвращает:
  /// - [PairPlotDataCalculator] с подготовленными данными или ошибкой
  static PairPlotDataCalculator calculate({
    required Dataset dataset,
    required PairPlotState state,
  }) {
    final numericColumns = dataset.numericColumns;
    if (numericColumns.length < 2) {
      return PairPlotDataCalculator._(
        PairPlotData(columnNames: [], matrix: []),
        false,
        'Недостаточно числовых колонок (минимум 2)',
      );
    }

    // Берём все числовые колонки или только выбранные
    final selectedColumns = state.selectedColumns != null && state.selectedColumns!.isNotEmpty
        ? numericColumns.where((c) => state.selectedColumns!.contains(c.name)).toList()
        : numericColumns;

    if (selectedColumns.length < 2) {
      return PairPlotDataCalculator._(
        PairPlotData(columnNames: [], matrix: []),
        false,
        'Недостаточно выбранных колонок',
      );
    }

    // Получаем hue-колонку, если требуется
    DataColumn? hueColumn;
    bool hueIsNumeric = false;
    if (state.useHue && state.hueColumn != null) {
      hueColumn = dataset.column(state.hueColumn!);
      if (hueColumn == null) {
        return PairPlotDataCalculator._(
          PairPlotData(columnNames: [], matrix: []),
          false,
          'Колонка "${state.hueColumn}" для окраски не найдена',
        );
      }
      hueIsNumeric = hueColumn is NumericColumn;
    }

    final columnNames = selectedColumns.map((c) => c.name).toList();
    final n = columnNames.length;

    // Строим матрицу ячеек n x n
    final matrix = List.generate(n, (i) {
      return List.generate(n, (j) {
        final xCol = selectedColumns[i];
        final yCol = selectedColumns[j];

        final xValues = <double>[];
        final yValues = <double>[];
        final hueValues = <dynamic>[];

        // Собираем только пары, где оба значения не null
        final minLength = xCol.data.length < yCol.data.length
            ? xCol.data.length
            : yCol.data.length;

        for (int k = 0; k < minLength; k++) {
          final x = xCol.data[k];
          final y = yCol.data[k];
          if (x == null || y == null) continue;

          if (hueColumn != null){
            final hue = hueColumn.data[k];
            if (hue == null) continue; // пропускаем тройные null (x, y, hue)
            if (hueIsNumeric) {
              hueValues.add(hue as double);
            } else {
              hueValues.add(hue.toString());
            }
          }
          xValues.add(x);
          yValues.add(y);
        }

        // Применяем сэмплирование, если нужно
        final maxPoints = state.maxPoints > 0 ? state.maxPoints : 5000;
        List<double> sampledX = xValues;
        List<double> sampledY = yValues;
        List<dynamic> sampledHue = hueValues;

        if (xValues.length > maxPoints) {
          final indices = List.generate(xValues.length, (i) => i);
          // Метод sample (предположительно, расширение для List) случайно выбирает maxPoints элементов
          final sampledIndices = indices.sample(maxPoints);
          sampledX = sampledIndices.map((i) => xValues[i]).toList();
          sampledY = sampledIndices.map((i) => yValues[i]).toList();
          if (hueColumn != null) {
            sampledHue = sampledIndices.map((i) => hueValues[i]).toList();
          }
        }

        return PairPlotCellData(
          xColumn: columnNames[i],
          yColumn: columnNames[j],
          xValues: sampledX,
          yValues: sampledY,
          hueValues: hueColumn != null ? sampledHue : null,
          hueIsNumeric: hueIsNumeric,
        );
      });
    });

    return PairPlotDataCalculator._(
      PairPlotData(columnNames: columnNames, matrix: matrix),
      false,
      null,
    );
  }
}