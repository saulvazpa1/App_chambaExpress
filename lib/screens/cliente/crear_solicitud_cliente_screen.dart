import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'boton_salir.dart';

import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';

class CrearSolicitudClienteScreen extends StatefulWidget {
  const CrearSolicitudClienteScreen({super.key});

  @override
  State<CrearSolicitudClienteScreen> createState() =>
      _CrearSolicitudClienteScreenState();
}

class _CrearSolicitudClienteScreenState
    extends State<CrearSolicitudClienteScreen> {
  static const Color _azul = Color(0xFF1E56A0);

  final _descripcion = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  String? _categoriaId;
  String _categoriaNombre = '';
  bool _enviando = false;
    String _nombrePerfil = '';
  String _telefonoPerfil = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final datos = doc.data();
    if (datos == null || !mounted) return;

    setState(() {
      _nombrePerfil = (datos['nombre'] ?? '').toString();
      _telefonoPerfil = (datos['telefono'] ?? '').toString();
      _telefono.text = _telefonoPerfil;
    });
  }

  @override
  void dispose() {
    _descripcion.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  String _nombre(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      (d.data()['nombre'] ?? d.id).toString();

  Future<void> _enviar() async {
        if (_categoriaId == null ||
        _direccion.text.trim().isEmpty ||
        _telefonoPerfil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }
    if (_descripcion.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La descripción debe tener al menos 10 caracteres')),
      );
      return;
    }
        final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Revisa tu solicitud',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trabajo: $_categoriaNombre',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Descripción: ${_descripcion.text.trim()}'),
            const SizedBox(height: 10),
            Text('Dirección: ${_direccion.text.trim()}'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Editar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB91D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar y enviar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _enviando = true);
    final user = FirebaseAuth.instance.currentUser;

    final id = await SolicitudService().crearSolicitud(
      Solicitud(
        id: '',
        clienteId: user?.uid ?? '',
        clienteNombre: _nombrePerfil,
        clienteTelefono: _telefonoPerfil,
        categoriaId: _categoriaId!,
        categoriaNombre: _categoriaNombre,
        descripcion: _descripcion.text.trim(),
        direccion: _direccion.text.trim(),
        fechaCreacion: DateTime.now(),
      ),
    );

        if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito!'),
          backgroundColor: Color(0xFF1DB91D),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la solicitud')),
      );
    }
  }

        Widget _campo(String etiqueta, TextEditingController c,
      {int lineas = 1,
      TextInputType? tipo,
      IconData? icono,
      bool soloLectura = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: lineas,
          readOnly: soloLectura,
          keyboardType: tipo,
          decoration: InputDecoration(
            filled: true,
            fillColor: soloLectura ? const Color(0xFFE0E0E0) : Colors.white,
            border: const OutlineInputBorder(),
            prefixIcon: icono == null ? null : Icon(icono),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azul,
      appBar: AppBar(
        actions: const [BotonSalir()],
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('ChambaExpress',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Crea aquí tu solicitud',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const Text('Selecciona el trabajo que necesitas:',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('categorias').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  value: _categoriaId,
                  hint: const Text('Elige una categoría'),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: docs
                      .map((d) => DropdownMenuItem(
                          value: d.id, child: Text(_nombre(d))))
                      .toList(),
                  onChanged: (v) {
                    final d = docs.firstWhere((x) => x.id == v);
                    setState(() {
                      _categoriaId = v;
                      _categoriaNombre = _nombre(d);
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _campo('Descripción de por qué necesitas el servicio:',
                _descripcion,
                lineas: 3),
                  _campo('Teléfono de contacto:', _telefono,
                tipo: TextInputType.phone,
                icono: Icons.phone,
                soloLectura: true),
               _campo('Dirección de reparación:', _direccion, icono:Icons.location_on),
            
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB91D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 46),
                ),
                onPressed: _enviando ? null : _enviar,
                child: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}