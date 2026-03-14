part of 'dataset.dart';

/// {@template dataset_typed_columns}
/// Расширение для типизированного доступа к колонкам датасета
/// {@endtemplate}
extension DatasetTypedColumns on Dataset {
  /// Возвращает числовую колонку по имени
  /// 
  /// Выбрасывает исключение, если колонка не является [NumericColumn]
  NumericColumn numeric(String name) {
    final col = column(name);

    if (col is! NumericColumn) {
      throw Exception("$name is not a NumericColumn");
    }

    return col;
  }
}

/// {@template dataset_columns}
/// Расширение для фильтрации колонок по типам
/// {@endtemplate}
extension DatasetColumns on Dataset {
  /// Все числовые колонки датасета
  List<NumericColumn> get numericColumns =>
      columns.whereType<NumericColumn>().toList();

  /// Все текстовые колонки датасета
  List<TextColumn> get textColumns =>
      columns.whereType<TextColumn>().toList();

  /// Все колонки даты/времени
  List<DateTimeColumn> get dateTimeColumns =>
      columns.whereType<DateTimeColumn>().toList();

  /// Все категориальные колонки
  List<CategoricalColumn> get categoricalColumns =>
      columns.whereType<CategoricalColumn>().toList();
}

/// {@template dataset_correlation}
/// Расширение для вычисления корреляционной матрицы датасета
/// {@endtemplate}
extension DatasetCorrelation on Dataset {
  /// Вычисляет матрицу корреляции Пирсона для всех числовых колонок
  CorrelationMatrix corr() {
    return CorrelationMatrix.fromDataset(this);
  }
}

/// {@template dataset_preview}
/// Расширение для получения предварительного просмотра датасета
/// {@endtemplate}
extension DatasetPreview on Dataset {
  /// Возвращает первые n строк датасета (по умолчанию 5)
  Dataset head([int n = 5]) {
    final newColumns = columns
        .map((c) => c.slice(0, n))
        .toList();

    return Dataset(
      name: name,
      columns: newColumns,
    );
  }
}

/// {@template dataset_select}
/// Расширение для выбора подмножества колонок
/// {@endtemplate}
extension DatasetSelect on Dataset {
  /// Возвращает новый датасет, содержащий только указанные колонки
  Dataset select(List<String> columnNames) {
    final selected = columns
        .where((c) => columnNames.contains(c.name))
        .toList();

    return Dataset(
      name: name,
      columns: selected,
    );
  }
}

/// {@template dataset_filter}
/// Расширение для фильтрации строк датасета по условию
/// {@endtemplate}
extension DatasetFilter on Dataset {
  /// Фильтрует строки датасета по предикату
  /// 
  /// Принимает функцию, которая получает [DatasetRow] и возвращает true
  /// для строк, которые должны остаться в результате.
  Dataset filter(bool Function(DatasetRow row) predicate) {
    final selectedRows = <int>[];

    for (int i = 0; i < rowCount; i++) {
      final row = DatasetRow(this, i);

      if (predicate(row)) {
        selectedRows.add(i);
      }
    }

    final newColumns = columns.map((col) => col.filterByIndices(selectedRows)).toList();
    return Dataset(
      name: name,
      columns: newColumns,
    );
  }
}

/// {@template numeric_column_stats}
/// Расширение для статистического анализа числовых колонок
/// {@endtemplate}
extension NumericColumnStats on NumericColumn {
  /// Возвращает полную статистику по колонке
  StatisticResult describe() {
    return StatisticCalculator().calculate(this);
  }

  /// Среднее арифметическое
  double? mean() => describe().mean;

  /// Медиана
  double? median() => describe().median;

  /// Стандартное отклонение
  double? std() => describe().std;

  /// Минимальное значение
  double? min() => describe().min;

  /// Максимальное значение
  double? max() => describe().max;
}

/// {@template row_getters}
/// Расширение для типизированного получения значений из строки
/// {@endtemplate}
extension RowGetters on DatasetRow {
  /// Возвращает значение как double? (для числовых колонок)
  double? getDouble(String column) => this[column] as double?;

  /// Возвращает значение как String? (для текстовых и категориальных колонок)
  String? getString(String column) => this[column] as String?;

  /// Возвращает значение как DateTime? (для колонок даты/времени)
  DateTime? getDate(String column) => this[column] as DateTime?;
}

/// {@template list_sampling}
/// Расширение для выборки данных при визуализации больших датасетов.
///
/// Используется для того, чтобы не передавать в графики и таблицы
/// слишком много точек и не блокировать UI при больших объемах данных.
/// {@endtemplate}
extension SamplingExtension<T> on List<T> {
  /// Возвращает не более [maxSamples] элементов, равномерно распределённых по списку.
  ///
  /// Всегда включает первый и последний элементы (если они существуют).
  List<T> sample(int maxSamples) {
    if (length <= maxSamples) return this;

    final step = (length - 1) / (maxSamples - 1);
    return List.generate(maxSamples, (i) {
      final index = (i * step).round().clamp(0, length - 1);
      return this[index];
    });
  }
}
