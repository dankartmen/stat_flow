import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/charts/bar_chart/bar_data_calculator.dart';
import 'package:stat_flow/features/charts/bar_chart/bar_state.dart';

void main() {
  group('BarDataCalculator', () {
    test('empty state returns empty data', () {
      final dataset = Dataset(name: 'test', columns: []);
      final state = BarState();
      final result = BarDataCalculator.calculate(dataset: dataset, state: state);
      expect(result.seriesData, isEmpty);
      expect(result.isSampled, false);
    });

    test('numeric column produces histogram bins', () {
      final values = [1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
      final numericCol = NumericColumn('num', values.map((v) => v as double?).toList());
      final dataset = Dataset(name: 'test', columns: [numericCol]);
      final state = BarState(columnName: 'num', binCount: 3);
      
      final result = BarDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 1);
      expect(result.seriesData.first.groupName, 'Частота');
      expect(result.seriesData.first.bars.length, 3);
      // Проверяем, что сумма частот равна общему числу значений
      final total = result.seriesData.first.bars.fold(0.0, (sum, bar) => sum + bar.value);
      expect(total, values.length.toDouble());
    });

    test('categorical column without grouping produces frequency bars', () {
      final data = ['A', 'B', 'A', 'C', 'B', 'A', 'D', 'D'];
      final catCol = CategoricalColumn('cat', data);
      final dataset = Dataset(name: 'test', columns: [catCol]);
      final state = BarState(columnName: 'cat', maxCategories: 3, sortDescending: true);
      
      final result = BarDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 1);
      final bars = result.seriesData.first.bars;
      expect(bars.length, 3);
      // Проверяем сортировку по убыванию: A (3), B (2), D (2) -> C отброшена
      expect(bars[0].category, 'A');
      expect(bars[0].value, 3.0);
      expect(bars[1].category, anyOf('B', 'D'));
      expect(result.isSampled, true); // т.к. maxCategories=3, а всего 4
    });

    test('grouped categorical columns produce multiple series', () {
      final mainData = ['X', 'X', 'Y', 'Y', 'X'];
      final groupData = ['G1', 'G2', 'G1', 'G2', 'G1'];
      final mainCol = CategoricalColumn('main', mainData);
      final groupCol = CategoricalColumn('group', groupData);
      final dataset = Dataset(name: 'test', columns: [mainCol, groupCol]);
      final state = BarState(
        columnName: 'main',
        groupByColumn: 'group',
        maxCategories: 10,
      );
      
      final result = BarDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 2); // G1 и G2
      expect(result.seriesData.map((s) => s.groupName).toSet(), {'G1', 'G2'});
      
      // Проверяем данные для G1
      final g1Series = result.seriesData.firstWhere((s) => s.groupName == 'G1');
      final xBar = g1Series.bars.firstWhere((b) => b.category == 'X');
      final yBar = g1Series.bars.firstWhere((b) => b.category == 'Y');
      expect(xBar.value, 2.0); // два X в G1
      expect(yBar.value, 1.0);
    });

    test('stacked flag does not affect data calculation (only rendering)', () {
      // stacked влияет только на отображение, данные те же
      final mainData = ['A', 'A', 'B'];
      final groupData = ['G1', 'G2', 'G1'];
      final mainCol = CategoricalColumn('main', mainData);
      final groupCol = CategoricalColumn('group', groupData);
      final dataset = Dataset(name: 'test', columns: [mainCol, groupCol]);
      final state = BarState(
        columnName: 'main',
        groupByColumn: 'group',
      );
      
      final result = BarDataCalculator.calculate(dataset: dataset, state: state);
      // Результат должен быть таким же, как без stacked
      final stateNoStack = state.copyWith(stacked: false);
      final resultNoStack = BarDataCalculator.calculate(dataset: dataset, state: stateNoStack);
      
      expect(result.seriesData.length, resultNoStack.seriesData.length);
    });
  });
}