import 'package:cloud_firestore/cloud_firestore.dart';

class HabitTemplate {
  final String id;
  final String name;
  final String category;
  final String identity;
  final String context;
  final String motivation;
  final String microAction;
  final int durationMinutes;
  final String scheduledTime;
  final List<int> weekDays;
  final bool isActive;

  const HabitTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.identity,
    required this.context,
    required this.motivation,
    required this.microAction,
    required this.durationMinutes,
    required this.scheduledTime,
    required this.weekDays,
    required this.isActive,
  });

  factory HabitTemplate.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('La plantilla ${document.id} no contiene datos.');
    }

    return HabitTemplate(
      id: document.id,
      name: data['name'] as String,
      category: data['category'] as String,
      identity: data['identity'] as String,
      context: data['context'] as String,
      motivation: data['motivation'] as String,
      microAction: data['microAction'] as String,
      durationMinutes: data['durationMinutes'] as int,
      scheduledTime: data['scheduledTime'] as String,
      weekDays: List<int>.from(data['weekDays'] as List),
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
