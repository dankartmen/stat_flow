enum ChartType {
  heatmap('Тепловая карта'),
  scatter('Диаграмма рассеяния'),
  histogram('Гистограмма'),
  boxplot('Ящик с усами');

  final String name;
  const ChartType(this.name);
}