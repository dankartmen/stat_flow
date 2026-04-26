/// {@template pairplot_cell_data}
/// Данные для одной ячейки матрицы Pair Plot.
/// 
/// Содержит значения для двух колонок (или одну и ту же колонку для диагонали).
/// Для диагональных ячеек используется для построения гистограммы.
/// Для недиагональных — для построения scatter plot.
/// {@endtemplate}
class PairPlotCellData {
  /// Имя колонки по оси X.
  final String xColumn;

  /// Имя колонки по оси Y.
  final String yColumn;

  /// Значения по оси X.
  final List<double> xValues;

  /// Значения по оси Y.
  final List<double> yValues;

  /// Значения цветовой колонки, соответствующие точкам (может быть null, если окраска не используется).
  /// Тип элементов — dynamic, так как может быть double (числовая шкала) или String (категория).
  final List<dynamic>? hueValues;
  
  /// Является ли цветовая колонка числовой (иначе категориальная/текстовая).
  /// Используется для выбора цветовой карты и легенды.
  final bool hueIsNumeric;

  /// {@macro pairplot_cell_data}
  PairPlotCellData({
    required this.xColumn,
    required this.yColumn,
    required this.xValues,
    required this.yValues,
    this.hueValues,
    this.hueIsNumeric = false,
  });

  /// Является ли ячейка диагональной (X == Y).
  /// Если true, то scatter plot не строится, вместо него — гистограмма или текст.
  bool get isDiagonal => xColumn == yColumn;
}

/// {@template pairplot_data}
/// Данные для всей матрицы Pair Plot.
/// 
/// Содержит список имён колонок и двумерную матрицу ячеек,
/// где matrix[i][j] соответствует данным для колонок i и j.
/// {@endtemplate}
class PairPlotData {
  /// Список имён колонок в порядке отображения.
  final List<String> columnNames;

  /// Двумерная матрица ячеек: [строка][столбец].
  final List<List<PairPlotCellData>> matrix;

  /// {@macro pairplot_data}
  PairPlotData({
    required this.columnNames,
    required this.matrix,
  });
}