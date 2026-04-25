import 'package:stat_flow/core/dataset/dataset.dart';
import '../statistics/statistical_tests.dart';

/// {@template insight}
/// Инсайт (аналитический вывод) на основе статистического анализа данных.
/// 
/// Содержит текстовое описание, тип значимости и уровень значимости (p-value).
/// Используется для отображения ключевых наблюдений в панели аналитики.
/// {@endtemplate}
class Insight {
  /// Текстовое описание инсайта (на русском языке).
  final String text;
  
  /// Тип значимости: сильный, умеренный, слабый или информационный.
  final InsightType type;
  
  /// Уровень значимости (p-value), если применимо. null для информационных инсайтов.
  final double? significance;

  /// {@macro insight}
  Insight({required this.text, required this.type, this.significance});
}

/// {@template insight_type}
/// Тип значимости статистического вывода.
/// 
/// - [strong] — сильная значимость (p < 0.01)
/// - [moderate] — умеренная значимость (p < 0.05)
/// - [weak] — слабая значимость (p < 0.1 или незначимая корреляция)
/// - [info] — информационное сообщение без статистической оценки
/// {@endtemplate}
enum InsightType { strong, moderate, weak, info }

/// {@template insight_generator}
/// Генератор аналитических инсайтов на основе датасета.
/// 
/// Анализирует связи между целевой переменной (DEATH_EVENT) и признаками:
/// - Для числовых признаков: t-тест и корреляция Пирсона.
/// - Для категориальных признаков: χ²-тест независимости.
/// - Также вычисляет медиану времени наблюдения.
/// 
/// Результат — список [Insight] с текстовыми выводами и оценкой значимости.
/// 
/// TODO: Добавить поддержку других целевых переменных
/// TODO: Расширить анализ на многомерные взаимосвязи
/// {@endtemplate}
class InsightGenerator {
  /// Генерирует список инсайтов для заданного датасета.
  ///
  /// Принимает:
  /// - [dataset] — датасет для анализа (должен содержать колонки 'time' и целевую переменную 'DEATH_EVENT' или с подстрокой 'death'/'event').
  ///
  /// Возвращает:
  /// - список [Insight], отсортированный по возрастанию p-value (наиболее значимые первыми).
  ///
  /// Если целевая переменная не найдена, возвращается информационный инсайт об ошибке.
  static List<Insight> generate(Dataset dataset) {
    final insights = <Insight>[];

    // Ищем колонку с целевой переменной по имени (death/event)
    final targetCol = _findTargetColumn(dataset);
    if (targetCol == null) {
      insights.add(Insight(
        text: 'Целевая переменная (DEATH_EVENT) не найдена',
        type: InsightType.info,
      ));
      return insights;
    }

    // Извлекаем бинарный вектор событий (0/1) независимо от типа колонки
    final List<int> targetVector = _extractBinaryTarget(targetCol);

    // Анализ числовых колонок (исключаем колонку 'time' — она обрабатывается отдельно)
    for (final col in dataset.numericColumns) {
      if (col.name == 'time') continue;

      final groups = _splitByTargetNumeric(col.data, targetVector);
      // Проверяем, что в каждой группе есть хотя бы 2 наблюдения для t-теста
      if (groups[0].length > 1 && groups[1].length > 1) {
        final tTest = StatisticalTests.independentTTest(
          group1: groups[0],
          group2: groups[1],
        );

        if (tTest.isSignificant) {
          final direction = tTest.meanDiff > 0 ? 'выше' : 'ниже';
          insights.add(Insight(
            text: '${col.name}: значимое различие между группами (p=${tTest.pValue.toStringAsFixed(3)}), '
                'у умерших показатель $direction на ${tTest.meanDiff.abs().toStringAsFixed(2)}',
            type: tTest.pValue < 0.01 ? InsightType.strong : InsightType.moderate,
            significance: tTest.pValue,
          ));
        }

        final correlation = StatisticalTests.pearsonCorrelation(
          col.data.whereType<double>().toList(),
          targetVector.map((v) => v.toDouble()).toList(),
        );
        if (correlation.abs() > 0.2) {
          insights.add(Insight(
            text: '${col.name}: корреляция с исходом ${correlation.toStringAsFixed(2)}',
            type: correlation.abs() > 0.4 ? InsightType.moderate : InsightType.weak,
          ));
        }
      }
    }

    // Анализ категориальных колонок
    for (final col in dataset.categoricalColumns) {
      final crossTable = _buildCrossTable(col.data, targetVector);
      // Для χ² теста нужна таблица 2×2
      if (crossTable.length == 2 && crossTable[0].length == 2) {
        final chi2 = StatisticalTests.chiSquaredTest(crossTable);
        if (chi2 > 3.84) { // критическое значение для p=0.05 с 1 степенью свободы
          insights.add(Insight(
            text: '${col.name}: статистически значимая связь с исходом (χ²=${chi2.toStringAsFixed(1)})',
            type: chi2 > 10.83 ? InsightType.strong : InsightType.moderate, // p<0.001 и p<0.001? 10.83≈0.001
          ));
        }
      }
    }

    // Анализ времени до события (добавляем в начало как информационный инсайт)
    final timeCol = dataset.column('time');
    if (timeCol is NumericColumn) {
      insights.insert(0, Insight(
        text: 'Медиана времени наблюдения: ${_calculateMedian(timeCol.data)} дней',
        type: InsightType.info,
      ));
    }

    // Сортируем инсайты по значимости (p-value по возрастанию)
    insights.sort((a, b) => (a.significance ?? 1.0).compareTo(b.significance ?? 1.0));
    return insights;
  }

  /// Поиск колонки с целевой переменной по имени.
  ///
  /// Принимает:
  /// - [dataset] — датасет для поиска.
  ///
  /// Возвращает:
  /// - первую колонку, чьё имя содержит подстроку 'death' или 'event' (без учёта регистра).
  /// - null, если такая колонка не найдена.
  static DataColumn? _findTargetColumn(Dataset dataset) {
    for (final col in dataset.columns) {
      if (col.name.toLowerCase().contains('death') ||
          col.name.toLowerCase().contains('event')) {
        return col;
      }
    }
    return null;
  }

  /// Извлекает бинарный вектор (0/1) из произвольной колонки.
  ///
  /// Принимает:
  /// - [col] — колонка данных (числовая, строковая, категориальная).
  ///
  /// Возвращает:
  /// - список целых чисел (0/1), где 1 соответствует событию (смерть/отказ).
  ///
  /// Правила преобразования:
  /// - Числовые значения: 1.0 → 1, иначе 0.
  /// - Строковые значения: '1' или 'true' (независимо от регистра) → 1, иначе 0.
  /// - null → 0.
  static List<int> _extractBinaryTarget(DataColumn col) {
    final List<int> result = [];
    for (final val in col.data) {
      if (val == null) {
        result.add(0);
      } else if (val is double || val is int) {
        result.add(val == 1.0 ? 1 : 0);
      } else if (val is String) {
        result.add(val == '1' || val.toLowerCase() == 'true' ? 1 : 0);
      } else {
        result.add(0);
      }
    }
    return result;
  }

  /// Разделяет числовые значения на две группы по бинарному вектору событий.
  ///
  /// Принимает:
  /// - [values] — список числовых значений (может содержать null).
  /// - [target] — бинарный вектор (0/1) той же длины.
  ///
  /// Возвращает:
  /// - список из двух списков: index 0 — группа с target=0, index 1 — группа с target=1.
  ///   null-значения в values игнорируются.
  static List<List<double>> _splitByTargetNumeric(List<double?> values, List<int> target) {
    final group0 = <double>[];
    final group1 = <double>[];
    for (int i = 0; i < values.length && i < target.length; i++) {
      final val = values[i];
      if (val == null) continue;
      if (target[i] == 0) {
        group0.add(val);
      } else {
        group1.add(val);
      }
    }
    return [group0, group1];
  }

  /// Строит таблицу сопряжённости между категориальной колонкой и бинарным таргетом.
  ///
  /// Принимает:
  /// - [colData] — список категорий (строки, может содержать null).
  /// - [target] — бинарный вектор (0/1).
  ///
  /// Возвращает:
  /// - двумерный список вида [[count_0_cat0, count_0_cat1, ...], [count_1_cat0, ...]]
  ///   где первая строка — таргет=0, вторая — таргет=1.
  ///
  /// Примечание: результирующая таблица может иметь более 2 столбцов, но для χ² теста
  /// используется только случай с двумя категориями.
  static List<List<int>> _buildCrossTable(List<String?> colData, List<int> target) {
    final categories = colData.whereType<String>().toSet().toList();
    final table = List.generate(2, (_) => List.filled(categories.length, 0));
    for (int i = 0; i < colData.length && i < target.length; i++) {
      final val = colData[i];
      if (val == null) continue;
      final catIdx = categories.indexOf(val);
      if (catIdx == -1) continue;
      final t = target[i];
      if (t == 0 || t == 1) {
        table[t][catIdx]++;
      }
    }
    return table;
  }

  /// Вычисляет медиану списка числовых значений (игнорируя null).
  ///
  /// Принимает:
  /// - [data] — список значений (может содержать null).
  ///
  /// Возвращает:
  /// - медианное значение (double). Если список пуст, возвращает 0.
  static double _calculateMedian(List<double?> data) {
    final sorted = data.whereType<double>().toList()..sort();
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}