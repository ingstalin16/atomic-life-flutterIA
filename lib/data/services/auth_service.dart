import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Escuchar los cambios de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el usuario actual.
  User? get currentUser => _auth.currentUser;

  // Registrar un usuario y guardar su perfil.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;

    if (user == null) {
      throw StateError('No se pudo obtener el usuario registrado.');
    }

    // Guardar el perfil en Cloud Firestore.
    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  // Iniciar sesión.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Cerrar sesión.
  Future<void> logout() async {
    await _auth.signOut();
  }
}
