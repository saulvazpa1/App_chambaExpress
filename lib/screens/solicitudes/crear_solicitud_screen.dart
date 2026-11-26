
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/categoria.dart';
import '../../models/solicitud.dart';
import '../../services/categoria_service.dart';
import '../../services/solicitud_service.dart';
import '../../services/cloudinary_service.dart';

class CrearSolicitudScreen extends StatefulWidget {
  const CrearSolicitudScreen({super.key});

  @override
  State<CrearSolicitudScreen> createState() =>
      _CrearSolicitudScreenState();
}

class _CrearSolicitudScreenState
    extends State<CrearSolicitudScreen> {
  static const Color _azul = Color(0xFF1E5CA8);
  static const Color _fondo = Color(0xFFF4F6FA);
  static const Color _texto = Color(0xFF202938);
  static const Color _gris = Color(0xFF687386);
  static const Color _verde = Color(0xFF25B818);

  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();

  final _categoriaService = CategoriaService();
  final _solicitudService = SolicitudService();
  final _cloudinaryService = CloudinaryService();

  final ImagePicker _imagePicker = ImagePicker();
  final Geocoding _geocoding = Geocoding();

  late Future<List<Categoria>> _categoriasFuture;

  String? _categoriaId;
  bool _guardando = false;
  bool _obteniendoUbicacion = false;

  final List<XFile> _fotografias = [];
  GeoPoint? _ubicacion;

  static const int _maxFotografias = 5;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _categoriaService.obtenerCategorias();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    String? ayuda,
    Widget? sufijo,
    bool multilinea = false,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: ayuda,
      labelStyle: const TextStyle(color: _gris),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA4B2),
        fontSize: 13,
      ),
      prefixIcon: multilinea
          ? Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: Icon(icono, color: _azul),
            )
          : Icon(icono, color: _azul),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: multilinea,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
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
        borderSide: const BorderSide(color: _azul, width: 1.5),
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

  Widget _seccion({
    required int numero,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Widget contenido,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _azul.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icono, color: _azul, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$numero. $titulo',
                      style: const TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: _gris,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          contenido,
        ],
      ),
    );
  }

  // SELECCIONAR FOTOGRAFÍAS
  Future<void> _seleccionarFotografias() async {
    if (_fotografias.length >= _maxFotografias) {
      _mostrarMensaje('Solo puedes agregar 5 fotografías.');
      return;
    }

    try {
      final disponibles = _maxFotografias - _fotografias.length;

      final imagenes = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        limit: disponibles,
      );

      if (!mounted || imagenes.isEmpty) return;

      setState(() {
        _fotografias.addAll(imagenes.take(disponibles));
      });
    } catch (e) {
      debugPrint('ERROR AL SELECCIONAR FOTOGRAFÍAS: $e');
      _mostrarMensaje('No se pudieron seleccionar las fotografías: $e');
    }
  }

  // TOMAR FOTOGRAFÍA
  Future<void> _tomarFotografia() async {
    if (_fotografias.length >= _maxFotografias) {
      _mostrarMensaje('Solo puedes agregar 5 fotografías.');
      return;
    }

    try {
      final imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (!mounted || imagen == null) return;

      setState(() {
        _fotografias.add(imagen);
      });
    } catch (e) {
      debugPrint('ERROR AL TOMAR FOTOGRAFÍA: $e');
      _mostrarMensaje('No se pudo tomar la fotografía: $e');
    }
  }

  void _eliminarFotografia(int indice) {
    setState(() {
      _fotografias.removeAt(indice);
    });
  }

  // OBTENER GPS Y DIRECCIÓN
  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoUbicacion = true);

    try {
      final servicioActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        throw Exception('Activa el GPS de tu teléfono.');
      }

      LocationPermission permiso =
          await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception(
          'Debes permitir el acceso a tu ubicación.',
        );
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _ubicacion = GeoPoint(
          posicion.latitude,
          posicion.longitude,
        );
      });

      String direccion = '';

      try {
        final direcciones =
            await _geocoding.placemarkFromCoordinates(
          posicion.latitude,
          posicion.longitude,
        );

        if (direcciones.isNotEmpty) {
          final lugar = direcciones.first;

          direccion = [
            lugar.street,
            lugar.subLocality,
            lugar.locality,
            lugar.administrativeArea,
            lugar.country,
          ]
              .whereType<String>()
              .where((dato) => dato.trim().isNotEmpty)
              .join(', ');
        }
      } catch (e) {
        debugPrint('ERROR AL CONVERTIR GPS EN DIRECCIÓN: $e');
      }

      if (!mounted) return;

      if (direccion.isNotEmpty) {
        setState(() {
          _direccionController.text = direccion;
        });
      }

      _mostrarMensaje(
        direccion.isNotEmpty
            ? 'Dirección y ubicación obtenidas correctamente.'
            : 'GPS obtenido. Puedes escribir la dirección manualmente.',
      );
    } catch (e) {
      debugPrint('ERROR AL OBTENER GPS: $e');

      if (mounted) {
        _mostrarMensaje(
          'No se pudo obtener la ubicación: '
          '${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _obteniendoUbicacion = false);
      }
    }
  }

  // PUBLICAR SOLICITUD
  Future<void> _publicarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensaje('Debes iniciar sesión para publicar.');
      return;
    }

    setState(() => _guardando = true);

    try {
      final perfilDocumento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!perfilDocumento.exists) {
        throw Exception('No se encontró el perfil del cliente.');
      }

      final datosCliente = perfilDocumento.data()!;

      final clienteNombre =
          (datosCliente['nombre'] ?? '').toString().trim();

      final clienteTelefono =
          (datosCliente['telefono'] ?? '').toString().trim();

      if (clienteNombre.isEmpty || clienteTelefono.isEmpty) {
        throw Exception(
          'Tu perfil debe tener nombre y teléfono registrados.',
        );
      }

      final categorias = await _categoriasFuture;

      final categoria = categorias.firstWhere(
        (c) => c.id == _categoriaId,
      );

      final List<String> urlsFotografias = [];

      for (final fotografia in _fotografias) {
        final url = await _cloudinaryService.subirFotografia(
          File(fotografia.path),
        );

        urlsFotografias.add(url);
      }

      final solicitud = Solicitud(
        id: '',
        clienteId: usuario.uid,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        categoriaId: categoria.id,
        categoriaNombre: categoria.nombre,
        descripcion: _descripcionController.text.trim(),
        fotografias: urlsFotografias,
        ubicacion: _ubicacion,
        direccion: _direccionController.text.trim(),
        estado: 'pendiente',
        fechaCreacion: DateTime.now(),
      );

      final id = await _solicitudService.crearSolicitud(solicitud);

      if (!mounted) return;

      if (id == null) {
        throw Exception(
          'No se pudo guardar la solicitud en Firebase. '
          'Revisa la consola para ver el error.',
        );
      }

      _descripcionController.clear();
      _direccionController.clear();

      setState(() {
        _categoriaId = null;
        _fotografias.clear();
        _ubicacion = null;
      });

      _mostrarMensaje('¡Solicitud publicada correctamente!');
    } catch (e) {
      debugPrint('ERROR AL PUBLICAR SOLICITUD: $e');

      if (mounted) {
        _mostrarMensaje('Error al publicar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _botonFotografia({
    required IconData icono,
    required String texto,
    required VoidCallback? accion,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: accion,
        style: OutlinedButton.styleFrom(
          foregroundColor: _azul,
          side: const BorderSide(color: Color(0xFFD5E2F2)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(icono, size: 19),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _fotografiasSeleccionadas() {
    if (_fotografias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE1E6EF),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 35,
              color: Color(0xFF9AA4B2),
            ),
            SizedBox(height: 8),
            Text(
              'Todavía no agregas fotografías',
              style: TextStyle(
                color: _gris,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_fotografias.length, (indice) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_fotografias[indice].path),
                width: 92,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _guardando
                      ? null
                      : () => _eliminarFotografia(indice),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _ubicacionContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _ubicacion == null
                ? _fondo
                : const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _ubicacion == null
                    ? Icons.location_searching
                    : Icons.location_on,
                color: _ubicacion == null ? _gris : _verde,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _ubicacion == null
                      ? 'Aún no has obtenido tu ubicación GPS.'
                      : 'Ubicación GPS obtenida correctamente.',
                  style: TextStyle(
                    color: _ubicacion == null ? _gris : _verde,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_ubicacion != null) ...[
          const SizedBox(height: 10),
          Text(
            'Latitud: ${_ubicacion!.latitude.toStringAsFixed(5)}',
            style: const TextStyle(color: _gris, fontSize: 11),
          ),
          Text(
            'Longitud: ${_ubicacion!.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: _gris, fontSize: 11),
          ),
        ],
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _guardando || _obteniendoUbicacion
                ? null
                : _obtenerUbicacion,
            style: OutlinedButton.styleFrom(
              foregroundColor: _azul,
              side: const BorderSide(color: _azul),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: _obteniendoUbicacion
                ? const SizedBox(
                    height: 17,
                    width: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _azul,
                    ),
                  )
                : const Icon(Icons.my_location, size: 19),
            label: Text(
              _obteniendoUbicacion
                  ? 'Obteniendo ubicación...'
                  : 'Obtener mi ubicación actual',
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulario(List<Categoria> categorias) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: _azul,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.handyman_outlined,
                  color: Colors.white,
                  size: 29,
                ),
                SizedBox(height: 13),
                Text(
                  'Publica tu servicio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cuéntanos qué necesitas. Los trabajadores podrán revisar tu solicitud y enviarte sus propuestas.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _seccion(
            numero: 1,
            titulo: 'Tipo de servicio',
            subtitulo: 'Selecciona la categoría que necesitas.',
            icono: Icons.category_outlined,
            contenido: DropdownButtonFormField<String>(
              initialValue: _categoriaId,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: _texto,
                fontSize: 13,
              ),
              decoration: _decoracion(
                etiqueta: 'Categoría',
                icono: Icons.work_outline,
              ),
              items: categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria.id,
                  child: Text(
                    categoria.nombre,
                    style: const TextStyle(color: _texto),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _guardando
                  ? null
                  : (valor) {
                      setState(() {
                        _categoriaId = valor;
                      });
                    },
              validator: (valor) {
                if (valor == null) {
                  return 'Selecciona una categoría';
                }
                return null;
              },
            ),
          ),

          _seccion(
            numero: 2,
            titulo: 'Describe lo que necesitas',
            subtitulo: 'Explica el trabajo con el mayor detalle posible.',
            icono: Icons.description_outlined,
            contenido: TextFormField(
              controller: _descripcionController,
              maxLines: 5,
              maxLength: 500,
              enabled: !_guardando,
              style: const TextStyle(
                color: _texto,
                fontSize: 13,
                height: 1.4,
              ),
              decoration: _decoracion(
                etiqueta: 'Descripción del servicio',
                icono: Icons.edit_note,
                ayuda: 'Ej. Necesito reparar una fuga de agua en el baño...',
                multilinea: true,
              ),
              validator: (valor) {
                if (valor == null || valor.trim().length < 10) {
                  return 'Describe un poco más el servicio (mínimo 10 caracteres).';
                }
                return null;
              },
            ),
          ),

          _seccion(
            numero: 3,
            titulo: 'Fotografías',
            subtitulo: 'Ayuda a los trabajadores a entender el problema.',
            icono: Icons.photo_library_outlined,
            contenido: Column(
              children: [
                Row(
                  children: [
                    _botonFotografia(
                      icono: Icons.photo_library_outlined,
                      texto: 'Galería',
                      accion: _guardando
                          ? null
                          : _seleccionarFotografias,
                    ),
                    const SizedBox(width: 10),
                    _botonFotografia(
                      icono: Icons.camera_alt_outlined,
                      texto: 'Cámara',
                      accion: _guardando
                          ? null
                          : _tomarFotografia,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Text(
                      'Fotografías agregadas',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_fotografias.length}/$_maxFotografias',
                      style: const TextStyle(
                        color: _azul,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _fotografiasSeleccionadas(),
              ],
            ),
          ),

          _seccion(
            numero: 4,
            titulo: 'Ubicación del servicio',
            subtitulo: 'Indica dónde se realizará el trabajo.',
            icono: Icons.location_on_outlined,
            contenido: Column(
              children: [
                TextFormField(
                  controller: _direccionController,
                  maxLines: 2,
                  enabled: !_guardando,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 13,
                  ),
                  decoration: _decoracion(
                    etiqueta: 'Dirección',
                    icono: Icons.home_outlined,
                    ayuda: 'Calle, colonia, municipio...',
                    multilinea: true,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa la dirección del servicio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _ubicacionContenido(),
              ],
            ),
          ),

          const SizedBox(height: 3),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _publicarSolicitud,
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _azul.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _guardando ? 'Publicando servicio...' : 'Publicar solicitud',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Revisa que tus datos sean correctos antes de publicar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _gris,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _texto,
        elevation: 0,
        title: const Text(
          'Publicar servicio',
          style: TextStyle(
            color: _texto,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<Categoria>>(
        future: _categoriasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _azul),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar las categorías.',
                style: TextStyle(color: _texto),
              ),
            );
          }

          final categorias = snapshot.data ?? [];

          if (categorias.isEmpty) {
            return const Center(
              child: Text(
                'No hay categorías disponibles.',
                style: TextStyle(color: _texto),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: _formulario(categorias),
          );
        },
      ),
    );
  }
}
