import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'boton_salir.dart';

class BarraChamba extends StatelessWidget implements PreferredSizeWidget {
  const BarraChamba({super.key});

  static const Color _azul = Color(0xFF1E56A0);
  static const Color _fondoIcono = Color(0xFFE6EEF8);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _perfil(BuildContext context) {
    final correo = FirebaseAuth.instance.currentUser?.email ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mi perfil'),
        content: Text(correo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _fondoIcono,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.construction, color: _azul),
          ),
          const SizedBox(width: 12),
          const Text('ChambaExpress'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _perfil(context),
          icon: const CircleAvatar(
            backgroundColor: _fondoIcono,
            child: Icon(Icons.person, color: _azul),
          ),
        ),
        const BotonSalir(),
      ],
    );
  }
}