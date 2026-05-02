import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/image_api_service.dart';

/// {@template comparison_dialog}
/// Диалог сравнения нескольких экспериментов по классификации изображений.
/// Отображает:
/// - Таблицу гиперпараметров (количество слоёв, фильтры, оптимизатор, эпохи)
/// - Таблицу метрик (train/val/test accuracy и loss)
/// - Графики обучения каждого эксперимента (если доступны)
/// 
/// Позволяет наглядно сопоставить результаты разных моделей,
/// обученных на одном датасете.
/// {@endtemplate}
class ComparisonDialog extends StatefulWidget {
  /// Список идентификаторов экспериментов для сравнения.
  final List<String> experimentIds;

  /// Сервис API для загрузки деталей экспериментов.
  final ImageApiService api;

  /// {@macro comparison_dialog}
  const ComparisonDialog({
    super.key,
    required this.experimentIds,
    required this.api,
  });

  @override
  State<ComparisonDialog> createState() => _ComparisonDialogState();
}

/// {@template comparison_dialog_state}
/// Состояние диалога сравнения экспериментов.
/// Управляет загрузкой деталей экспериментов, отображением таблиц и графиков.
/// {@endtemplate}
class _ComparisonDialogState extends State<ComparisonDialog> {
  /// Загруженные детали экспериментов.
  List<ExperimentDetail>? _details;

  /// Флаг загрузки данных.
  bool _loading = true;

  /// Сообщение об ошибке (если есть).
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails(); // Загружаем данные при инициализации
  }

  /// Загружает детали всех выбранных экспериментов параллельно.
  /// При успехе обновляет [_details], при ошибке сохраняет сообщение в [_error].
  Future<void> _loadDetails() async {
    try {
      // Параллельная загрузка деталей всех экспериментов
      final results = await Future.wait(
        widget.experimentIds.map((id) => widget.api.getExperimentDetail(id)),
      );
      setState(() {
        _details = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сравнение экспериментов'),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text('Ошибка: $_error')
              : _buildComparison(context, _details!),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  /// Строит основное содержимое диалога: таблицы гиперпараметров, метрик и графики.
  ///
  /// Принимает:
  /// - [context] – контекст сборки
  /// - [details] – список деталей экспериментов
  ///
  /// Возвращает [SingleChildScrollView] с тремя секциями.
  Widget _buildComparison(BuildContext context, List<ExperimentDetail> details) {
    // Список ключей метрик для отображения
    final metricKeys = [
      'train_accuracy', 'val_accuracy', 'test_accuracy',
      'train_loss', 'val_loss', 'test_loss'
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Секция гиперпараметров
          const Text('Параметры моделей:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DataTable(
            columnSpacing: 10,
            columns: [
              const DataColumn(label: Text('Характеристика')),
              ...details.map(
                (d) => DataColumn(
                  label: Text(d.experimentId.substring(0, 8)),
                ),
              ),
            ],
            rows: [
              _hyperparamRow(
                'Слоёв',
                details.map((d) => d.hyperparams.convLayers.toString()).toList(),
              ),
              _hyperparamRow(
                'Фильтры',
                details.map((d) => d.hyperparams.filters.toString()).toList(),
              ),
              _hyperparamRow(
                'Оптимизатор',
                details.map((d) => d.hyperparams.optimizer).toList(),
              ),
              _hyperparamRow(
                'Эпох',
                details.map((d) => d.hyperparams.epochs.toString()).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Секция метрик
          const Text('Метрики:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DataTable(
            columnSpacing: 10,
            columns: [
              const DataColumn(label: Text('Метрика')),
              ...details.map(
                (d) => DataColumn(
                  label: Text(d.experimentId.substring(0, 8)),
                ),
              ),
            ],
            rows: metricKeys.map((key) {
              return DataRow(cells: [
                DataCell(Text(key.replaceAll('_', ' '))),
                ...details.map((d) {
                  final val = d.metrics?[key];
                  return DataCell(
                    Text(val != null ? val.toStringAsFixed(4) : 'N/A'),
                  );
                }),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Секция графиков обучения
          const Text('Графики обучения:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: details.map((d) {
              if (d.plotBase64 == null) return const SizedBox.shrink();
              return Column(
                children: [
                  Text(d.experimentId.substring(0, 8),
                      style: const TextStyle(fontSize: 12)),
                  Image.memory(
                    base64Decode(d.plotBase64!),
                    width: 550,
                    fit: BoxFit.contain,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Вспомогательный метод для создания строки таблицы с гиперпараметром.
  ///
  /// Принимает:
  /// - [label] – название параметра.
  /// - [values] – список значений (по одному на эксперимент).
  ///
  /// Возвращает [DataRow] для вставки в [DataTable].
  DataRow _hyperparamRow(String label, List<String> values) {
    return DataRow(cells: [
      DataCell(Text(label)),
      ...values.map((v) => DataCell(Text(v))),
    ]);
  }
}