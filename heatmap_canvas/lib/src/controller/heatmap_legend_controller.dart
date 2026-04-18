import 'package:flutter/foundation.dart';
import '../model/hover_range.dart';

/// Контроллер для управления состоянием легенды и синхронизации с тепловой картой.
///
/// Позволяет:
/// - Отслеживать текущий диапазон/значение под курсором на легенде.
/// - Программно устанавливать выделение.
/// - Сбрасывать выделение.
class HeatmapLegendController extends ChangeNotifier {
  HoverRange? _hoverRange;

  /// Текущий диапазон или значение под курсором на легенде.
  HoverRange? get hoverRange => _hoverRange;

  /// Устанавливает новое значение диапазона и уведомляет слушателей.
  void setHoverRange(HoverRange? range) {
    if (_hoverRange == range) return;
    _hoverRange = range;
    notifyListeners();
  }

  /// Сбрасывает выделение.
  void clear() => setHoverRange(null);

  @override
  void dispose() {
    _hoverRange = null;
    super.dispose();
  }
}