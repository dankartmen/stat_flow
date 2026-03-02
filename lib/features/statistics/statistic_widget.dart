import 'package:flutter/material.dart';
import '../statistics/statistic_result.dart';

/// {@template statistic_widget}
/// Виджет для отображения статистических данных в карточке
/// {@endtemplate}
class StatisticWidget extends StatelessWidget{
  /// Результат статистических вычислений для отображения.
  final StatisticResult statisticResult;

  const StatisticWidget({
    super.key, 
    required this.statisticResult
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Небольшая тень для эффекта глубины
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Скругленные углы карточки
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Статистика данных',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            _buildStatRow(
              'Общее количество значений',
              statisticResult.totalCount.toString(),
              Icons.numbers,
            ),
            _buildStatRow(
              'Валидные значения',
              statisticResult.validCount.toString(),
              Icons.check_circle,
              color: Colors.green,
            ),
            _buildStatRow(
              'Пустые значения',
              statisticResult.emptyCount.toString(),
              Icons.cancel,
              color: Colors.red,
            ),
            const Divider(thickness: 1),
            _buildStatRow(
              'Минимум',
              _formatNumber(statisticResult.min),
              Icons.arrow_downward,
              color: Colors.blue,
            ),
            _buildStatRow(
              'Максимум',
              _formatNumber(statisticResult.max),
              Icons.arrow_upward,
              color: Colors.orange,
            ),
            _buildStatRow(
              'Среднее арифметическое',
              _formatNumber(statisticResult.mean),
              Icons.calculate,
              color: Colors.purple,
            ),
            _buildStatRow(
              'Медиана',
              _formatNumber(statisticResult.median),
              Icons.show_chart,
              color: Colors.teal,
            ),
            _buildStatRow(
              'Стандартное отклонение',
              _formatNumber(statisticResult.std),
              Icons.analytics,
              color: Colors.brown,
            ),
          ],
        ),
      ),
    );
  }

  /// Строит строку статистики с иконкой, названием и значением.
  ///
  /// [label] - название показателя
  /// [value] - отформатированное значение
  /// [icon] - иконка для визуализации
  /// [color] - цвет иконки и фона значения (по умолчанию серый)
  Widget _buildStatRow(String label, String value, IconData icon, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Форматирует числовое значение для отображения.
  ///
  /// Возвращает '-' для null значений.
  /// Для целых чисел не показывает десятичную часть.
  /// Для дробных чисел показывает 2 знака после запятой.
  String _formatNumber(num? value) {
    if (value == null) return '-';
    
    if (value is int) {
      return value.toString();
    }
    
    return value.toStringAsFixed(2);
  }
}