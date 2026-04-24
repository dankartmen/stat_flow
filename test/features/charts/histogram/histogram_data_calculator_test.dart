import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/charts/histogram/histogram_data_calculator.dart';
import 'package:stat_flow/features/charts/histogram/histogram_state.dart';

void main() {
  group('HistogramDataCalculator', () {
    test('пустое состояние возвращает пустые данные', () {
      final dataset = Dataset(name: 'test', columns: []);
      final state = HistogramState();
      final result = HistogramDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData, isEmpty);
      expect(result.isSampled, false);
      expect(result.totalCount, 0);
    });

    test('числовой столбец без разбиения возвращает один ряд', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      final numCol = NumericColumn('num', values);
      final dataset = Dataset(name: 'test', columns: [numCol]);
      final state = HistogramState(columnName: 'num');

      final result = HistogramDataCalculator.calculate(dataset: dataset, state: state);

      expect(result.seriesData.length, 1);
      expect(result.seriesData.first.groupName, 'num');
      expect(result.seriesData.first.values, values);
      expect(result.totalCount, values.length);
    });

    test('разбиение по категориальному столбцу создает несколько рядов', () {
      final numericData = [5.0, 2.0, 8.0, 1.0, 9.0];
      final groupData = ['A', 'B', 'A', 'B', 'A'];
      final numCol = NumericColumn('values', numericData);
      final catCol = CategoricalColumn('groups', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, catCol]);
      final state = HistogramState(
        columnName: 'values',
        splitByColumn: 'groups',
      );

      final result = HistogramDataCalculator.calculate(dataset: dataset, state: state);

      expect(result.seriesData.length, 2);
      
      final seriesA = result.seriesData.firstWhere((s) => s.groupName == 'A');
      expect(seriesA.values, [5.0, 8.0, 9.0]);
      
      final seriesB = result.seriesData.firstWhere((s) => s.groupName == 'B');
      expect(seriesB.values, [2.0, 1.0]);
      expect(result.totalCount, 5);
    });

    test('разбиение игнорирует null значения в числовом или группирующем столбцах', () {
      // Тест проверяет корректную фильтрацию null-значений:
      // - Индекс 1: val = null, group = 'Y' — игнорируется
      // - Индекс 2: val = 3.0, group = null — игнорируется
      // - Индекс 4: val = null, group = 'Y' — игнорируется
      final numericData = [1.0, null, 3.0, 4.0, null];
      final groupData = ['X', 'Y', null, 'X', 'Y'];
      final numCol = NumericColumn('val', numericData);
      final textCol = TextColumn('grp', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, textCol]);
      final state = HistogramState(columnName: 'val', splitByColumn: 'grp');

      final result = HistogramDataCalculator.calculate(dataset: dataset, state: state);

      // Только группа X имеет валидные пары (val != null && group != null)
      expect(result.seriesData.length, 1);
      
      final seriesX = result.seriesData.firstWhere((s) => s.groupName == 'X');
      expect(seriesX.values, [1.0, 4.0]);
      expect(result.totalCount, 2); // две валидные пары (индексы 0 и 3)
      // Группа Y отсутствует, так как для неё нет ни одного не-null числового значения
    });

    test('разбиение с сэмплированием maxPoints (пока не реализовано, но totalCount верен)', () {
      // Примечание: В текущей реализации сэмплирование не делается для гистограммы,
      // так как гистограмма агрегирует данные в бины и хорошо работает с большими объёмами.
      // isSampled ожидаем false.
      final numericData = List.generate(2000, (i) => i.toDouble());
      final groupData = List.generate(2000, (i) => i % 2 == 0 ? 'Even' : 'Odd');
      final numCol = NumericColumn('big', numericData);
      final catCol = CategoricalColumn('parity', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, catCol]);
      final state = HistogramState(
        columnName: 'big',
        splitByColumn: 'parity',
        bins: 10,
      );

      final result = HistogramDataCalculator.calculate(dataset: dataset, state: state);

      expect(result.seriesData.length, 2);
      expect(result.totalCount, 2000);
      expect(result.isSampled, false); // сэмплирование не добавлено
    });
  });
}