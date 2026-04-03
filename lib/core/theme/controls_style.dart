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
/// - [context] — контекст для доступа к теме
/// - [icon] — иконка, отображаемая слева от заголовка
///
/// Возвращает:
/// - [Widget] — колонка с заголовком, содержимым и разделителем
Widget buildSection({
  required BuildContext context,
  required String title,
  required IconData? icon,
  required Widget child,
  bool initiallyExpanded = true,
}) {
  return Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      children: [child],
    ),
  );
}

/// {@template build_dropdown}
/// Создает выпадающий список с меткой и поддержкой значения "Не выбрано".
///
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
/// - [context] — контекст для доступа к теме
///
/// Возвращает:
/// - [Widget] — строка с меткой и выпадающим списком
Widget buildDropdown<T>({
  required BuildContext context,
  required String label,
  required T? initialValue,
  required List<T> items,
  required ValueChanged<T?> onChanged,
  String Function(T)? displayName,
}) {
  final effectiveItems = [null, ...items];
  final safeInitialValue = (initialValue == null || items.contains(initialValue)) ? initialValue : null;

  final valueListenable = ValueNotifier<T?>(safeInitialValue);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      const SizedBox(height: 8),
      DropdownButtonHideUnderline(
        child: DropdownButton2<T?>(
          isExpanded: true,
          valueListenable: valueListenable,
          hint: Text(
            'Не выбрано',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          items: effectiveItems.map((item) {
            final text = item == null
                ? 'Не выбрано'
                : (displayName != null ? displayName(item as T) : item.toString());
            return DropdownItem<T?>(
              value: item,
              child: Text(text, style: const TextStyle(fontSize: 15.5)),
            );
          }).toList(),
          onChanged: (newValue) {
            valueListenable.value = newValue;
            onChanged(newValue);
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
          ),
          iconStyleData: IconStyleData(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
            iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ],
  );
}

/// {@template build_switch}
/// Создает переключатель с заголовком и кастомной стилизацией.
/// Особенности:
/// - Заголовок выравнивается по левому краю
/// - Активный цвет переключателя соответствует основной цветовой схеме темы
/// - Удобный размер и отступы для лучшей юзабилити
/// - Используется [SwitchListTile] для автоматической обработки нажатий и отображения состояния
/// {@endtemplate}
/// 
/// Принимает:
/// - [title] — текст заголовка переключателя
/// - [value] — текущее состояние переключателя (включен/выключен)
/// - [onChanged] — колбэк, вызываемый при изменении состояния переключателя
/// - [context] — контекст для доступа к теме и стилям
/// 
/// Возвращает:
/// - [Widget] — виджет переключателя с заголовком
Widget buildSwitch(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15.5)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }