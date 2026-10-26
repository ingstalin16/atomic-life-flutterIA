import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/habit_completion_model.dart';

class HabitCompletionRepository {
  HabitCompletionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _currentUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'Debes iniciar sesión.',
      );
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _completions(String habitId) {
    if (habitId.trim().isEmpty || habitId.contains('/')) {
      throw ArgumentError('Identificador de hábito inválido.');
    }

    final uid = _currentUserId();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .collection('completions');
  }

  // Obtiene la fecha local sin su componente horario.
  DateTime _onlyDate(DateTime date) {
    final local = date.toLocal();

    return DateTime(local.year, local.month, local.day);
  }

  // Evita registrar fechas futuras desde la aplicación.
  void _validateDate(DateTime date) {
    final selected = _onlyDate(date);
    final today = _onlyDate(DateTime.now());

    if (selected.isAfter(today)) {
      throw ArgumentError('No puedes registrar una fecha futura.');
    }
  }

  // MARCAR un hábito como completado.
  Future<void> markCompleted({
    required String habitId,
    required DateTime date,
  }) async {
    _validateDate(date);

    final uid = _currentUserId();
    final dateId = HabitCompletion.dateKey(_onlyDate(date));

    final document = _completions(habitId).doc(dateId);

    final existing = await document.get();

    // El mismo día no debe generar registros duplicados.
    if (existing.exists) {
      return;
    }

    await document.set({
      'habitId': habitId,
      'userId': uid,
      'date': dateId,
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // DESMARCAR un cumplimiento.
  Future<void> unmarkCompleted({
    required String habitId,
    required DateTime date,
  }) async {
    _validateDate(date);

    final dateId = HabitCompletion.dateKey(_onlyDate(date));

    await _completions(habitId).doc(dateId).delete();
  }

  // CONSULTAR si se completó un hábito en una fecha.
  Future<bool> isCompleted({
    required String habitId,
    required DateTime date,
  }) async {
    final dateId = HabitCompletion.dateKey(_onlyDate(date));

    final document = await _completions(habitId).doc(dateId).get();

    if (!document.exists) {
      return false;
    }

    return document.data()?['completed'] == true;
  }

  // CONSULTAR el historial de un hábito.
  Future<List<HabitCompletion>> getHistory({required String habitId}) async {
    final snapshot = await _completions(habitId)
        .orderBy(FieldPath.documentId)
        .get();

    return snapshot.docs.map(HabitCompletion.fromDocument).toList();
  }

  // CONSULTAR registros de un período.
  Future<List<HabitCompletion>> getHistoryBetween({
    required String habitId,
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = HabitCompletion.dateKey(_onlyDate(start));
    final endKey = HabitCompletion.dateKey(_onlyDate(end));

    if (startKey.compareTo(endKey) > 0) {
      throw ArgumentError(
        'La fecha inicial debe ser anterior '
        'o igual a la fecha final.',
      );
    }

    final snapshot = await _completions(habitId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .get();

    return snapshot.docs.map(HabitCompletion.fromDocument).toList();
  }
}
