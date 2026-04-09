/// Форматирует число для отображения в ячейках тепловой карты, используя компактное представление для больших чисел и экспоненциальное представление для очень маленьких чисел.
String formatHeatmapNumber(double value) {
  if (value == 0) return '0';
  final abs = value.abs();
  if (abs < 0.001) return value.toStringAsExponential(2);
  if (abs < 1) return value.toStringAsFixed(3);
  if (abs < 1000) return value.toStringAsFixed(2);
  if (abs < 1e6) return '${(value / 1000).toStringAsFixed(1)}K';
  if (abs < 1e9) return '${(value / 1e6).toStringAsFixed(1)}M';
  return '${(value / 1e9).toStringAsFixed(1)}B';
}