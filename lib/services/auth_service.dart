
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTRAR USUARIO
  Future<String?> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String telefono,
    required String rol,
  }) async {
    UserCredential? resultado;

    try {
      if (!['cliente', 'trabajador'].contains(rol)) {
        return 'El tipo de usuario no es válido.';
      }

      resultado = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );

      final usuario = resultado.user!;

      final datosUsuario = <String, dynamic>{
        'uid': usuario.uid,
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'telefono': telefono.trim(),
        'rol': rol,
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fotoPerfil': null,
        'ubicacion': null,
      };

      if (rol == 'trabajador') {
        datosUsuario.addAll({
          'especialidades': <String>[],
          'descripcion': '',
          'disponible': true,
          'calificacionPromedio': 0.0,
          'totalCalificaciones': 0,
          'estadoVerificacion': 'no_verificado',
          'documentosVerificacion': <Map<String, dynamic>>[],
        });
      }

      await _db
          .collection('usuarios')
          .doc(usuario.uid)
          .set(datosUsuario);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al registrar usuario';
    } catch (e) {
      if (resultado?.user != null) {
        try {
          await resultado!.user!.delete();
        } catch (_) {}
      }

      return 'Error al crear el perfil: $e';
    }
  }

  // INICIAR SESIÓN
  Future<String?> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error al iniciar sesión';
    } catch (e) {
      return 'Error al iniciar sesión: $e';
    }
  }

  // OBTENER PERFIL POR UID
  Future<Usuario?> obtenerPerfil(String uid) async {
    try {
      final documento =
          await _db.collection('usuarios').doc(uid).get();

      if (!documento.exists || documento.data() == null) {
        return null;
      }

      return Usuario.fromMap(documento.data()!);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // OBTENER PERFIL DEL USUARIO ACTUAL
  Future<Usuario?> obtenerPerfilActual() async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return null;
    }

    return obtenerPerfil(usuario.uid);
  }

  // CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // USUARIO ACTUAL DE FIREBASE AUTH
  User? get usuarioActual => _auth.currentUser;

  // ESTADO DE AUTENTICACIÓN
  Stream<User?> get estadoAutenticacion =>
      _auth.authStateChanges();
}
