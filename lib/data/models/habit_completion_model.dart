import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final String date;
  final bool completed;
  final DateTime? completedAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.completed,
    this.completedAt,
  });

  factory HabitCompletion.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('El registro ${document.id} no contiene datos.');
    }

    final timestamp = data['completedAt'];

    return HabitCompletion(
      id: document.id,
      habitId: data['habitId'] as String,
      userId: data['userId'] as String,
      date: data['date'] as String,
      completed: data['completed'] as bool,
      completedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  // Convierte una fecha local a yyyy-MM-dd.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Determina si un registro corresponde al día indicado.
  bool belongsTo(DateTime date) {
    return this.date == dateKey(date);
  }
}
