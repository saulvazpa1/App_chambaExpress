
import 'package:cloud_firestore/cloud_firestore.dart';

class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono;
  final String? imagen;
  final bool activa;
  final DateTime? fechaCreacion;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    this.imagen,
    required this.activa,
    this.fechaCreacion,
  });

  factory Categoria.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    final fecha = datos['fechaCreacion'];

    return Categoria(
      id: id,
      nombre: datos['nombre'] as String,
      descripcion: datos['descripcion'] as String,
      icono: datos['icono'] as String,
      imagen: datos['imagen'] as String?,
      activa: datos['activa'] as bool? ?? true,
      fechaCreacion: fecha is Timestamp
          ? fecha.toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'imagen': imagen,
      'activa': activa,
      'fechaCreacion':
          Timestamp.fromDate(fechaCreacion ?? DateTime.now()),
    };
  }
}
