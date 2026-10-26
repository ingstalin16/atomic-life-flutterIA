import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/habit_template_model.dart';
import '../controllers/habit_templates_controller.dart';
import 'habit_form_screen.dart';

class HabitCatalogScreen extends StatelessWidget {
  const HabitCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HabitTemplatesController>()
        ? Get.find<HabitTemplatesController>()
        : Get.put(HabitTemplatesController());

    return Scaffold(
      appBar: AppBar(title: const Text('Explora hábitos'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar hábitos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: controller.updateSearch,
              ),
            ),

            // Filtros por categoría
            SizedBox(
              height: 54,
              child: Obx(() {
                final categories = controller.categories;
                final selected = controller.selectedCategory.value;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return ChoiceChip(
                      label: Text(category),
                      selected: selected == category,
                      onSelected: (_) {
                        controller.updateCategory(category);
                      },
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 8),

            // Estados del catálogo
            Expanded(
              child: Obx(() {
                switch (controller.status.value) {
                  case CatalogStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case CatalogStatus.error:
                    return _MessageState(
                      icon: Icons.wifi_off,
                      message: controller.errorMessage.value,
                      buttonText: 'Reintentar',
                      onPressed: controller.loadTemplates,
                    );

                  case CatalogStatus.empty:
                    return _MessageState(
                      icon: Icons.inbox_outlined,
                      message: 'No hay hábitos disponibles en el catálogo.',
                      buttonText: 'Actualizar',
                      onPressed: controller.loadTemplates,
                    );

                  case CatalogStatus.success:
                    final habits = controller.filteredTemplates;

                    if (habits.isEmpty) {
                      return const _MessageState(
                        icon: Icons.search_off,
                        message: 'No encontramos hábitos con esos filtros.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: controller.loadTemplates,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];

                          return _HabitCard(
                            habit: habit,
                            onTap: () {
                              controller.selectTemplate(habit);

                              Get.to(
                                () => HabitTemplateDetailScreen(habit: habit),
                              );
                            },
                          );
                        },
                      ),
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta para mostrar cada hábito del catálogo
class _HabitCard extends StatelessWidget {
  final HabitTemplate habit;
  final VoidCallback onTap;

  const _HabitCard({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2E9),
          child: Icon(Icons.spa, color: Color(0xFF2E7D64)),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.category),
              const SizedBox(height: 4),
              Text(
                'Microacción: ${habit.microAction}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${habit.durationMinutes} minutos · '
                '${habit.scheduledTime}',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Widget reutilizable para mensajes de estado
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _MessageState({
    required this.icon,
    required this.message,
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
            Icon(icon, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
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

// Pantalla de detalle del hábito y las cuatro leyes
class HabitTemplateDetailScreen extends StatelessWidget {
  final HabitTemplate habit;

  const HabitTemplateDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del hábito')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.spa, size: 70, color: Color(0xFF2E7D64)),

            const SizedBox(height: 16),

            Text(
              habit.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(habit.category, textAlign: TextAlign.center),

            const SizedBox(height: 24),

            // Primera ley
            _LawCard(
              number: '1',
              title: 'Hacerlo obvio',
              description: habit.context,
              icon: Icons.visibility_outlined,
            ),

            // Segunda ley
            _LawCard(
              number: '2',
              title: 'Hacerlo atractivo',
              description: habit.motivation,
              icon: Icons.favorite_outline,
            ),

            // Tercera ley
            _LawCard(
              number: '3',
              title: 'Hacerlo sencillo',
              description: habit.microAction,
              icon: Icons.directions_walk,
            ),

            // Cuarta ley
            const _LawCard(
              number: '4',
              title: 'Hacerlo satisfactorio',
              description:
                  'Registra cada cumplimiento y observa '
                  'tu progreso en el calendario.',
              icon: Icons.emoji_events_outlined,
            ),

            const SizedBox(height: 16),

            // Identidad del hábito
            Card(
              color: const Color(0xFFE0F2E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Identidad que quiero construir',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(habit.identity, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información de planificación
            Text('Duración: ${habit.durationMinutes} minutos'),
            Text('Hora sugerida: ${habit.scheduledTime}'),

            const SizedBox(height: 24),

            // Botón para personalizar y crear un hábito
            FilledButton.icon(
              onPressed: () async {
                final created = await Get.to<bool>(
                  () => HabitFormScreen(template: habit),
                );

                // Si el formulario guardó el hábito,
                // regresamos al catálogo.
                if (created == true && context.mounted) {
                  Get.back(result: true);
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Usar este hábito'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D64),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Puedes personalizar el nombre, '
              'la duración, el horario y los días '
              'antes de guardar este hábito.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Tarjeta reutilizable para las cuatro leyes
class _LawCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _LawCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE0F2E9),
              child: Icon(icon, color: const Color(0xFF2E7D64)),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
