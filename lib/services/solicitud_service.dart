
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/solicitud.dart';

class SolicitudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _coleccion = 'solicitudes';

  String? get _usuarioId => FirebaseAuth.instance.currentUser?.uid;

  // REGISTRAR UNA NUEVA SOLICITUD
  Future<String?> crearSolicitud(Solicitud solicitud) async {
    try {
      final datos = solicitud.toMap();
      final documento = await _db.collection(_coleccion).add(datos);

      debugPrint('SOLICITUD CREADA: ${documento.id}');
      return documento.id;
    } catch (e, stackTrace) {
      debugPrint('ERROR AL CREAR SOLICITUD: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  // OBTENER SOLICITUDES DE UN CLIENTE
  Stream<List<Solicitud>> obtenerSolicitudesCliente(String clienteId) {
    return _db
        .collection(_coleccion)
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Solicitud.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // OBTENER SOLICITUDES DISPONIBLES
  Stream<List<Solicitud>> obtenerSolicitudesPendientes() {
    return _db
        .collection(_coleccion)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Solicitud.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ENVIAR PROPUESTA DEL TRABAJADOR
  Future<bool> enviarPropuesta({
    required String solicitudId,
    required String trabajadorId,
    required double precio,
    required DateTime fecha,
    required String hora,
  }) async {
    try {
      final solicitudRef = _db.collection(_coleccion).doc(solicitudId);
      final propuestaRef =
          solicitudRef.collection('propuestas').doc(trabajadorId);

      return await _db.runTransaction<bool>((transaction) async {
        final solicitudDoc = await transaction.get(solicitudRef);
        final propuestaDoc = await transaction.get(propuestaRef);

        if (!solicitudDoc.exists) return false;

        final datos = solicitudDoc.data()!;

        if (datos['estado'] != 'pendiente') return false;
        if (datos['clienteId'] == trabajadorId) return false;
        if (propuestaDoc.exists) return false;

        transaction.set(propuestaRef, {
          'trabajadorId': trabajadorId,
          'precio': precio,
          'fecha': Timestamp.fromDate(fecha),
          'hora': hora,
          'estado': 'enviada',
          'fechaEnvio': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ENVIAR PROPUESTA: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // OBTENER PROPUESTAS DE UNA SOLICITUD
  Stream<List<Map<String, dynamic>>> obtenerPropuestas(
    String solicitudId,
  ) {
    return _db
        .collection(_coleccion)
        .doc(solicitudId)
        .collection('propuestas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // ACEPTAR UNA PROPUESTA
  Future<bool> aceptarPropuesta({
    required String solicitudId,
    required String trabajadorId,
  }) async {
    try {
      final solicitudRef = _db.collection(_coleccion).doc(solicitudId);
      final propuestaRef =
          solicitudRef.collection('propuestas').doc(trabajadorId);

      return await _db.runTransaction<bool>((transaction) async {
        final solicitudDoc = await transaction.get(solicitudRef);
        final propuestaDoc = await transaction.get(propuestaRef);

        if (!solicitudDoc.exists || !propuestaDoc.exists) {
          return false;
        }

        final solicitud = solicitudDoc.data()!;
        final propuesta = propuestaDoc.data()!;

        if (solicitud['estado'] != 'pendiente') return false;
        if (propuesta['estado'] != 'enviada') return false;

        transaction.update(solicitudRef, {
          'estado': 'aceptado',
          'trabajadorId': trabajadorId,
          'precioPropuesto': propuesta['precio'],
          'fechaPropuesta': propuesta['fecha'],
          'horaPropuesta': propuesta['hora'],
          'fechaAceptacion': FieldValue.serverTimestamp(),
        });

        transaction.update(propuestaRef, {
          'estado': 'aceptada',
          'fechaRespuesta': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ACEPTAR PROPUESTA: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // RECHAZAR UNA PROPUESTA
  Future<bool> rechazarPropuesta({
    required String solicitudId,
    required String trabajadorId,
  }) async {
    try {
      final referencia = _db
          .collection(_coleccion)
          .doc(solicitudId)
          .collection('propuestas')
          .doc(trabajadorId);

      await referencia.update({
        'estado': 'rechazada',
        'fechaRespuesta': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, stackTrace) {
      debugPrint('ERROR AL RECHAZAR PROPUESTA: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // OBTENER TRABAJOS ACEPTADOS POR EL TRABAJADOR
  Stream<List<Solicitud>> obtenerSolicitudesEnProceso(
    String trabajadorId,
  ) {
    return _db
        .collection(_coleccion)
        .where('estado', isEqualTo: 'aceptado')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Solicitud.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // MODIFICAR ACUERDO: EL CLIENTE DEBE ACEPTAR EL CAMBIO
  Future<bool> solicitarCambioAcuerdo({
    required String solicitudId,
    required double precio,
    required DateTime fecha,
    required String hora,
  }) async {
    try {
      final trabajadorId = _usuarioId;

      if (trabajadorId == null || precio <= 0 || !precio.isFinite) {
        return false;
      }

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;

        if (datos['estado'] != 'aceptado') return false;
        if (datos['trabajadorId'] != trabajadorId) return false;
        if (datos['cambioPendiente'] != null) return false;

        transaction.update(referencia, {
          'cambioPendiente': {
            'trabajadorId': trabajadorId,
            'precio': precio,
            'fecha': Timestamp.fromDate(fecha),
            'hora': hora,
            'estado': 'pendiente',
            'fechaSolicitud': FieldValue.serverTimestamp(),
          },
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL SOLICITAR CAMBIO: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // OBTENER CAMBIO PENDIENTE PARA EL CLIENTE
  Stream<Map<String, dynamic>?> obtenerCambioPendiente(
    String solicitudId,
  ) {
    return _db
        .collection(_coleccion)
        .doc(solicitudId)
        .snapshots()
        .map((documento) {
      if (!documento.exists) return null;

      final datos = documento.data()!;
      final cambio = datos['cambioPendiente'];

      if (cambio is! Map<String, dynamic>) return null;
      if (cambio['estado'] != 'pendiente') return null;

      return Map<String, dynamic>.from(cambio);
    });
  }

  // CLIENTE ACEPTA LA MODIFICACIÓN
  Future<bool> aceptarCambioAcuerdo(String solicitudId) async {
    try {
      final clienteId = _usuarioId;
      if (clienteId == null) return false;

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;
        final cambio = datos['cambioPendiente'];

        if (datos['clienteId'] != clienteId) return false;
        if (datos['estado'] != 'aceptado') return false;
        if (cambio is! Map<String, dynamic>) return false;
        if (cambio['estado'] != 'pendiente') return false;

        transaction.update(referencia, {
          'precioPropuesto': cambio['precio'],
          'fechaPropuesta': cambio['fecha'],
          'horaPropuesta': cambio['hora'],
          'cambioPendiente': FieldValue.delete(),
          'ultimoCambioRespuesta': 'aceptado',
          'fechaRespuestaCambio': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ACEPTAR CAMBIO: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // CLIENTE RECHAZA LA MODIFICACIÓN
  Future<bool> rechazarCambioAcuerdo(String solicitudId) async {
    try {
      final clienteId = _usuarioId;
      if (clienteId == null) return false;

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;
        final cambio = datos['cambioPendiente'];

        if (datos['clienteId'] != clienteId) return false;
        if (datos['estado'] != 'aceptado') return false;
        if (cambio is! Map<String, dynamic>) return false;
        if (cambio['estado'] != 'pendiente') return false;

        transaction.update(referencia, {
          'cambioPendiente': FieldValue.delete(),
          'ultimoCambioRespuesta': 'rechazado',
          'fechaRespuestaCambio': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL RECHAZAR CAMBIO: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // CANCELAR PEDIDO CON MOTIVO
  Future<bool> cancelarSolicitud({
    required String solicitudId,
    required String motivo,
  }) async {
    try {
      final trabajadorId = _usuarioId;
      final motivoLimpio = motivo.trim();

      if (trabajadorId == null || motivoLimpio.length < 5) {
        return false;
      }

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;

        if (datos['estado'] != 'aceptado') return false;
        if (datos['trabajadorId'] != trabajadorId) return false;

        transaction.update(referencia, {
          'estado': 'cancelada',
          'motivoCancelacion': motivoLimpio,
          'canceladoPor': 'trabajador',
          'fechaCancelacion': FieldValue.serverTimestamp(),
          'cambioPendiente': FieldValue.delete(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL CANCELAR SOLICITUD: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // FINALIZAR TRABAJO
  Future<bool> finalizarSolicitud(String solicitudId) async {
    try {
      final trabajadorId = _usuarioId;
      if (trabajadorId == null) return false;

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;

        if (datos['estado'] != 'aceptado') return false;
        if (datos['trabajadorId'] != trabajadorId) return false;
        if (datos['cambioPendiente'] != null) return false;

        transaction.update(referencia, {
          'estado': 'completada',
          'fechaFinalizacion': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL FINALIZAR SOLICITUD: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // HISTORIAL DEL TRABAJADOR
  Stream<List<Solicitud>> obtenerHistorialTrabajador(
    String trabajadorId,
  ) {
    return _db
        .collection(_coleccion)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where(
          'estado',
          whereIn: ['completada', 'cancelada'],
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Solicitud.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // CALIFICAR UN TRABAJO COMPLETADO
  Future<bool> calificarSolicitud({
    required String solicitudId,
    required int estrellas,
    String comentario = '',
  }) async {
    try {
      final clienteId = _usuarioId;

      if (clienteId == null) return false;
      if (estrellas < 1 || estrellas > 5) return false;
      if (comentario.trim().length > 500) return false;

      final referencia = _db.collection(_coleccion).doc(solicitudId);

      return await _db.runTransaction<bool>((transaction) async {
        final documento = await transaction.get(referencia);

        if (!documento.exists) return false;

        final datos = documento.data()!;

        if (datos['clienteId'] != clienteId) return false;
        if (datos['estado'] != 'completada') return false;
        if (datos['trabajadorId'] == null) return false;
        if (datos['calificacion'] != null) return false;

        transaction.update(referencia, {
          'calificacion': {
            'clienteId': clienteId,
            'trabajadorId': datos['trabajadorId'],
            'estrellas': estrellas,
            'comentario': comentario.trim(),
            'fecha': FieldValue.serverTimestamp(),
          },
        });

        return true;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR AL CALIFICAR SOLICITUD: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // OBTENER CALIFICACIONES DE UN TRABAJADOR
  Stream<List<Map<String, dynamic>>> obtenerCalificacionesTrabajador(
    String trabajadorId,
  ) {
    return _db
        .collection(_coleccion)
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('estado', isEqualTo: 'completada')
        .snapshots()
        .map((snapshot) {
      final calificaciones = <Map<String, dynamic>>[];

      for (final documento in snapshot.docs) {
        final datos = documento.data();
        final calificacion = datos['calificacion'];

        if (calificacion is Map) {
          calificaciones.add({
            'solicitudId': documento.id,
            'categoriaNombre': datos['categoriaNombre'] ?? '',
            'descripcion': datos['descripcion'] ?? '',
            ...Map<String, dynamic>.from(calificacion),
          });
        }
      }

      return calificaciones;
    });
  }

  // ESTADÍSTICAS REALES DE CALIFICACIONES
  Stream<Map<String, dynamic>> obtenerEstadisticasCalificaciones(
    String trabajadorId,
  ) {
    return obtenerCalificacionesTrabajador(trabajadorId).map(
      (calificaciones) {
        if (calificaciones.isEmpty) {
          return {
            'promedio': 0.0,
            'total': 0,
          };
        }

        final suma = calificaciones.fold<int>(
          0,
          (total, item) =>
              total + ((item['estrellas'] as num?)?.toInt() ?? 0),
        );

        return {
          'promedio': suma / calificaciones.length,
          'total': calificaciones.length,
        };
      },
    );
  }
}
