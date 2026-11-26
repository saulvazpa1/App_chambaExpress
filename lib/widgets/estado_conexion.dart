
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class EstadoConexion extends StatefulWidget {
  final Widget child;

  const EstadoConexion({
    super.key,
    required this.child,
  });

  @override
  State<EstadoConexion> createState() => _EstadoConexionState();
}

class _EstadoConexionState extends State<EstadoConexion> {
  final InternetConnection _conexion = InternetConnection();

  StreamSubscription<InternetStatus>? _suscripcion;

  bool _tieneInternet = true;
  bool _comprobando = true;

  @override
  void initState() {
    super.initState();

    _comprobarConexionInicial();

    _suscripcion = _conexion.onStatusChange.listen((estado) {
      if (!mounted) return;

      setState(() {
        _tieneInternet = estado == InternetStatus.connected;
        _comprobando = false;
      });
    });
  }

  Future<void> _comprobarConexionInicial() async {
    try {
      final conectado = await _conexion.hasInternetAccess;

      if (!mounted) return;

      setState(() {
        _tieneInternet = conectado;
        _comprobando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _tieneInternet = false;
        _comprobando = false;
      });
    }
  }

  Future<void> _reintentar() async {
    if (!mounted) return;

    setState(() {
      _comprobando = true;
    });

    await _comprobarConexionInicial();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (!_tieneInternet && !_comprobando)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: const Color(0xFFB31237),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sin conexión a Internet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Algunas funciones no estarán disponibles.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      TextButton(
                        onPressed: _reintentar,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (_comprobando && !_tieneInternet)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF1E5CA8),
            ),
          ),
      ],
    );
  }
}
