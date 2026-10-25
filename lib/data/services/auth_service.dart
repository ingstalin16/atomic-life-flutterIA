import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Registrar usuario y crear su perfil remoto.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase no devolvio un usuario valido.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Iniciar sesion.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Consultar el perfil del usuario autenticado.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final current = _auth.currentUser;

    if (current == null || current.uid != uid) {
      throw StateError('Usuario no autorizado.');
    }

    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  // Validar si el perfil existe y tiene datos basicos.
  Future<bool> hasValidProfile(String uid) async {
    final profile = await getUserProfile(uid);

    if (profile == null) return false;

    final name = profile['name'];
    final email = profile['email'];

    return name is String &&
        name.trim().isNotEmpty &&
        email is String &&
        email.trim().isNotEmpty &&
        email == _auth.currentUser?.email;
  }

  // Cerrar sesion.
  Future<void> logout() {
    return _auth.signOut();
  }

  // Recuperar un perfil que no se guardo durante el registro.
  Future<void> recoverUserProfile({required String name}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Debes iniciar sesion para recuperar tu perfil.');
    }

    final cleanName = name.trim();

    if (cleanName.length < 2 || cleanName.length > 80) {
      throw ArgumentError('El nombre debe tener entre 2 y 80 caracteres.');
    }

    if (user.email == null || user.email!.isEmpty) {
      throw StateError('La cuenta no tiene un correo electronico valido.');
    }

    final profileRef = _firestore.collection('users').doc(user.uid);

    // Leer desde el servidor para no confundir
    // un error de conexion con un perfil inexistente.
    final snapshot = await profileRef.get(
      const GetOptions(source: Source.server),
    );

    // Nunca sobrescribir un perfil existente.
    if (snapshot.exists) {
      throw StateError('El perfil ya existe. Vuelve a verificar tu cuenta.');
    }

    await profileRef.set({
      'name': cleanName,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
