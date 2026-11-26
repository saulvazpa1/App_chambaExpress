import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'propuesta_screen.dart';

import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';
import 'crear_solicitud_cliente_screen.dart';
  import 'barra_chamba.dart';

class SolicitudesActualesScreen extends StatelessWidget {
  const SolicitudesActualesScreen({super.key});

  static const Color _azul = Color(0xFF1E56A0);

    String _hace(DateTime fecha) {
    final d = DateTime.now().difference(fecha);
    if (d.inMinutes < 1) return 'hace un momento';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} día(s)';
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'En espera';
      case 'aceptado':
        return 'En proceso';
      default:
        return estado;
    }
  }

    @override
  Widget build(BuildContext context) {
    final clienteId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _azul,
         appBar: const BarraChamba(),
      body: StreamBuilder<List<Solicitud>>(
        stream: SolicitudService().obtenerSolicitudesCliente(clienteId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar',
                  style: TextStyle(color: Colors.white)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final lista = snapshot.data!
              .where((s) => s.estado == 'pendiente' || s.estado == 'aceptado')
              .toList()
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Solicitudes actuales',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (lista.isEmpty)
                const Text('Aún no tienes solicitudes.',
                    style: TextStyle(color: Colors.white70)),
                  ...lista.map((s) => _tarjeta(context, s)),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                minimumSize: const Size(90, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                     builder: (_) => const CrearSolicitudClienteScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    ),
    );
  }
      Widget _tarjeta(BuildContext context, Solicitud s) {
    return InkWell(
      onTap: s.estado == 'pendiente'
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropuestasScreen(solicitud: s),
                ),
              )
          : null,
      child: Card(
        color: Colors.black,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.categoriaNombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(s.descripcion,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Publicado\n${_hace(s.fechaCreacion)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(_textoEstado(s.estado),
                      style: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}