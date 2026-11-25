
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/categoria.dart';

class CategoriaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categorias =>
      _db.collection('categorias');

  // OBTENER CATEGORÍAS ACTIVAS
  Future<List<Categoria>> obtenerCategorias() async {
    final resultado = await _categorias
        .where('activa', isEqualTo: true)
        .orderBy('nombre')
        .get();

    return resultado.docs.map((documento) {
      return Categoria.fromMap(
        documento.id,
        documento.data(),
      );
    }).toList();
  }

  // OBTENER UNA CATEGORÍA
  Future<Categoria?> obtenerCategoria(String id) async {
    final documento = await _categorias.doc(id).get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return Categoria.fromMap(
      documento.id,
      documento.data()!,
    );
  }

  // ESCUCHAR CAMBIOS EN LAS CATEGORÍAS
  Stream<List<Categoria>> escucharCategorias() {
    return _categorias
        .where('activa', isEqualTo: true)
        .orderBy('nombre')
        .snapshots()
        .map((resultado) {
      return resultado.docs.map((documento) {
        return Categoria.fromMap(
          documento.id,
          documento.data(),
        );
      }).toList();
    });
  }
}
