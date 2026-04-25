// lib/features/statistics/column_statistics.dart
import 'package:flutter/material.dart';

/// Тип данных колонки: числовой, категориальный, текстовый или дата/время.
enum ColumnType { numeric, categorical, text, datetime }

/// {@template column_statistics}
/// Статистические метаданные для одной колонки датасета.
/// Содержит как общие поля (количество, пропуски), так и специфичные в зависимости от типа колонки.
/// {@endtemplate}
class ColumnStatistics {
  /// Название колонки.
  final String columnName;

  /// Тип данных колонки (определяется автоматически при загрузке).
  final ColumnType columnType;

  /// Общее количество элементов в колонке (включая пустые/null).
  final int totalCount;

  /// Количество валидных (не null) элементов.
  final int validCount;

  /// Количество пустых (null) элементов.
  final int emptyCount;

  // Числовые метрики (только для numeric)
  final double? mean;
  final double? std;
  final double? min;
  final double? max;
  final double? q1;
  final double? median;
  final double? q3;

  // Категориальные / текстовые метрики
  final int? uniqueValues;
  final String? mostFrequent;
  final int? mostFrequentCount;
  final int? minLength;
  final int? maxLength;

  // Метрики для дат
  final DateTime? minDate;
  final DateTime? maxDate;
  final int? daysRange;

  /// {@macro column_statistics}
  ColumnStatistics({
    required this.columnName,
    required this.columnType,
    required this.totalCount,
    required this.validCount,
    required this.emptyCount,
    this.mean,
    this.std,
    this.min,
    this.max,
    this.q1,
    this.median,
    this.q3,
    this.uniqueValues,
    this.mostFrequent,
    this.mostFrequentCount,
    this.minLength,
    this.maxLength,
    this.minDate,
    this.maxDate,
    this.daysRange,
  });

  /// Процент пропущенных (empty) значений относительно общего количества.
  /// Если [totalCount] == 0, возвращает 0.
  double get emptyPercentage => totalCount == 0 ? 0 : (emptyCount / totalCount) * 100;
}