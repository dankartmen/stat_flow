import 'package:flutter/material.dart';

import '../../core/services/image_api_service.dart';

/// {@template experiments_table}
/// Таблица (список) проведённых экспериментов для выбора и сравнения.
/// Каждый эксперимент отображается в виде карточки.
/// При наличии лучшего эксперимента (по test accuracy) он подсвечивается зелёным фоном и звёздочкой.
/// {@endtemplate}
class ExperimentsTable extends StatelessWidget {
  /// Список экспериментов для отображения.
  final List<ExperimentSummary> experiments;

  /// Колбэк, вызываемый при нажатии на эксперимент.
  /// Принимает выбранный эксперимент.
  final void Function(ExperimentSummary) onTap;

  /// Идентификатор лучшего эксперимента (если есть).
  /// Эксперимент с таким ID будет подсвечен.
  final String? bestExperimentId;

  /// {@macro experiments_table}
  const ExperimentsTable({
    super.key,
    required this.experiments,
    required this.onTap,
    this.bestExperimentId,
  });

  @override
  Widget build(BuildContext context) {
    if (experiments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет проведённых экспериментов.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final exp = experiments[index];
        final isBest = exp.experimentId == bestExperimentId;
        return Card(
          // Подсветка лучшего эксперимента
          color: isBest ? Colors.green.shade50 : null,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            title: Text('Модель ${exp.experimentId.substring(0, 8)}'),
            subtitle: Text(
              'Test Acc: ${exp.testAccuracy?.toStringAsFixed(3) ?? "N/A"} | '
              '${exp.hyperparams.convLayers} слоя, ${exp.hyperparams.optimizer}',
            ),
            trailing: isBest ? const Icon(Icons.star, color: Colors.amber) : null,
            onTap: () => onTap(exp),
          ),
        );
      },
    );
  }
}