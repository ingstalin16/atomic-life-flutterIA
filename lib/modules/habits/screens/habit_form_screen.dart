import 'package:flutter/material.dart';
//import 'package:get/get.dart';

import '../../../data/models/habit_template_model.dart';
import '../../../data/repositories/habit_repository.dart';

class HabitFormScreen extends StatefulWidget {
  final HabitTemplate? template;
  final Map<String, dynamic>? existingHabit;

  const HabitFormScreen({super.key, this.template, this.existingHabit})
    : assert(
        template == null || existingHabit == null,
        'No se puede usar una plantilla y editar un hábito a la vez.',
      );

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = HabitRepository();

  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _identity;
  late final TextEditingController _context;
  late final TextEditingController _motivation;
  late final TextEditingController _microAction;
  late final TextEditingController _duration;

  late TimeOfDay _time;
  late Set<int> _weekDays;

  bool _saving = false;

  bool get _isEditing => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();

    final template = widget.template;
    final existing = widget.existingHabit;

    String initialText(String field, String? templateValue) {
      return existing?[field] as String? ?? templateValue ?? '';
    }

    _name = TextEditingController(text: initialText('name', template?.name));

    _category = TextEditingController(
      text: initialText('category', template?.category),
    );

    _identity = TextEditingController(
      text: initialText('identity', template?.identity),
    );

    _context = TextEditingController(
      text: initialText('context', template?.context),
    );

    _motivation = TextEditingController(
      text: initialText('motivation', template?.motivation),
    );

    _microAction = TextEditingController(
      text: initialText('microAction', template?.microAction),
    );

    final duration =
        existing?['durationMinutes'] as int? ?? template?.durationMinutes ?? 2;

    _duration = TextEditingController(text: duration.toString());

    final scheduledTime =
        existing?['scheduledTime'] as String? ??
        template?.scheduledTime ??
        '08:00';

    final parts = scheduledTime.split(':');

    _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final existingDays = existing?['weekDays'];

    _weekDays = existingDays is List
        ? existingDays.whereType<int>().toSet()
        : Set<int>.from(template?.weekDays ?? [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _identity.dispose();
    _context.dispose();
    _motivation.dispose();
    _microAction.dispose();
    _duration.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (selected != null && mounted) {
      setState(() => _time = selected);
    }
  }

  Future<void> _saveHabit() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_weekDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final days = _weekDays.toList()..sort();

      if (_isEditing) {
        // Actualizar un hábito existente
        final habitId = widget.existingHabit?['id'] as String?;

        if (habitId == null || habitId.isEmpty) {
          throw StateError('No se encontró el identificador del hábito.');
        }

        await _repository.updateHabit(
          habitId: habitId,
          name: _name.text,
          category: _category.text,
          identity: _identity.text,
          context: _context.text,
          motivation: _motivation.text,
          microAction: _microAction.text,
          durationMinutes: int.parse(_duration.text),
          scheduledTime: _formatTime(_time),
          weekDays: days,
        );
      } else {
        // Crear un hábito nuevo
        await _repository.createHabit(
          name: _name.text,
          category: _category.text,
          identity: _identity.text,
          context: _context.text,
          motivation: _motivation.text,
          microAction: _microAction.text,
          durationMinutes: int.parse(_duration.text),
          scheduledTime: _formatTime(_time),
          weekDays: days,
        );
      }

      if (!mounted) return;

      // Comunicar al origen que se guardó correctamente
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el hábito: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar hábito'
              : widget.template != null
              ? 'Personalizar hábito'
              : 'Crear nuevo hábito',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _isEditing ? 'Actualiza tu hábito' : 'Diseña tu hábito',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              Text(
                _isEditing
                    ? 'Modifica los detalles de tu hábito '
                          'y guarda los cambios.'
                    : 'Comienza con acciones pequeñas '
                          'y conviértelas en parte de tu identidad.',
              ),

              const SizedBox(height: 24),

              _textField(
                controller: _name,
                label: 'Nombre del hábito',
                hint: 'Ejemplo: Leer diariamente',
                maxLength: 100,
              ),

              _textField(
                controller: _category,
                label: 'Categoría',
                hint: 'Ejemplo: Desarrollo personal',
              ),

              const Divider(),

              const Text(
                'Identidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _textField(
                controller: _identity,
                label: '¿En quién quiero convertirme?',
                hint: 'Soy una persona que aprende cada día',
                maxLines: 2,
              ),

              const Text(
                '1. Hacerlo obvio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _textField(
                controller: _context,
                label: '¿Cuándo y dónde lo realizaré?',
                hint: 'Después de desayunar, en mi escritorio',
                maxLines: 2,
              ),

              const Text(
                '2. Hacerlo atractivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _textField(
                controller: _motivation,
                label: '¿Por qué quiero lograrlo?',
                hint: 'Quiero ampliar mis conocimientos',
                maxLines: 2,
              ),

              const Text(
                '3. Hacerlo sencillo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _textField(
                controller: _microAction,
                label: 'Mi acción mínima',
                hint: 'Leer una página durante dos minutos',
                maxLines: 2,
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duración en minutos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');

                    if (minutes == null || minutes < 1 || minutes > 1440) {
                      return 'Introduce entre 1 y 1440 minutos';
                    }

                    return null;
                  },
                ),
              ),

              ListTile(
                title: const Text('Hora programada'),
                subtitle: Text(_formatTime(_time)),
                trailing: const Icon(Icons.access_time),
                onTap: _saving ? null : _chooseTime,
              ),

              const SizedBox(height: 16),

              const Text(
                'Días de la semana',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;

                  return FilterChip(
                    label: Text(days[index]),
                    selected: _weekDays.contains(dayNumber),
                    onSelected: _saving
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _weekDays.add(dayNumber);
                              } else {
                                _weekDays.remove(dayNumber);
                              }
                            });
                          },
                  );
                }),
              ),

              const SizedBox(height: 24),

              const Text(
                '4. Hacerlo satisfactorio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Registra cada cumplimiento y observa '
                'tu progreso en el calendario.',
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _saving ? null : _saveHabit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Guardando...'
                      : _isEditing
                      ? 'Guardar cambios'
                      : 'Guardar hábito',
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
