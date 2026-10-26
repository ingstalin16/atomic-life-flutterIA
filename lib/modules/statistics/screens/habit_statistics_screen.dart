import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/habit_statistics_model.dart';
import '../controllers/habit_statistics_controller.dart';

class HabitStatisticsScreen extends StatefulWidget {
  const HabitStatisticsScreen({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitStatisticsScreen> createState() => _HabitStatisticsScreenState();
}

class _HabitStatisticsScreenState extends State<HabitStatisticsScreen> {
  late final HabitStatisticsController controller;
  late final String controllerTag;

  @override
  void initState() {
    super.initState();

    controllerTag = 'statistics_${widget.habitId}_${identityHashCode(this)}';

    controller = Get.put(
      HabitStatisticsController(habitId: widget.habitId),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<HabitStatisticsController>(tag: controllerTag)) {
      Get.delete<HabitStatisticsController>(tag: controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del hábito'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar estadísticas',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStatistics,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.status.value) {
            case StatisticsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case StatisticsStatus.error:
              return _buildError(context);

            case StatisticsStatus.success:
              final data = controller.statistics.value;

              if (data == null) {
                return _buildError(context);
              }

              return _buildStatistics(context, data);
          }
        }),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value.isEmpty
                  ? 'No se encontraron estadísticas.'
                  : controller.errorMessage.value,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: controller.loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, HabitStatistics data) {
    final percentage = (data.completionRate * 100).clamp(0.0, 100.0);

    return RefreshIndicator(
      onRefresh: controller.loadStatistics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.spa, size: 48, color: Color(0xFF2E7D64)),
                  const SizedBox(height: 12),
                  Text(
                    controller.habitName.value,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (controller.habitCategory.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.habitCategory.value,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text('Tu progreso', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _StatisticCard(
                icon: Icons.local_fire_department_outlined,
                title: 'Racha actual',
                value: '${data.currentStreak}',
                description: 'Días programados',
              ),
              _StatisticCard(
                icon: Icons.emoji_events_outlined,
                title: 'Mejor racha',
                value: '${data.bestStreak}',
                description: 'Mayor secuencia',
              ),
              _StatisticCard(
                icon: Icons.check_circle_outline,
                title: 'Completados',
                value: '${data.completedDays}',
                description: 'Días cumplidos',
              ),
              _StatisticCard(
                icon: Icons.percent,
                title: 'Cumplimiento',
                value: '${percentage.toStringAsFixed(1)}%',
                description: 'Tasa general',
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            color: const Color(0xFFE0F2E9),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Porcentaje de cumplimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  LinearProgressIndicator(
                    value: data.completionRate.clamp(0.0, 1.0),
                    minHeight: 14,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.white,
                    color: const Color(0xFF2E7D64),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    '${data.completedDays} de '
                    '${data.scheduledDays} días programados',
                    style: const TextStyle(color: Colors.black87),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D64),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'La constancia se construye mediante '
            'pequeñas acciones repetidas en el tiempo.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Las estadísticas se calculan utilizando '
            'la programación semanal actual del hábito '
            'desde su fecha de creación.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: const Color(0xFF2E7D64)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
