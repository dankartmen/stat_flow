import 'bar_chart/bar_plugin.dart';
import 'boxplot/boxplot_plugin.dart';
import 'chart_registry.dart';
import 'heatmap/heatmap_plugin.dart';
import 'histogram/histogram_plugin.dart';
import 'line_chart/line_plugin.dart';
import 'scatterplot/scatter_plugin.dart';

/// {@template register_charts}
/// Регистрирует все доступные плагины графиков в системе
/// 
/// Вызывается при инициализации приложения для подключения:
/// - Тепловой карты ([HeatmapPlugin])
/// - Гистограммы ([HistogramPlugin])
/// - Ящика с усами ([BoxPlotPlugin])
/// 
/// Плагины регистрируются в [ChartRegistry] для последующего
/// динамического создания графиков по типу.
/// {@endtemplate}
void registerCharts() {
  ChartRegistry.register(HeatmapPlugin());
  ChartRegistry.register(HistogramPlugin());
  ChartRegistry.register(BoxPlotPlugin());
  ChartRegistry.register(ScatterPlugin());
  ChartRegistry.register(LinePlugin());
  ChartRegistry.register(BarPlugin());
}