import 'package:flutter/material.dart';

import '../../core/services/image_api_service.dart';

/// {@template experiments_table}
/// Таблица (список) проведённых экспериментов для выбора и сравнения.
/// Каждый эксперимент отображается в виде карточки.
/// При наличии лучшего эксперимента (по test accuracy) он подсвечивается зелёным фоном и звёздочкой.
///
/// Поддерживает режим множественного выбора (через чекбоксы) для последующего сравнения.
/// {@endtemplate}
class ExperimentsTable extends StatelessWidget {
  /// Список экспериментов для отображения.
  final List<ExperimentSummary> experiments;

  /// Колбэк, вызываемый при нажатии на эксперимент.
  /// Принимает выбранный эксперимент.
  final void Function(ExperimentSummary)? onTap;

  /// Идентификатор лучшего эксперимента (если есть).
  /// Эксперимент с таким ID будет подсвечен.
  final String? bestExperimentId;

  /// Множество идентификаторов экспериментов, выбранных в данный момент.
  /// Используется для отображения состояния чекбоксов.
  final Set<String>? selectedIds;

  /// Колбэк, вызываемый при изменении выбора экспериментов.
  /// Принимает новое множество выбранных идентификаторов.
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// {@macro experiments_table}
  const ExperimentsTable({
    super.key,
    required this.experiments,
    this.onTap,
    this.bestExperimentId,
    this.selectedIds,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (experiments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Нет проведённых экспериментов.'),
      );
    }

    // Режим множественного выбора активен, если переданы оба параметра
    final multiSelect = selectedIds != null && onSelectionChanged != null;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final exp = experiments[index];
        final isBest = exp.experimentId == bestExperimentId;
        final isSelected = selectedIds?.contains(exp.experimentId) ?? false;

        return Card(
          color: isBest ? Colors.green.shade50 : null,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: multiSelect
                ? Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      final newSet = Set<String>.from(selectedIds!);
                      if (val == true) {
                        newSet.add(exp.experimentId);
                      } else {
                        newSet.remove(exp.experimentId);
                      }
                      onSelectionChanged!(newSet);
                    },
                  )
                : null,
            title: Text('Модель ${exp.experimentId.substring(0, 8)}'),
            subtitle: Text(
              'Test Acc: ${exp.testAccuracy?.toStringAsFixed(3) ?? "N/A"} | '
              '${exp.hyperparams.convLayers} слоя, ${exp.hyperparams.optimizer}',
            ),
            trailing: isBest ? const Icon(Icons.star, color: Colors.amber) : null,
            onTap: () => onTap?.call(exp),
          ),
        );
      },
    );
  }
}