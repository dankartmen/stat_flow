  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../core/providers/providers.dart';
  import '../charts/chart_type.dart';

  /// {@template left_sidebar}
  /// Левая боковая панель навигации приложения
  /// 
  /// Предоставляет основной интерфейс для:
  /// - Загрузки датасетов через диалог выбора файла
  /// - Создания новых графиков различных типов
  /// - Открытия таблицы с данными
  /// - Просмотра информации о приложении
  /// 
  /// Панель имеет фиксированную ширину 72px и всегда видима на экране.
  /// Элементы управления динамически появляются только после загрузки данных.
  /// {@endtemplate}
  class LeftSidebar extends ConsumerWidget {
    /// Коллбек для открытия диалога загрузки датасета
    final VoidCallback onLoadDataset;

    /// Коллбек для создания нового графика указанного типа
    final Function(ChartType) onAddChart;

    /// Коллбек для отображения информационного диалога
    final VoidCallback onShowInfo;

    /// Коллбек для открытия полноэкранной таблицы данных
    final VoidCallback onShowTable;

    /// {@macro left_sidebar}
    const LeftSidebar({
      super.key,
      required this.onLoadDataset,
      required this.onAddChart,
      required this.onShowInfo,
      required this.onShowTable,
    });

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final dataset = ref.watch(datasetProvider);
      final isDatasetLoaded = dataset != null;

      return Container(
        width: 72,
        color: Colors.blueGrey[900],
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 32),
            _SidebarIconButton(
              icon: Icons.upload_file,
              label: 'Загрузить',
              onTap: onLoadDataset,
              isActive: true,
            ),
            const SizedBox(height: 16),
            Container(height: 1, width: 40, color: Colors.blueGrey[700]),
            const SizedBox(height: 16),
            if (isDatasetLoaded) ...[
              _SidebarIconButton(
                icon: Icons.grid_on,
                label: 'Таблица',
                onTap: onShowTable,
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

    /// Отображает всплывающее меню с доступными типами графиков
    void _showChartMenu(BuildContext context) {
      showMenu(
        context: context,
        position: const RelativeRect.fromLTRB(80, 200, 0, 0),
        items: ChartType.values.map((type) {
          return PopupMenuItem(
            onTap: () => onAddChart(type),
            child: Row(
              children: [
                Icon(_iconForType(type), size: 20),
                const SizedBox(width: 12),
                Text(type.name),
              ],
            ),
          );
        }).toList(),
      );
    }

    /// Возвращает иконку для указанного типа графика
    IconData _iconForType(ChartType type) {
      switch (type) {
        case ChartType.heatmap:
          return Icons.heat_pump;
        case ChartType.scatter:
          return Icons.bubble_chart;
        case ChartType.histogram:
          return Icons.bar_chart;
        case ChartType.boxplot:
          return Icons.candlestick_chart;
        case ChartType.linechart:
          return Icons.line_axis;
        case ChartType.barchart:
          return Icons.bar_chart;
      }
    }
  }

  /// {@template sidebar_icon_button}
  /// Кастомная иконка-кнопка для боковой панели с всплывающей подсказкой
  /// 
  /// Особенности:
  /// - Круглая форма с радиусом 8px
  /// - Подсветка активного состояния
  /// - Всплывающая подсказка при наведении
  /// - Единый стиль для всех иконок панели
  /// {@endtemplate}
  class _SidebarIconButton extends StatelessWidget {
    /// Иконка для отображения
    final IconData icon;

    /// Текст всплывающей подсказки
    final String label;

    /// Коллбек при нажатии
    final VoidCallback onTap;

    /// Флаг активности (подсветка кнопки)
    final bool isActive;

    /// {@macro sidebar_icon_button}
    const _SidebarIconButton({
      required this.icon, 
      required this.label, 
      required this.onTap, 
      this.isActive = false
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
            child: Icon(icon, color: isActive ? Colors.white : Colors.blueGrey[300], size: 24),
          ),
        ),
      );
    }
  }