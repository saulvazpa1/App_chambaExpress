
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> crearPerfilTrabajador() async {
  final usuario = FirebaseAuth.instance.currentUser;

  if (usuario == null) {
    throw Exception('No hay un usuario autenticado.');
  }

  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(usuario.uid)
      .set({
    'uid': usuario.uid,
    'nombre': 'Roberto López',
    'correo': usuario.email ?? '',
    'telefono': '2461234567',
    'rol': 'trabajador',
    'activo': true,
    'fechaRegistro': FieldValue.serverTimestamp(),
    'fotoPerfil': null,
    'especialidades': [],
    'descripcion': '',
    'disponible': true,
    'calificacionPromedio': 0,
    'totalCalificaciones': 0,
    'estadoVerificacion': 'no_verificado',
    'documentosVerificacion': [],
    'ubicacion': null,
  }, SetOptions(merge: true));
}
