import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String userId;
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
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.userId,
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
    required this.createdAt,
  });

  // Convertir el objeto Habit en datos para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'identity': identity,
      'context': context,
      'motivation': motivation,
      'microAction': microAction,
      'durationMinutes': durationMinutes,
      'scheduledTime': scheduledTime,
      'weekDays': weekDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Construir un objeto Habit desde Firestore.
  factory Habit.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      throw StateError('El documento del habito esta vacio.');
    }

    return Habit(
      id: document.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      identity: data['identity'] as String,
      context: data['context'] as String,
      motivation: data['motivation'] as String,
      microAction: data['microAction'] as String,
      durationMinutes: data['durationMinutes'] as int,
      scheduledTime: data['scheduledTime'] as String,
      weekDays: List<int>.from(data['weekDays'] as List),
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Crear una copia del habito modificando campos.
  Habit copyWith({
    String? name,
    String? category,
    String? identity,
    String? context,
    String? motivation,
    String? microAction,
    int? durationMinutes,
    String? scheduledTime,
    List<int>? weekDays,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      identity: identity ?? this.identity,
      context: context ?? this.context,
      motivation: motivation ?? this.motivation,
      microAction: microAction ?? this.microAction,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      weekDays: weekDays ?? this.weekDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
