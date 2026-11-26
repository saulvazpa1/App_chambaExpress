
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color azul = Color(0xFF1E5CA8);
  static const Color fondo = Color(0xFFF4F6FA);
  static const Color texto = Color(0xFF202938);
  static const Color gris = Color(0xFF687386);

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  String _rol = 'cliente';
  bool _cargando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(color: gris),
      prefixIcon: Icon(icono, color: azul),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE1E6EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: azul, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    required IconData icono,
    TextInputType? teclado,
    String? Function(String?)? validar,
    bool ocultar = false,
    Widget? sufijo,
    TextCapitalization capitalizacion = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: ocultar,
      textCapitalization: capitalizacion,
      maxLength: maxLength,
      style: const TextStyle(color: texto, fontSize: 14),
      decoration: _decoracion(
        etiqueta: etiqueta,
        icono: icono,
        sufijo: sufijo,
      ).copyWith(counterText: ''),
      validator: validar,
    );
  }

  Widget _opcionRol({
    required String valor,
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    final seleccionado = _rol == valor;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _cargando
            ? null
            : () => setState(() => _rol = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: seleccionado
                ? azul.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado
                  ? azul
                  : const Color(0xFFE1E6EF),
              width: seleccionado ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icono,
                    color: seleccionado ? azul : gris,
                    size: 25,
                  ),
                  const Spacer(),
                  Icon(
                    seleccionado
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: seleccionado ? azul : gris,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(
                  color: texto,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                descripcion,
                style: const TextStyle(
                  color: gris,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final error = await _authService.registrarUsuario(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        password: _passwordController.text,
        rol: _rol,
      );

      if (!mounted) return;

      setState(() => _cargando = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada correctamente!'),
            backgroundColor: Color(0xFF25A55B),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la cuenta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: texto,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(
            color: texto,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: azul.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      color: azul,
                      size: 39,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Únete a ChambaExpress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: texto,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Crea tu cuenta y comienza a conectar con personas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gris,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 27),

                const Text(
                  'Tus datos',
                  style: TextStyle(
                    color: texto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 13),

                _campo(
                  controller: _nombreController,
                  etiqueta: 'Nombre completo',
                  icono: Icons.person_outline,
                  capitalizacion: TextCapitalization.words,
                  validar: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    if (!RegExp(
                      r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$",
                    ).hasMatch(value.trim())) {
                      return 'El nombre solo debe contener letras';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _campo(
                  controller: _telefonoController,
                  etiqueta: 'Teléfono',
                  icono: Icons.phone_outlined,
                  teclado: TextInputType.phone,
                  maxLength: 10,
                  validar: (value) {
                    if (value == null ||
                        !RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                      return 'Ingresa un teléfono de 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _campo(
                  controller: _correoController,
                  etiqueta: 'Correo electrónico',
                  icono: Icons.email_outlined,
                  teclado: TextInputType.emailAddress,
                  validar: (value) {
                    if (value == null ||
                        !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                            .hasMatch(value.trim())) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),
                const Text(
                  'Seguridad de tu cuenta',
                  style: TextStyle(
                    color: texto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 13),

                _campo(
                  controller: _passwordController,
                  etiqueta: 'Contraseña',
                  icono: Icons.lock_outline,
                  ocultar: !_mostrarPassword,
                  sufijo: IconButton(
                    onPressed: () {
                      setState(() {
                        _mostrarPassword = !_mostrarPassword;
                      });
                    },
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: gris,
                    ),
                  ),
                  validar: (value) {
                    if (value == null || value.length < 6) {
                      return 'Usa al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _campo(
                  controller: _confirmarController,
                  etiqueta: 'Confirmar contraseña',
                  icono: Icons.lock_reset_outlined,
                  ocultar: !_mostrarConfirmacion,
                  sufijo: IconButton(
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmacion = !_mostrarConfirmacion;
                      });
                    },
                    icon: Icon(
                      _mostrarConfirmacion
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: gris,
                    ),
                  ),
                  validar: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 27),
                const Text(
                  '¿Cómo utilizarás ChambaExpress?',
                  style: TextStyle(
                    color: texto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecciona el tipo de cuenta que deseas crear.',
                  style: TextStyle(color: gris, fontSize: 12),
                ),
                const SizedBox(height: 13),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _opcionRol(
                      valor: 'cliente',
                      icono: Icons.search_rounded,
                      titulo: 'Cliente',
                      descripcion: 'Necesito contratar un servicio.',
                    ),
                    const SizedBox(width: 12),
                    _opcionRol(
                      valor: 'trabajador',
                      icono: Icons.build_circle_outlined,
                      titulo: 'Trabajador',
                      descripcion: 'Quiero ofrecer mis servicios.',
                    ),
                  ],
                ),

                const SizedBox(height: 27),
                SizedBox(
                  height: 53,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azul,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          azul.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 23,
                            width: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 20),
                              SizedBox(width: 9),
                              Text(
                                'Crear mi cuenta',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Al crear tu cuenta podrás utilizar ChambaExpress según el perfil que seleccionaste.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gris,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
