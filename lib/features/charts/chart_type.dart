enum ChartType {
  heatmap('Тепловая карта'),
  scatter('Диаграмма рассеяния'),
  histogram('Гистограмма'),
  boxplot('Ящик с усами'),
  linechart('Линейный график'),
  barchart('Столбчатая диаграмма'),
  pairplotchart('Матрица диаграмм рассеяния'),
  kaplanmeier('Кривые Каплан-Мейера');
  final String name;
  const ChartType(this.name);
}