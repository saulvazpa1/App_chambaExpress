import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../login_screen.dart';

class BotonSalir extends StatelessWidget {
  const BotonSalir({super.key});

  Future<void> _salir(BuildContext context) async {
    await AuthService().cerrarSesion();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Color(0xFFA50034)),
      tooltip: 'Cerrar sesión',
      onPressed: () => _salir(context),
    );
  }
}