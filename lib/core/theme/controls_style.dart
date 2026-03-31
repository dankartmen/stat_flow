import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// {@template build_section}
/// Создает секцию с заголовком и разделителем.
///
/// Особенности:
/// - Заголовок выравнивается по левому краю
/// - Содержимое размещается под заголовком
/// - После содержимого добавляется горизонтальный разделитель
/// {@endtemplate}
///
/// Принимает:
/// - [title] — виджет заголовка секции [Text]
/// - [child] — содержимое секции
///
/// Возвращает:
/// - [Widget] — колонка с заголовком, содержимым и разделителем
Widget buildSection({required Text title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: title,
      ),
      child,
      const Divider(),
    ],
  );
}

/// {@template build_dropdown}
/// Создает выпадающий список с меткой и поддержкой значения "Не выбрано".
///
/// Использует пакет [dropdown_button2] для расширенного стилизации.
/// Особенности:
/// - Автоматически добавляет пункт "Не выбрано" (null) в начало списка
/// - Гарантирует, что [initialValue] присутствует в списке, иначе сбрасывает на null
/// - Поддерживает пользовательское форматирование текста через [displayName]
/// - Использует [ValueNotifier] для реактивного обновления
/// - Адаптивная верстка с двумя колонками (метка и выпадающий список)
/// {@endtemplate}
///
/// Принимает:
/// - [label] — текст метки слева
/// - [initialValue] — начальное выбранное значение (может быть null)
/// - [items] — список доступных значений (без учета null-пункта)
/// - [onChanged] — колбэк при изменении выбранного значения
/// - [displayName] — опциональная функция форматирования текста для каждого значения
///
/// Возвращает:
/// - [Widget] — строка с меткой и выпадающим списком
Widget buildDropdown<T>({
  required String label,
  required T? initialValue,
  required List<T> items,
  required ValueChanged<T?> onChanged,
  String Function(T)? displayName,
}) {
  // Добавляем пункт "Не выбрано" со значением null
  final effectiveItems = [null, ...items];

  // Важно: если initialValue не входит в items и не null — сбрасываем его на null
  final safeInitialValue = (initialValue == null || items.contains(initialValue))
      ? initialValue
      : null;

  final valueListenable = ValueNotifier<T?>(safeInitialValue);

  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 3,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T?>(
            isExpanded: true,
            valueListenable: valueListenable,
            hint: const Text('Выберите...'),
            items: effectiveItems.map((item) {
              final childText = item == null
                  ? 'Не выбрано'
                  : (displayName != null ? displayName(item as T) : item.toString());
              return DropdownItem<T?>(
                value: item,
                child: Text(
                  childText,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (T? newValue) {
              valueListenable.value = newValue;
              onChanged(newValue);
            },
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.symmetric(horizontal: 12),
              height: 40,
              width: 150,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}