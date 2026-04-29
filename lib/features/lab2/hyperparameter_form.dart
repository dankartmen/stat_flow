import 'package:flutter/material.dart';

import '../../core/services/image_api_service.dart';

/// {@template hyperparameter_form}
/// Форма для выбора гиперпараметров модели классификации изображений.
/// Позволяет изменять количество свёрточных слоёв, размер ядра, dropout, оптимизатор и количество эпох.
/// При изменении количества слоёв автоматически подставляются соответствующие фильтры.
/// {@endtemplate}
class HyperparameterForm extends StatefulWidget {
  /// Начальные значения гиперпараметров.
  final Hyperparams initial;

  /// Колбэк, вызываемый при любом изменении параметров.
  final ValueChanged<Hyperparams> onChanged;

  /// {@macro hyperparameter_form}
  const HyperparameterForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<HyperparameterForm> createState() => _HyperparameterFormState();
}

/// {@template hyperparameter_form_state}
/// Состояние формы гиперпараметров.
/// Управляет текущими значениями и уведомляет родителя об изменениях.
/// {@endtemplate}
class _HyperparameterFormState extends State<HyperparameterForm> {
  /// Текущие значения гиперпараметров.
  late Hyperparams _params;

  @override
  void initState() {
    super.initState();
    _params = widget.initial;
  }

  /// Уведомляет родителя об изменении параметров и обновляет состояние.
  void _update() {
    widget.onChanged(_params);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<int>(
          'Кол-во свёрточных слоёв',
          _params.convLayers,
          [2, 3],
          (v) {
            _params.convLayers = v!;
            // Автоматически подставляем фильтры в зависимости от количества слоёв
            // 2 слоя -> [32, 64], 3 слоя -> [32, 64, 128]
            if (v == 2) {
              _params.filters = [32, 64];
            } else {
              _params.filters = [32, 64, 128];
            }
            _update();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          'Фильтры',
          _params.filters.toString(),
          ['[32, 64]', '[32, 64, 128]'],
          (v) {
            _params.filters = v!.startsWith('[32, 64, 128]')
                ? [32, 64, 128]
                : [32, 64];
            _update();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          'Размер ядра',
          _params.kernelSize.toString(),
          ['[3, 3]', '[5, 5]'],
          (v) {
            _params.kernelSize = v == '[5, 5]' ? [5, 5] : [3, 3];
            _update();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown<double>(
          'Dropout',
          _params.dropoutRate,
          [0.25, 0.5],
          (v) {
            _params.dropoutRate = v!;
            _update();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          'Оптимизатор',
          _params.optimizer,
          ['adam', 'sgd'],
          (v) {
            _params.optimizer = v!;
            _update();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown<int>(
          'Эпохи',
          _params.epochs,
          [3, 10, 20, 30],
          (v) {
            _params.epochs = v!;
            _update();
            setState(() {});
          },
        ),
      ],
    );
  }

  /// Универсальный метод построения выпадающего списка для выбора параметра.
  /// Принимает:
  /// - [label] – текст подписи.
  /// - [value] – текущее значение.
  /// - [items] – список доступных значений.
  /// - [onChanged] – колбэк при изменении.
  /// Возвращает виджет с двумя колонками: подпись и выпадающий список.
  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<T>(
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          ),
        ),
      ],
    );
  }
}