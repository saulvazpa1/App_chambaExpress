
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'solicitudes/crear_solicitud_screen.dart';
import 'solicitudes/mis_solicitudes_screen.dart';
import 'trabajador/trabajador_screen.dart';

class InicioScreen extends StatelessWidget {
  final Usuario usuario;

  const InicioScreen({
    super.key,
    required this.usuario,
  });

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (usuario.esTrabajador) {
      return TrabajadorScreen(usuario: usuario);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChambaExpress'),
        actions: [
          IconButton(
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, ${usuario.nombre}!',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Encuentra trabajadores para tus servicios.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.add_circle,
                  color: Colors.deepOrange,
                  size: 35,
                ),
                title: const Text('Publicar un servicio'),
                subtitle: const Text(
                  'Describe qué trabajo necesitas.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CrearSolicitudScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.work_outline,
                  size: 35,
                ),
                title: const Text('Mis solicitudes'),
                subtitle: const Text(
                  'Consulta los servicios que has publicado.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisSolicitudesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
