import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habit_tracking_controller.dart';

class HabitTrackingScreen extends StatefulWidget {
  const HabitTrackingScreen({super.key});

  @override
  State<HabitTrackingScreen> createState() => _HabitTrackingScreenState();
}

class _HabitTrackingScreenState extends State<HabitTrackingScreen>
    with WidgetsBindingObserver {
  late final HabitTrackingController controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (Get.isRegistered<HabitTrackingController>()) {
      controller = Get.find<HabitTrackingController>();
      controller.loadToday();
    } else {
      controller = Get.put(HabitTrackingController());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !controller.isClosed) {
      controller.loadToday();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _toggleHabit(String habitId) async {
    final success = await controller.toggleCompletion(habitId);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage.value.isNotEmpty
                ? controller.errorMessage.value
                : 'No se pudo actualizar el cumplimiento.',
          ),
        ),
      );
      return;
    }

    final completed = controller.isHabitCompleted(habitId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? '¡Excelente! Hábito completado.'
              : 'Cumplimiento desmarcado.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis hábitos de hoy'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadToday,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.status.value) {
            case TrackingStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case TrackingStatus.error:
              return _TrackingMessage(
                icon: Icons.error_outline,
                title: 'No pudimos cargar tus hábitos',
                description: controller.errorMessage.value,
                onRetry: controller.loadToday,
              );

            case TrackingStatus.empty:
              return _TrackingMessage(
                icon: Icons.event_available_outlined,
                title: 'No tienes hábitos programados hoy',
                description:
                    'Puedes crear un hábito o revisar '
                    'los días programados en Mis hábitos.',
                onRetry: controller.loadToday,
              );

            case TrackingStatus.success:
              return _buildTrackingContent(context);
          }
        }),
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context) {
    final completed = controller.completedToday;
    final total = controller.totalToday;
    final progress = controller.progress;

    return RefreshIndicator(
      onRefresh: controller.loadToday,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFE0F2E9),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi progreso de hoy',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  Text('$completed de $total hábitos completados'),

                  const SizedBox(height: 12),

                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: Colors.white,
                    color: const Color(0xFF2E7D64),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D64),
                    ),
                  ),

                  if (total > 0 && completed == total) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '¡Felicitaciones! Completaste todos '
                      'tus hábitos de hoy.',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Hábitos programados',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          ...controller.todayHabits.map((habit) {
            final habitId = habit['id'] as String? ?? '';
            final completed = controller.isHabitCompleted(habitId);

            final processing = controller.processingHabitId.value.isNotEmpty;

            final name = habit['name'] as String? ?? 'Sin nombre';

            final microAction = habit['microAction'] as String? ?? '';

            final time = habit['scheduledTime'] as String? ?? '';

            final duration = habit['durationMinutes'] as int? ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: completed,
                onChanged: processing || habitId.isEmpty
                    ? null
                    : (_) => _toggleHabit(habitId),
                activeColor: const Color(0xFF2E7D64),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (microAction.isNotEmpty)
                        Text('Microacción: $microAction'),
                      const SizedBox(height: 4),
                      Text('$time · $duration minutos'),
                    ],
                  ),
                ),
                secondary: controller.processingHabitId.value == habitId
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        completed
                            ? Icons.emoji_events_outlined
                            : Icons.spa_outlined,
                        color: const Color(0xFF2E7D64),
                      ),
              ),
            );
          }),

          const SizedBox(height: 24),

          const Text(
            'Cada pequeña acción cuenta. '
            'Construye tu constancia un día a la vez.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TrackingMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Future<void> Function()? onRetry;

  const _TrackingMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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

            const SizedBox(height: 12),

            Text(description, textAlign: TextAlign.center),

            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
