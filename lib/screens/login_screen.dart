
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'inicio_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _cargando = false;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await _authService.iniciarSesion(
      correo: _correoController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    try {
      final perfil = await _authService.obtenerPerfilActual();

      if (!mounted) return;

      if (perfil == null ||
          !perfil.activo ||
          (!perfil.esCliente && !perfil.esTrabajador)) {
        await _authService.cerrarSesion();

        if (!mounted) return;

        setState(() => _cargando = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró un perfil válido o activo.',
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioScreen(usuario: perfil),
        ),
      );
    } catch (e) {
      await _authService.cerrarSesion();

      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo recuperar tu perfil.'),
        ),
      );
    }
  }

  InputDecoration _decoracionCampo({
    required String hint,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        color: AppTheme.secondaryColor.withValues(alpha: 0.45),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icono,
        color: AppTheme.primaryColor,
      ),
      suffixIcon: sufijo,
      filled: true,
      fillColor: AppTheme.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.secondaryColor.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.secondaryColor.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.dangerColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.dangerColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _tituloCampo(String texto) {
    return Text(
      texto,
      style: GoogleFonts.openSans(
        fontWeight: FontWeight.w600,
        color: AppTheme.secondaryColor,
        fontSize: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 15),

                  // LOGOTIPO
                  Center(
                    child: Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: AppTheme.surfaceWhite,
                        size: 55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'ChambaExpress',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.epilogue(
                      color: AppTheme.primaryColor,
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tu talento encuentra oportunidades.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF667085),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // FORMULARIO
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(
                            alpha: 0.06,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bienvenido',
                          style: GoogleFonts.epilogue(
                            color: AppTheme.secondaryColor,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Inicia sesión para continuar',
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF667085),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 25),

                        _tituloCampo('Correo electrónico'),

                        const SizedBox(height: 9),

                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.openSans(
                            color: AppTheme.secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: AppTheme.primaryColor,
                          decoration: _decoracionCampo(
                            hint: 'ejemplo@correo.com',
                            icono: Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(value.trim())) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        _tituloCampo('Contraseña'),

                        const SizedBox(height: 9),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_mostrarPassword,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.openSans(
                            color: AppTheme.secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: AppTheme.primaryColor,
                          onFieldSubmitted: (_) {
                            if (!_cargando) _iniciarSesion();
                          },
                          decoration: _decoracionCampo(
                            hint: 'Ingresa tu contraseña',
                            icono: Icons.lock_outline,
                            sufijo: IconButton(
                              icon: Icon(
                                _mostrarPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarPassword = !_mostrarPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: AppTheme.surfaceWhite,
                              disabledBackgroundColor:
                                  AppTheme.successColor.withValues(
                                alpha: 0.5,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.surfaceWhite,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Iniciar sesión',
                                    style: GoogleFonts.openSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Expanded(
                              child: Divider(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '¿Eres nuevo?',
                                style: GoogleFonts.openSans(
                                  color: AppTheme.secondaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Crear una cuenta',
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    'ChambaExpress · Conectando talento y oportunidades',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF98A2B3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
