
import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nombre;
  final String correo;
  final String telefono;
  final String rol;
  final bool activo;
  final DateTime? fechaRegistro;
  final String? fotoPerfil;
  final GeoPoint? ubicacion;

  // Campos exclusivos del trabajador
  final List<String> especialidades;
  final String? descripcion;
  final bool? disponible;
  final double? calificacionPromedio;
  final int? totalCalificaciones;
  final String? estadoVerificacion;
  final List<Map<String, dynamic>> documentosVerificacion;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.activo,
    this.fechaRegistro,
    this.fotoPerfil,
    this.ubicacion,
    this.especialidades = const [],
    this.descripcion,
    this.disponible,
    this.calificacionPromedio,
    this.totalCalificaciones,
    this.estadoVerificacion,
    this.documentosVerificacion = const [],
  });

  bool get esCliente => rol == 'cliente';

  bool get esTrabajador => rol == 'trabajador';

  factory Usuario.fromMap(
    Map<String, dynamic> datos,
  ) {
    final fecha = datos['fechaRegistro'];

    return Usuario(
      uid: datos['uid'] as String,
      nombre: datos['nombre'] as String,
      correo: datos['correo'] as String,
      telefono: datos['telefono'] as String,
      rol: datos['rol'] as String,
      activo: datos['activo'] as bool? ?? true,

      fechaRegistro: fecha is Timestamp
          ? fecha.toDate()
          : null,

      fotoPerfil: datos['fotoPerfil'] as String?,

      ubicacion: datos['ubicacion'] is GeoPoint
          ? datos['ubicacion'] as GeoPoint
          : null,

      especialidades:
          List<String>.from(datos['especialidades'] ?? []),

      descripcion: datos['descripcion'] as String?,

      disponible: datos['disponible'] as bool?,

      calificacionPromedio:
          (datos['calificacionPromedio'] as num?)?.toDouble(),

      totalCalificaciones:
          (datos['totalCalificaciones'] as num?)?.toInt(),

      estadoVerificacion:
          datos['estadoVerificacion'] as String?,

      documentosVerificacion:
          (datos['documentosVerificacion'] as List<dynamic>? ?? [])
              .map((documento) =>
                  Map<String, dynamic>.from(documento as Map))
              .toList(),
    );
  }
}
