import '../../features/charts/heatmap/model/correlation_matrix.dart';
import '../../features/statistics/statistic_calculator.dart';
import '../../features/statistics/statistic_result.dart';
import 'correlation_matrix_builder.dart';

class Dataset {
  final String name;
  final List<DataColumn> columns;
  final Map<String, DataColumn> _columnMap;

  Dataset({
    required this.name,
    required this.columns,
  }) : _columnMap = {
      for(final c in columns) c.name: c
  };

  int get rowCount => columns.isEmpty ? 0 : columns.first.length;

  int get columnCount => columns.length;

  DataColumn? column(String name) => _columnMap[name];
  
}

extension DatasetTypedColumns on Dataset {

  NumericColumn numeric(String name) {
    final col = column(name);

    if (col is! NumericColumn) {
      throw Exception("$name is not a NumericColumn");
    }

    return col;
  }

}


abstract class DataColumn<T> {
  final String name;
  final List<T?> data;

  const DataColumn(this.name, this.data);

  
  int get length => data.length;

  T? operator [](int i) => data[i];

  DataColumn<T> copyWithData(List<T?> newData);

  DataColumn<T> slice(int start, int end) {
    return copyWithData(data.sublist(start, end));
  }

  DataColumn<T> filterByIndices(List<int> indices) {
    final result = <T?>[];

    for (final i in indices) {
      result.add(data[i]);
    }

    return copyWithData(result);
  }

  DataColumn<T> filter(bool Function(int index) predicate) {
    final result = <T?>[];

    for (int i = 0; i < data.length; i++) {
      if (predicate(i)) {
        result.add(data[i]);
      }
    }

    return copyWithData(result);
}
}

class NumericColumn extends DataColumn<double> {
  const NumericColumn(super.name, super.data);

  @override
  NumericColumn copyWithData(List<double?> newData) {
    return NumericColumn(name, newData);
  }
}

extension NumericColumnStats on NumericColumn {

  StatisticResult describe() {
    return StatisticCalculator().calculate(this);
  }

  double? mean() {
    return describe().mean;
  }

  double? median() {
    return describe().median;
  }

  double? std() {
    return describe().std;
  }

  double? min() {
    return describe().min;
  }

  double? max() {
    return describe().max;
  }

}

class TextColumn extends DataColumn<String> {
  const TextColumn(super.name, super.data);

  @override
  TextColumn copyWithData(List<String?> newData) {
    return TextColumn(name, newData);
  }
}

class DateTimeColumn extends DataColumn<DateTime> {
  const DateTimeColumn(super.name, super.data);

  @override
  DateTimeColumn copyWithData(List<DateTime?> newData) {
    return DateTimeColumn(name, newData);
  }
}

class CategoricalColumn extends DataColumn<String> {
  late final Map<String, int> _codes;
  late final List<int?> encoded;

  CategoricalColumn(String name, List<String?> data)
      : super(name, data) {

    final map = <String, int>{};
    int index = 0;

    encoded = data.map((v) {
      if (v == null) return null;

      return map.putIfAbsent(v, () => index++);
    }).toList();

    _codes = map;
  }

  @override
  CategoricalColumn copyWithData(List<String?> newData) {
    return CategoricalColumn(name, newData);
  }
}

extension DatasetColumns on Dataset {

  List<NumericColumn> get numericColumns =>
      columns.whereType<NumericColumn>().toList();

  List<TextColumn> get textColumns =>
      columns.whereType<TextColumn>().toList();

  List<DateTimeColumn> get dateTimeColumns =>
      columns.whereType<DateTimeColumn>().toList();

  List<CategoricalColumn> get categoricalColumns =>
      columns.whereType<CategoricalColumn>().toList();

}


extension DatasetCorrelation on Dataset {

  CorrelationMatrix corr() {
    return CorrelationMatrixBuilder
        .fromNumericColumns(numericColumns);
  }

}

extension DatasetPreview on Dataset {
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

extension DatasetSelect on Dataset {
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

extension DatasetFilter on Dataset {
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

class DatasetRow {

  final Dataset dataset;
  final int index;

  DatasetRow(this.dataset, this.index);

  dynamic operator [](String columnName) {

    final column = dataset.column(columnName);

    if (column == null) {
      throw Exception("Колонка '$columnName' не найдена");
    }

    return column[index];
  }
}

extension RowGetters on DatasetRow {

  double? getDouble(String column) => this[column] as double?;

  String? getString(String column) => this[column] as String?;

  DateTime? getDate(String column) => this[column] as DateTime?;
}