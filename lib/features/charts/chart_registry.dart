import 'package:stat_flow/features/charts/chart_type.dart';

import 'chart_plugin.dart';

/// {@template chart_registry}
/// Реестр плагинов графиков (реализация паттерна Registry)
/// 
/// Отвечает за:
/// - Регистрацию плагинов различных типов графиков
/// - Хранение зарегистрированных плагинов в статической карте
/// - Предоставление доступа к плагинам по типу графика
/// 
/// Используется для динамического создания графиков и их элементов
/// управления без жесткой привязки к конкретным реализациям.
/// {@endtemplate}
class ChartRegistry {
  /// Внутренняя карта зарегистрированных плагинов
  static final Map<ChartType, ChartPlugin> _plugins = {};

  /// Регистрирует новый плагин в системе
  /// 
  /// Принимает:
  /// - [plugin] — экземпляр плагина для регистрации
  /// 
  /// Особенности:
  /// - Ключом служит [ChartPlugin.type]
  /// - При регистрации плагина с уже существующим типом,
  ///   новый плагин заменяет старый
  static void register(ChartPlugin plugin) {
    _plugins[plugin.type] = plugin;
  }

  /// Возвращает плагин по типу графика
  /// 
  /// Принимает:
  /// - [type] — тип графика (строка)
  /// 
  /// Возвращает:
  /// - [ChartPlugin] — зарегистрированный плагин
  /// 
  /// Выбрасывает:
  /// - [Exception] — если плагин с указанным типом не найден
  static ChartPlugin get(ChartType type) {
    final plugin = _plugins[type];
    if (plugin == null) {
      throw Exception("График не зарегистрирован: $type");
    }
    return plugin;
  }

  /// Возвращает список всех зарегистрированных типов графиков
  static List<ChartType> get types => _plugins.keys.toList();
}