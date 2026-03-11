import 'package:flutter/material.dart';

import '../charts/chart_type.dart';

/// {@template left_sidebar}
/// Левая боковая панель навигации приложения
/// 
/// Предоставляет основной интерфейс для:
/// - Загрузки датасета
/// - Добавления различных типов графиков (тепловая карта, диаграмма рассеяния, гистограмма, ящик с усами)
/// - Просмотра информации о приложении
/// 
/// Панель имеет фиксированную ширину 72 пикселя и содержит иконки с всплывающими подсказками.
/// Кнопки добавления графиков доступны только после загрузки датасета.
/// {@endtemplate}
class LeftSidebar extends StatelessWidget {
  /// Callback для загрузки датасета
  final VoidCallback onLoadDataset;

  /// Callback для добавления нового графика определенного типа
  final Function(ChartType) onAddChart;

  /// Callback для отображения информации о приложении
  final VoidCallback onShowInfo;

  /// Callback для отображения таблицы данных
  final VoidCallback onShowTable;

  /// Флаг, указывающий, загружен ли датасет
  final bool isDatasetLoaded;

  /// {@macro left_sidebar}
  const LeftSidebar({
    super.key,
    required this.onLoadDataset,
    required this.onAddChart,
    required this.onShowInfo,
    required this.onShowTable,
    required this.isDatasetLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Логотип приложения
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 32),

          // Кнопка загрузки датасета
          _SidebarIconButton(
            icon: Icons.upload_file,
            label: 'Загрузить',
            onTap: onLoadDataset,
            isActive: true,
          ),

          const SizedBox(height: 16),

          // Разделитель
          Container(
            height: 1,
            width: 40,
            color: Colors.blueGrey[700],
          ),

          const SizedBox(height: 16),

          // Кнопки добавления графиков (доступны только с датасетом)
          if (isDatasetLoaded) ...[
            _SidebarIconButton(
              icon: Icons.grid_on,
              label: 'Таблица',
              onTap: () => onShowTable(),
              isActive: false,
            ),
            const SizedBox(height: 8),
            _SidebarIconButton(
              icon: Icons.add_chart,
              label: 'График',
              onTap: () => _showChartMenu(context),
            ),
          ],

          const Spacer(),

          // Информация о приложении
          _SidebarIconButton(
            icon: Icons.info_outline,
            label: 'О нас',
            onTap: onShowInfo,
            isActive: true,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Отображает меню выбора типа графика
  /// 
  /// Принимает:
  /// - [context] — BuildContext для отображения меню
  /// 
  /// Особенности:
  /// - Меню позиционируется справа от боковой панели
  /// - Предлагает 4 типа графиков: тепловая карта, диаграмма рассеяния, гистограмма, ящик с усами
  /// - При выборе вызывается [onAddChart] с соответствующим типом
  void _showChartMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(80, 200, 0, 0),
      items: [
        PopupMenuItem(
          onTap: () => onAddChart(ChartType.heatmap),
          child: const Row(
            children: [
              Icon(Icons.heat_pump, size: 20),
              SizedBox(width: 12),
              Text('Тепловая карта'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => onAddChart(ChartType.scatter),
          child: const Row(
            children: [
              Icon(Icons.bubble_chart, size: 20),
              SizedBox(width: 12),
              Text('Диаграмма рассеяния'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => onAddChart(ChartType.histogram),
          child: const Row(
            children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 12),
              Text('Гистограмма'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => onAddChart(ChartType.boxplot),
          child: const Row(
            children: [
              Icon(Icons.candlestick_chart, size: 20),
              SizedBox(width: 12),
              Text('Ящик с усами'),
            ],
          ),
        ),
      ],
    );
  }
}

/// {@template sidebar_icon_button}
/// Внутренний виджет для отображения кнопки на боковой панели
/// 
/// Представляет собой иконку с всплывающей подсказкой при наведении.
/// Кнопка может быть активной (подсвеченной) или неактивной.
/// {@endtemplate}
class _SidebarIconButton extends StatelessWidget {
  /// Иконка кнопки
  final IconData icon;

  /// Текст подсказки
  final String label;

  /// Callback при нажатии
  final VoidCallback onTap;

  /// Флаг активности (подсветки)
  final bool isActive;

  /// {@macro sidebar_icon_button}
  const _SidebarIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueGrey[700] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.blueGrey[300],
            size: 24,
          ),
        ),
      ),
    );
  }
}