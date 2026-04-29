import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/services/image_api_service.dart';

/// {@template experiment_detail_dialog}
/// Диалог с подробной информацией об эксперименте.
/// Отображает метрики (train/val/test accuracy и loss) и график обучения.
/// Предоставляет кнопки для скачивания модели и архива.
/// {@endtemplate}
class ExperimentDetailDialog extends StatelessWidget {
  /// Детальная информация об эксперименте.
  final ExperimentDetail detail;

  /// {@macro experiment_detail_dialog}
  const ExperimentDetailDialog({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Эксперимент ${detail.experimentId.substring(0, 8)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.metrics != null) ...[
              const Text('Метрики:', style: TextStyle(fontWeight: FontWeight.bold)),
              _metricRow('Train accuracy', detail.metrics!['train_accuracy']),
              _metricRow('Val accuracy', detail.metrics!['val_accuracy']),
              _metricRow('Test accuracy', detail.metrics!['test_accuracy']),
              const SizedBox(height: 8),
              _metricRow('Train loss', detail.metrics!['train_loss']),
              _metricRow('Val loss', detail.metrics!['val_loss']),
              _metricRow('Test loss', detail.metrics!['test_loss']),
            ],
            if (detail.plotBase64 != null) ...[
              const SizedBox(height: 12),
              const Text('График обучения:'),
              const SizedBox(height: 8),
              Image.memory(
                base64Decode(detail.plotBase64!),
                fit: BoxFit.contain,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Скачать модель',
              onPressed: () async {
                try {
                  final bytes = await ImageApiService().downloadModelBytes(detail.experimentId);
                  // TODO: реализовать сохранение байтов в файл (например, через share_plus или file_saver)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Модель загружена (временный вывод)')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.archive),
              tooltip: 'Скачать архив',
              onPressed: () async {
                // TODO: реализовать скачивание архива (аналогично downloadModelBytes)
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        )
      ],
    );
  }

  /// Строит строку метрики: название и значение.
  /// Принимает:
  /// - [label] – название метрики.
  /// - [value] – значение метрики (может быть null).
  /// Возвращает виджет с двумя текстами, расположенными по краям.
  Widget _metricRow(String label, double? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value != null ? value.toStringAsFixed(4) : 'N/A'),
        ],
      ),
    );
  }
}