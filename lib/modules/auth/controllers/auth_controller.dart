import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/services/auth_service.dart';

// Estados de autenticacion de AtomicLife
enum AuthStatus {
  checking,
  unauthenticated,
  authenticated,
  incompleteProfile,
  error,
}

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  // Usuario autenticado en Firebase
  final Rxn<User> firebaseUser = Rxn<User>();

  // Estado general de autenticacion
  final Rx<AuthStatus> authStatus = AuthStatus.checking.obs;

  // Estados para las operaciones
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<User?>? _authSubscription;

  // Evita que verificaciones antiguas cambien la sesion
  int _validationVersion = 0;

  // Control de operaciones de registro
  bool _registering = false;

  // Usuario actual
  User? get currentUser => firebaseUser.value;

  // Indica si la sesion y el perfil fueron validados
  bool get isLoggedIn => authStatus.value == AuthStatus.authenticated;

  @override
  void onInit() {
    super.onInit();

    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthChange,
      onError: (Object error) {
        errorMessage.value = 'No se pudo comprobar la sesion.';
        authStatus.value = AuthStatus.error;
      },
    );
  }

  // Detecta los cambios de sesion en Firebase
  Future<void> _handleAuthChange(User? user) async {
    final version = ++_validationVersion;

    firebaseUser.value = user;

    if (user == null) {
      errorMessage.value = '';
      authStatus.value = AuthStatus.unauthenticated;
      return;
    }

    authStatus.value = AuthStatus.checking;

    // Durante el registro esperamos a que
    // Firestore termine de guardar el perfil
    if (_registering) return;

    await _validateProfile(user, version);
  }

  // Verifica si el perfil existe en Firestore
  Future<void> _validateProfile(User user, int version) async {
    try {
      final valid = await _authService.hasValidProfile(user.uid);

      // Ignorar resultados de verificaciones anteriores
      if (version != _validationVersion) return;

      // Verificar que el usuario siga siendo el mismo
      if (_authService.currentUser?.uid != user.uid) {
        return;
      }

      if (valid) {
        errorMessage.value = '';
        authStatus.value = AuthStatus.authenticated;
      } else {
        errorMessage.value =
            'Tu cuenta existe, pero necesitamos '
            'completar tu perfil para continuar.';

        authStatus.value = AuthStatus.incompleteProfile;
      }
    } catch (_) {
      if (version != _validationVersion) return;

      errorMessage.value =
          'No pudimos verificar tu perfil. '
          'Comprueba tu conexion a Internet '
          'e intentalo nuevamente.';

      authStatus.value = AuthStatus.error;
    }
  }

  // Volver a comprobar el perfil del usuario
  Future<void> retryValidation() async {
    final user = _authService.currentUser;

    if (user == null) {
      ++_validationVersion;
      firebaseUser.value = null;
      authStatus.value = AuthStatus.unauthenticated;
      return;
    }

    final version = ++_validationVersion;

    firebaseUser.value = user;
    authStatus.value = AuthStatus.checking;

    await _validateProfile(user, version);
  }

  // Registrar un usuario nuevo
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = '';
    _registering = true;

    try {
      final credential = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw StateError('Usuario no disponible.');
      }

      _registering = false;

      // Comprobar el perfil creado en Firestore
      await retryValidation();

      return authStatus.value == AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _handleAuthError(e);

      // No reemplazar incorrectamente el estado
      // cuando Firebase no creo una sesion
      if (_authService.currentUser == null) {
        authStatus.value = AuthStatus.unauthenticated;
      } else {
        authStatus.value = AuthStatus.error;
      }

      return false;
    } catch (_) {
      errorMessage.value =
          'No se pudo completar el registro. '
          'Comprueba tu conexion y verifica '
          'si la cuenta fue creada.';

      // Si Firebase creo la cuenta, permitir
      // una nueva comprobacion del perfil
      if (_authService.currentUser != null) {
        authStatus.value = AuthStatus.error;
      } else {
        authStatus.value = AuthStatus.unauthenticated;
      }

      return false;
    } finally {
      _registering = false;
      isLoading.value = false;
    }
  }

  // Iniciar sesion con correo y contrasena
  Future<bool> login({required String email, required String password}) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw StateError('Usuario no disponible.');
      }

      // Validar el perfil antes de acceder
      await retryValidation();

      return authStatus.value == AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _handleAuthError(e);

      if (_authService.currentUser == null) {
        authStatus.value = AuthStatus.unauthenticated;
      }

      return false;
    } catch (_) {
      errorMessage.value =
          'No se pudo iniciar sesion. '
          'Intentalo nuevamente.';

      if (_authService.currentUser == null) {
        authStatus.value = AuthStatus.unauthenticated;
      }

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Recuperar un perfil faltante en Firestore
  Future<bool> recoverProfile({required String name}) async {
    if (isLoading.value) return false;

    final user = _authService.currentUser;

    if (user == null) {
      errorMessage.value = 'Debes iniciar sesion nuevamente.';

      firebaseUser.value = null;
      authStatus.value = AuthStatus.unauthenticated;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _authService.recoverUserProfile(name: name);

      // Validar nuevamente el perfil recuperado
      await retryValidation();

      return authStatus.value == AuthStatus.authenticated;
    } on ArgumentError catch (e) {
      errorMessage.value = e.message.toString();
      authStatus.value = AuthStatus.incompleteProfile;
      return false;
    } catch (_) {
      errorMessage.value =
          'No fue posible recuperar tu perfil. '
          'Comprueba tu conexion e intentalo nuevamente.';

      authStatus.value = AuthStatus.error;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Cerrar la sesion de Firebase
  Future<bool> logout() async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _authService.logout();

      ++_validationVersion;

      firebaseUser.value = null;
      authStatus.value = AuthStatus.unauthenticated;

      return true;
    } catch (_) {
      errorMessage.value = 'No se pudo cerrar la sesion.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Traducir errores de Firebase Authentication
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya esta registrado.';

      case 'invalid-email':
        return 'El correo electronico no es valido.';

      case 'weak-password':
        return 'La contrasena es demasiado debil.';

      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contrasena incorrectos.';

      case 'network-request-failed':
        return 'Comprueba tu conexion a Internet.';

      case 'too-many-requests':
        return 'Demasiados intentos. '
            'Prueba nuevamente mas tarde.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      default:
        return 'Error de autenticacion: ${e.code}';
    }
  }

  @override
  void onClose() {
    ++_validationVersion;
    _authSubscription?.cancel();
    super.onClose();
  }
}
