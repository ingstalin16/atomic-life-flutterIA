import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitRepository {
  HabitRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Obtener la colección de hábitos del usuario autenticado
  CollectionReference<Map<String, dynamic>> _userHabits() {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'Debes iniciar sesión para gestionar hábitos.',
      );
    }

    return _firestore.collection('users').doc(user.uid).collection('habits');
  }

  // Validar la información de un hábito
  void _validateHabit({
    required String name,
    required String category,
    required String identity,
    required String context,
    required String motivation,
    required String microAction,
    required int durationMinutes,
    required String scheduledTime,
    required List<int> weekDays,
  }) {
    if (name.trim().isEmpty || name.trim().length > 100) {
      throw ArgumentError('El nombre debe contener entre 1 y 100 caracteres.');
    }

    final requiredTexts = [
      category,
      identity,
      context,
      motivation,
      microAction,
    ];

    if (requiredTexts.any((text) => text.trim().isEmpty)) {
      throw ArgumentError('Todos los campos del hábito son obligatorios.');
    }

    if (durationMinutes < 1 || durationMinutes > 1440) {
      throw ArgumentError('La duración debe estar entre 1 y 1440 minutos.');
    }

    if (!RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(scheduledTime)) {
      throw ArgumentError('El horario debe tener el formato HH:mm.');
    }

    if (weekDays.isEmpty ||
        weekDays.length > 7 ||
        weekDays.toSet().length != weekDays.length ||
        weekDays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Selecciona días válidos, sin repetir.');
    }
  }

  // =====================================================
  // CREATE: Crear un hábito personal
  // =====================================================

  Future<String> createHabit({
    required String name,
    required String category,
    required String identity,
    required String context,
    required String motivation,
    required String microAction,
    required int durationMinutes,
    required String scheduledTime,
    required List<int> weekDays,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'No existe una sesión activa.',
      );
    }

    _validateHabit(
      name: name,
      category: category,
      identity: identity,
      context: context,
      motivation: motivation,
      microAction: microAction,
      durationMinutes: durationMinutes,
      scheduledTime: scheduledTime,
      weekDays: weekDays,
    );

    final data = <String, dynamic>{
      'userId': user.uid,
      'name': name.trim(),
      'category': category.trim(),
      'identity': identity.trim(),
      'context': context.trim(),
      'motivation': motivation.trim(),
      'microAction': microAction.trim(),
      'durationMinutes': durationMinutes,
      'scheduledTime': scheduledTime,
      'weekDays': weekDays,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final document = await _userHabits().add(data);

    return document.id;
  }

  // =====================================================
  // READ: Consultar los hábitos personales
  // =====================================================

  Future<List<Map<String, dynamic>>> getMyHabits() async {
    final snapshot = await _userHabits().get();

    return snapshot.docs.map((doc) {
      return <String, dynamic>{'id': doc.id, ...doc.data()};
    }).toList();
  }

  // Consultar un hábito específico
  Future<Map<String, dynamic>?> getHabitById(String habitId) async {
    if (habitId.trim().isEmpty) {
      throw ArgumentError('El identificador del hábito es obligatorio.');
    }

    final document = await _userHabits().doc(habitId).get();

    if (!document.exists) {
      return null;
    }

    return <String, dynamic>{'id': document.id, ...document.data()!};
  }

  // =====================================================
  // UPDATE: Editar un hábito personal
  // =====================================================

  Future<void> updateHabit({
    required String habitId,
    required String name,
    required String category,
    required String identity,
    required String context,
    required String motivation,
    required String microAction,
    required int durationMinutes,
    required String scheduledTime,
    required List<int> weekDays,
  }) async {
    if (habitId.trim().isEmpty) {
      throw ArgumentError('El identificador del hábito es obligatorio.');
    }

    _validateHabit(
      name: name,
      category: category,
      identity: identity,
      context: context,
      motivation: motivation,
      microAction: microAction,
      durationMinutes: durationMinutes,
      scheduledTime: scheduledTime,
      weekDays: weekDays,
    );

    await _userHabits().doc(habitId).update({
      'name': name.trim(),
      'category': category.trim(),
      'identity': identity.trim(),
      'context': context.trim(),
      'motivation': motivation.trim(),
      'microAction': microAction.trim(),
      'durationMinutes': durationMinutes,
      'scheduledTime': scheduledTime,
      'weekDays': weekDays,
    });
  }

  // =====================================================
  // UPDATE: Pausar o reactivar un hábito
  // =====================================================

  Future<void> setHabitActive({
    required String habitId,
    required bool isActive,
  }) async {
    if (habitId.trim().isEmpty) {
      throw ArgumentError('El identificador del hábito es obligatorio.');
    }

    await _userHabits().doc(habitId).update({'isActive': isActive});
  }

  // =====================================================
  // DELETE: Eliminar un hábito personal
  // =====================================================

  Future<void> deleteHabit(String habitId) async {
    if (habitId.trim().isEmpty) {
      throw ArgumentError('El identificador del hábito es obligatorio.');
    }

    await _userHabits().doc(habitId).delete();
  }
}
