
import 'package:cloud_firestore/cloud_firestore.dart';

class Solicitud {
  final String id;
  final String clienteId;
  final String clienteNombre;
  final String clienteTelefono;
  final String categoriaId;
  final String categoriaNombre;
  final String descripcion;
  final List<String> fotografias;
  final GeoPoint? ubicacion;
  final String direccion;
  final String estado;

  // Datos del acuerdo aceptado
  final String? trabajadorId;
  final double? precioPropuesto;
  final DateTime? fechaPropuesta;
  final String? horaPropuesta;
  final DateTime? fechaPropuestaEnvio;
  final DateTime? fechaAceptacion;

  // Datos de cancelación
  final String? motivoCancelacion;
  final String? canceladoPor;
  final DateTime? fechaCancelacion;

  // Datos de finalización
  final DateTime? fechaFinalizacion;

  // Datos de calificación
  final String? calificacionClienteId;
  final String? calificacionTrabajadorId;
  final int? estrellas;
  final String? comentarioCalificacion;
  final DateTime? fechaCalificacion;

  final DateTime fechaCreacion;

  Solicitud({
    required this.id,
    required this.clienteId,
    this.clienteNombre = '',
    this.clienteTelefono = '',
    required this.categoriaId,
    required this.categoriaNombre,
    required this.descripcion,
    this.fotografias = const [],
    this.ubicacion,
    required this.direccion,
    this.estado = 'pendiente',
    this.trabajadorId,
    this.precioPropuesto,
    this.fechaPropuesta,
    this.horaPropuesta,
    this.fechaPropuestaEnvio,
    required this.fechaCreacion,
    this.fechaAceptacion,
    this.motivoCancelacion,
    this.canceladoPor,
    this.fechaCancelacion,
    this.fechaFinalizacion,
    this.calificacionClienteId,
    this.calificacionTrabajadorId,
    this.estrellas,
    this.comentarioCalificacion,
    this.fechaCalificacion,
  });

  bool get tieneCalificacion => estrellas != null;

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteTelefono': clienteTelefono,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'descripcion': descripcion,
      'fotografias': fotografias,
      'ubicacion': ubicacion,
      'direccion': direccion,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  factory Solicitud.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime? convertirFecha(dynamic valor) {
      if (valor is Timestamp) return valor.toDate();
      if (valor is DateTime) return valor;
      return null;
    }

    final calificacion = map['calificacion'];

    Map<String, dynamic>? datosCalificacion;

    if (calificacion is Map) {
      datosCalificacion = Map<String, dynamic>.from(calificacion);
    }

    return Solicitud(
      id: id,
      clienteId: map['clienteId'] ?? '',
      clienteNombre: map['clienteNombre'] ?? '',
      clienteTelefono: map['clienteTelefono'] ?? '',
      categoriaId: map['categoriaId'] ?? '',
      categoriaNombre: map['categoriaNombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fotografias: List<String>.from(map['fotografias'] ?? []),
      ubicacion: map['ubicacion'] is GeoPoint
          ? map['ubicacion'] as GeoPoint
          : null,
      direccion: map['direccion'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      trabajadorId: map['trabajadorId'] as String?,
      precioPropuesto: (map['precioPropuesto'] as num?)?.toDouble(),
      fechaPropuesta: convertirFecha(map['fechaPropuesta']),
      horaPropuesta: map['horaPropuesta'] as String?,
      fechaPropuestaEnvio: convertirFecha(map['fechaPropuestaEnvio']),
      fechaCreacion:
          convertirFecha(map['fechaCreacion']) ?? DateTime.now(),
      fechaAceptacion: convertirFecha(map['fechaAceptacion']),
      motivoCancelacion: map['motivoCancelacion'] as String?,
      canceladoPor: map['canceladoPor'] as String?,
      fechaCancelacion: convertirFecha(map['fechaCancelacion']),
      fechaFinalizacion: convertirFecha(map['fechaFinalizacion']),

      // Calificación
      calificacionClienteId:
          datosCalificacion?['clienteId'] as String?,
      calificacionTrabajadorId:
          datosCalificacion?['trabajadorId'] as String?,
      estrellas: (datosCalificacion?['estrellas'] as num?)?.toInt(),
      comentarioCalificacion:
          datosCalificacion?['comentario'] as String?,
      fechaCalificacion:
          convertirFecha(datosCalificacion?['fecha']),
    );
  }
}
