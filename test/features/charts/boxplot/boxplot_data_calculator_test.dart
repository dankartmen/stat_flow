import 'package:flutter_test/flutter_test.dart';
import 'package:stat_flow/core/dataset/dataset.dart';
import 'package:stat_flow/features/charts/boxplot/boxplot_data_calculator.dart';
import 'package:stat_flow/features/charts/boxplot/boxplot_state.dart';

void main() {
  group('BoxPlotDataCalculator', () {
    test('пустое состояние возвращает пустые данные', () {
      final dataset = Dataset(name: 'test', columns: []);
      final state = BoxPlotState();
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      expect(result.seriesData, isEmpty);
      expect(result.isSampled, false);
      expect(result.totalCount, 0);
    });

    test('если столбец не выбран, возвращаются пустые данные', () {
      final numericCol = NumericColumn('num', [1.0, 2.0, 3.0]);
      final dataset = Dataset(name: 'test', columns: [numericCol]);
      final state = BoxPlotState(columnName: null);
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      expect(result.seriesData, isEmpty);
    });

    test('числовой столбец без группировки возвращает один ряд', () {
      final values = [5.0, 2.0, 8.0, 1.0, 9.0];
      final numericCol = NumericColumn('num', values);
      final dataset = Dataset(name: 'test', columns: [numericCol]);
      final state = BoxPlotState(columnName: 'num', maxPoints: 100);
      
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 1);
      expect(result.seriesData.first.groupName, 'num');
      expect(result.seriesData.first.values, containsAll(values));
      expect(result.isSampled, false);
      expect(result.totalCount, values.length);
    });

    test('группировка по категориальному столбцу дает правильное количество рядов', () {
      final numericData = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
      final groupData = ['A', 'A', 'B', 'B', 'C', 'C'];
      final numCol = NumericColumn('values', numericData);
      final catCol = CategoricalColumn('groups', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, catCol]);
      final state = BoxPlotState(
        columnName: 'values',
        groupByColumn: 'groups',
        maxPoints: 100,
      );
      
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 3);
      final groupNames = result.seriesData.map((s) => s.groupName).toSet();
      expect(groupNames, {'A', 'B', 'C'});
      
      // Проверяем значения в каждой группе
      final seriesA = result.seriesData.firstWhere((s) => s.groupName == 'A');
      expect(seriesA.values, [1.0, 2.0]);
      final seriesB = result.seriesData.firstWhere((s) => s.groupName == 'B');
      expect(seriesB.values, [3.0, 4.0]);
      final seriesC = result.seriesData.firstWhere((s) => s.groupName == 'C');
      expect(seriesC.values, [5.0, 6.0]);
      
      expect(result.isSampled, false);
      expect(result.totalCount, 6);
    });

    test('сэмплирование уменьшает количество точек и устанавливает флаг isSampled', () {
      // Создаём большой набор данных, чтобы превысить maxPoints
      final numericData = List.generate(2000, (i) => i.toDouble());
      final groupData = List.generate(2000, (i) => i % 2 == 0 ? 'Even' : 'Odd');
      final numCol = NumericColumn('values', numericData);
      final catCol = CategoricalColumn('groups', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, catCol]);
      final state = BoxPlotState(
        columnName: 'values',
        groupByColumn: 'groups',
        maxPoints: 100,
      );
      
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 2);
      expect(result.isSampled, true);
      expect(result.totalCount, 2000);
      
      // Проверяем, что каждая серия содержит <= maxPoints точек
      for (final series in result.seriesData) {
        expect(series.values.length, lessThanOrEqualTo(state.maxPoints));
      }
    });

    test('группировка с текстовым столбцом работает', () {
      final numericData = [10.0, 20.0, 30.0, 40.0];
      final groupData = ['X', 'Y', 'X', 'Y'];
      final numCol = NumericColumn('values', numericData);
      final textCol = TextColumn('groups', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, textCol]);
      final state = BoxPlotState(
        columnName: 'values',
        groupByColumn: 'groups',
        maxPoints: 100,
      );
      
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 2);
      final seriesX = result.seriesData.firstWhere((s) => s.groupName == 'X');
      expect(seriesX.values, [10.0, 30.0]);
      final seriesY = result.seriesData.firstWhere((s) => s.groupName == 'Y');
      expect(seriesY.values, [20.0, 40.0]);
    });

    test('игнорирует null значения как в числовом, так и в группирующем столбцах', () {
      final numericData = [1.0, null, 3.0, 4.0, null];
      final groupData = ['A', 'A', null, 'B', 'B'];
      final numCol = NumericColumn('values', numericData);
      final catCol = CategoricalColumn('groups', groupData);
      final dataset = Dataset(name: 'test', columns: [numCol, catCol]);
      final state = BoxPlotState(
        columnName: 'values',
        groupByColumn: 'groups',
        maxPoints: 100,
      );
      
      final result = BoxPlotDataCalculator.calculate(dataset: dataset, state: state);
      
      expect(result.seriesData.length, 2); // A и B
      final seriesA = result.seriesData.firstWhere((s) => s.groupName == 'A');
      expect(seriesA.values, [1.0]); // только одна валидная пара
      final seriesB = result.seriesData.firstWhere((s) => s.groupName == 'B');
      expect(seriesB.values, [4.0]);
      expect(result.totalCount, 2); // всего валидных пар
    });
  });
}