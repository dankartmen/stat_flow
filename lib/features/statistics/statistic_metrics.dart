/// Битовые флаги для типов колонок, используются для проверки совместимости статистических метрик.
class ColumnTypeFlags {
  /// Пустой флаг (нет типа).
  static const int none = 0;

  /// Флаг для числовых колонок.
  static const int numeric = 1 << 0;

  /// Флаг для категориальных колонок.
  static const int categorical = 1 << 1;

  /// Флаг для текстовых колонок.
  static const int text = 1 << 2;

  /// Флаг для колонок с датами.
  static const int datetime = 1 << 3;

  /// Комбинированный флаг для категориальных и текстовых колонок (строковые типы).
  static const int categoricalText = categorical | text;

  /// Комбинированный флаг для всех типов колонок.
  static const int all = numeric | categorical | text | datetime;

  /// Хранимое значение битовой маски.
  final int value;

  /// Создаёт экземпляр [ColumnTypeFlags] с заданной битовой маской.
  const ColumnTypeFlags(this.value);

  /// Проверяет, установлен ли флаг [flag] в текущей маске.
  bool has(int flag) => (value & flag) != 0;
}

/// Перечисление доступных статистических метрик.
/// Каждая метрика содержит человекочитаемый ярлык и битовую маску допустимых типов колонок.
enum StatisticMetric {
  count('Кол-во', ColumnTypeFlags.all),
  missing('Пропуски%', ColumnTypeFlags.all),

  mean('Среднее', ColumnTypeFlags.numeric),
  std('Стд.откл.', ColumnTypeFlags.numeric),
  min('Мин', ColumnTypeFlags.numeric | ColumnTypeFlags.datetime),
  max('Макс', ColumnTypeFlags.numeric | ColumnTypeFlags.datetime),
  q1('25%', ColumnTypeFlags.numeric),
  median('50%', ColumnTypeFlags.numeric),
  q3('75%', ColumnTypeFlags.numeric),

  unique('Уникальных', ColumnTypeFlags.categoricalText),
  top('Топ-1', ColumnTypeFlags.categoricalText),
  topFreq('Частота топ-1', ColumnTypeFlags.categoricalText),

  minLength('Мин. длина', ColumnTypeFlags.text),
  maxLength('Макс. длина', ColumnTypeFlags.text),

  minDate('Мин. дата', ColumnTypeFlags.datetime),
  maxDate('Макс. дата', ColumnTypeFlags.datetime),
  daysRange('Дней между', ColumnTypeFlags.datetime);

  /// Человекочитаемое название метрики (для отображения в UI).
  final String label;

  /// Битовый флаг, определяющий, для каких типов колонок применима эта метрика.
  final int allowedTypes;

  const StatisticMetric(this.label, this.allowedTypes);
}