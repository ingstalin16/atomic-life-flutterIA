import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habit_calendar_controller.dart';

class HabitCalendarScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const HabitCalendarScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  late final HabitCalendarController controller;
  late final String _controllerTag;

  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _weekDays = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();

    _controllerTag = 'calendar_${widget.habitId}_${identityHashCode(this)}';

    controller = Get.put(
      HabitCalendarController(
        habitId: widget.habitId,
        habitName: widget.habitName,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<HabitCalendarController>(tag: _controllerTag)) {
      Get.delete<HabitCalendarController>(tag: _controllerTag);
    }

    super.dispose();
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();

    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool _isFuture(DateTime date) {
    final today = DateTime.now();
    final selected = DateTime(date.year, date.month, date.day);
    final current = DateTime(today.year, today.month, today.day);

    return selected.isAfter(current);
  }

  bool _canGoNext(DateTime month) {
    final now = DateTime.now();

    return month.year < now.year ||
        (month.year == now.year && month.month < now.month);
  }

  Widget _buildCalendar() {
    final month = controller.selectedMonth.value;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = controller.daysInMonth;

    // Dart: lunes = 1 y domingo = 7.
    final emptyDays = firstDay.weekday - 1;
    final totalCells = emptyDays + daysInMonth;

    return Column(
      children: [
        // Nombres de los días
        Row(
          children: _weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.9,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < emptyDays) {
              return const SizedBox.shrink();
            }

            final day = index - emptyDays + 1;

            final date = DateTime(month.year, month.month, day);

            final completed = controller.isCompleted(date);
            final today = _isToday(date);
            final future = _isFuture(date);

            return Container(
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE0F2E9)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: today
                    ? Border.all(color: const Color(0xFF2E7D64), width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: completed || today
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: future
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),

                  if (completed) ...[
                    const SizedBox(height: 3),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D64),
                      size: 17,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de cumplimiento'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar calendario',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMonth,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final status = controller.status.value;
          final month = controller.selectedMonth.value;

          final monthName = _months[month.month - 1];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nombre del hábito
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        color: Color(0xFF2E7D64),
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.habitName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cada día cuenta para construir '
                        'tu constancia.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Navegación mensual
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mes anterior',
                    onPressed: controller.previousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),

                  Expanded(
                    child: Text(
                      '$monthName ${month.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Mes siguiente',
                    onPressed: _canGoNext(month) ? controller.nextMonth : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Estados de carga y error
              if (status == CalendarStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (status == CalendarStatus.error)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: controller.loadMonth,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildCalendar(),

                const SizedBox(height: 24),

                // Resumen mensual
                Card(
                  color: const Color(0xFFE0F2E9),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 32,
                          color: Color(0xFF2E7D64),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Días completados',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${controller.completedDays}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D64),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (status == CalendarStatus.empty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Todavía no existen cumplimientos '
                    'registrados para este mes.',
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D64),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('Día completado'),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'El calendario muestra los registros '
                  'guardados en Firebase. Para marcar '
                  'el cumplimiento de hoy, utiliza '
                  'la pantalla Mis hábitos de hoy.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: controller.goToCurrentMonth,
                  icon: const Icon(Icons.today),
                  label: const Text('Ir al mes actual'),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
