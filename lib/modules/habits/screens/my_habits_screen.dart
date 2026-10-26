import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/my_habits_controller.dart';
import 'habit_form_screen.dart';
import '../../tracking/screens/habit_calendar_screen.dart';
import '../../statistics/screens/habit_statistics_screen.dart';

// =====================================================
// PANTALLA PRINCIPAL: MIS HÁBITOS
// =====================================================

class MyHabitsScreen extends StatelessWidget {
  const MyHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MyHabitsController>()
        ? Get.find<MyHabitsController>()
        : Get.put(MyHabitsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis hábitos'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadHabits,
          ),
        ],
      ),

      // Crear hábito desde cero
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Get.to<bool>(() => const HabitFormScreen());

          if (created == true && !controller.isClosed) {
            await controller.loadHabits();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hábito'),
      ),

      body: SafeArea(
        child: Obx(() {
          switch (controller.status.value) {
            case MyHabitsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case MyHabitsStatus.error:
              return _EmptyMessage(
                icon: Icons.wifi_off,
                title: 'No se pudieron cargar tus hábitos',
                description: controller.errorMessage.value,
                buttonText: 'Reintentar',
                onPressed: controller.loadHabits,
              );

            case MyHabitsStatus.empty:
              return const _EmptyMessage(
                icon: Icons.spa_outlined,
                title: 'Todavía no tienes hábitos',
                description: 'Comienza creando tu primer hábito saludable.',
              );

            case MyHabitsStatus.success:
              return RefreshIndicator(
                onRefresh: controller.loadHabits,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: controller.habits.length,
                  itemBuilder: (context, index) {
                    final habit = controller.habits[index];

                    return _PersonalHabitCard(
                      habit: habit,
                      controller: controller,
                    );
                  },
                ),
              );
          }
        }),
      ),
    );
  }
}

// =====================================================
// TARJETA DE UN HÁBITO PERSONAL
// =====================================================

class _PersonalHabitCard extends StatelessWidget {
  final Map<String, dynamic> habit;
  final MyHabitsController controller;

  const _PersonalHabitCard({required this.habit, required this.controller});

  @override
  Widget build(BuildContext context) {
    final habitId = habit['id'] as String? ?? '';
    final name = habit['name'] as String? ?? 'Sin nombre';
    final category = habit['category'] as String? ?? '';
    final time = habit['scheduledTime'] as String? ?? '';
    final duration = habit['durationMinutes'] as int? ?? 0;
    final active = habit['isActive'] as bool? ?? true;

    final days =
        (habit['weekDays'] as List<dynamic>?)?.whereType<int>().toList() ??
        <int>[];

    const dayNames = {1: 'L', 2: 'Ma', 3: 'Mi', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};

    final dayLabel = days
        .map((day) => dayNames[day] ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2E9),
                  child: Icon(
                    active ? Icons.spa : Icons.pause,
                    color: const Color(0xFF2E7D64),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(category),
                    ],
                  ),
                ),

                Chip(label: Text(active ? 'Activo' : 'Pausado')),

                // =====================================
                // MENÚ DE ACCIONES DEL HÁBITO
                // =====================================
                Obx(
                  () => PopupMenuButton<String>(
                    tooltip: 'Opciones del hábito',
                    enabled:
                        habitId.isNotEmpty && !controller.isProcessing.value,

                    onSelected: (action) {
                      if (!context.mounted) return;

                      switch (action) {
                        // VER ESTADÍSTICAS
                        case 'statistics':
                          Get.to(() => HabitStatisticsScreen(habitId: habitId));
                          break;

                        // VER CALENDARIO
                        case 'calendar':
                          Get.to(
                            () => HabitCalendarScreen(
                              habitId: habitId,
                              habitName: name,
                            ),
                          );
                          break;

                        // EDITAR HÁBITO
                        case 'edit':
                          _editHabit(context);
                          break;

                        // PAUSAR O REACTIVAR
                        case 'status':
                          _changeStatus(context, habitId, name, !active);
                          break;

                        // ELIMINAR HÁBITO
                        case 'delete':
                          _confirmDelete(context, habitId, name);
                          break;
                      }
                    },

                    itemBuilder: (context) => [
                      // OPCIÓN 1: VER ESTADÍSTICAS
                      const PopupMenuItem<String>(
                        value: 'statistics',
                        child: Row(
                          children: [
                            Icon(
                              Icons.bar_chart_outlined,
                              color: Color(0xFF2E7D64),
                            ),
                            SizedBox(width: 12),
                            Text('Ver estadísticas'),
                          ],
                        ),
                      ),

                      // OPCIÓN 2: VER CALENDARIO
                      const PopupMenuItem<String>(
                        value: 'calendar',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_outlined),
                            SizedBox(width: 12),
                            Text('Ver calendario'),
                          ],
                        ),
                      ),

                      // OPCIÓN 3: EDITAR HÁBITO
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Editar hábito'),
                          ],
                        ),
                      ),

                      // OPCIÓN 4: PAUSAR O REACTIVAR
                      PopupMenuItem<String>(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(
                              active
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                            ),
                            const SizedBox(width: 12),
                            Text(active ? 'Pausar hábito' : 'Reactivar hábito'),
                          ],
                        ),
                      ),

                      // OPCIÓN 5: ELIMINAR
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Eliminar hábito'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información del hábito
            Text('Hora: $time'),
            Text('Duración: $duration minutos'),
            Text('Días: $dayLabel'),

            // Fecha de creación
            if (habit['createdAt'] is Timestamp) ...[
              const SizedBox(height: 8),
              Text(
                'Creado: ${_formatDate((habit['createdAt'] as Timestamp).toDate())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // EDITAR HÁBITO
  // =====================================================

  Future<void> _editHabit(BuildContext context) async {
    final updated = await Get.to<bool>(
      () => HabitFormScreen(existingHabit: habit),
    );

    if (updated != true || !context.mounted) return;

    await controller.refreshAfterEdit();

    if (!context.mounted) return;

    final success = controller.status.value != MyHabitsStatus.error;

    final message = success
        ? 'Hábito actualizado correctamente.'
        : controller.errorMessage.value;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // =====================================================
  // PAUSAR O REACTIVAR HÁBITO
  // =====================================================

  Future<void> _changeStatus(
    BuildContext context,
    String habitId,
    String name,
    bool newStatus,
  ) async {
    final success = await controller.changeHabitStatus(
      habitId: habitId,
      isActive: newStatus,
    );

    if (!context.mounted) return;

    final message = success
        ? newStatus
              ? 'El hábito "$name" fue reactivado.'
              : 'El hábito "$name" fue pausado.'
        : controller.errorMessage.value.isNotEmpty
        ? controller.errorMessage.value
        : 'No se pudo actualizar el hábito.';

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // =====================================================
  // ELIMINAR HÁBITO
  // =====================================================

  Future<void> _confirmDelete(
    BuildContext context,
    String habitId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Estás seguro de eliminar "$name"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await controller.removeHabit(habitId);

    if (!context.mounted) return;

    final message = success
        ? 'El hábito "$name" fue eliminado.'
        : controller.errorMessage.value.isNotEmpty
        ? controller.errorMessage.value
        : 'No se pudo eliminar el hábito.';

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // =====================================================
  // FORMATEAR FECHA DE CREACIÓN
  // =====================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// =====================================================
// WIDGET PARA ESTADOS VACÍOS Y ERRORES
// =====================================================

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF2E7D64)),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(description, textAlign: TextAlign.center),

            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}
