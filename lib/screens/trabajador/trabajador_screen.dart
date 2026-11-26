
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../login_screen.dart';
import '../../models/usuario.dart';
import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_theme.dart';

class TrabajadorScreen extends StatefulWidget {
  final Usuario usuario;

  const TrabajadorScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<TrabajadorScreen> createState() => _TrabajadorScreenState();
}

class _TrabajadorScreenState extends State<TrabajadorScreen> {
  int _pestanaSeleccionada = 0;

  final SolicitudService _solicitudService = SolicitudService();

  static const Color azul = AppTheme.primaryColor;
  static const Color negro = AppTheme.secondaryColor;
  static const Color verde = AppTheme.successColor;
  static const Color gris = Color(0xFF52606D);

  // CERRAR SESIÓN
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudo cerrar la sesión. Inténtalo nuevamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backColor,
      body: SafeArea(
        child: Column(
          children: [
            _construirEncabezado(),
            Expanded(child: _construirContenido()),
          ],
        ),
      ),
      bottomNavigationBar: _construirNavegacion(),
    );
  }

  // ENCABEZADO
  Widget _construirEncabezado() {
    final foto = widget.usuario.fotoPerfil;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: azul.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.handyman_outlined,
              color: azul,
              size: 27,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'ChambaExpress',
              style: TextStyle(
                color: negro,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: azul.withValues(alpha: 0.12),
            backgroundImage: foto != null && foto.isNotEmpty
                ? NetworkImage(foto)
                : null,
            child: foto == null || foto.isEmpty
                ? const Icon(Icons.person, color: azul)
                : null,
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.dangerColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // CONTENIDO DE LAS PESTAÑAS
  Widget _construirContenido() {
    switch (_pestanaSeleccionada) {
      case 0:
        return _construirPedidosDisponibles();
      case 1:
        return _construirPedidosProceso();
      case 2:
        return _construirHistorial();
      default:
        return const SizedBox();
    }
  }

  // PEDIDOS DISPONIBLES
  Widget _construirPedidosDisponibles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, ${widget.usuario.nombre}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Pedidos actuales',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Encuentra nuevas oportunidades de trabajo.',
                style: TextStyle(
                  color: Color(0xFFDCE8F7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Solicitud>>(
            stream: _solicitudService.obtenerSolicitudesPendientes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _construirEstado(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'No se pudieron cargar los pedidos',
                  mensaje: 'Comprueba tu conexión e inténtalo nuevamente.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final solicitudes = snapshot.data ?? [];

              if (solicitudes.isEmpty) {
                return _construirEstado(
                  icono: Icons.work_outline,
                  titulo: 'No hay pedidos disponibles',
                  mensaje:
                      'Cuando un cliente publique un servicio, aparecerá aquí.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  return _tarjetaSolicitud(solicitudes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // TARJETA DE PEDIDO DISPONIBLE
  Widget _tarjetaSolicitud(Solicitud solicitud) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: negro,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _mostrarDetalleSolicitud(solicitud),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: azul.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitud.categoriaNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      solicitud.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCFD6DE),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF9AA5B1),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _tiempoTranscurrido(solicitud.fechaCreacion),
                          style: const TextStyle(
                            color: Color(0xFF9AA5B1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: verde,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DETALLE DEL PEDIDO
  void _mostrarDetalleSolicitud(
    Solicitud solicitud, {
    bool permitirPropuesta = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 15, 22, 12),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  solicitud.categoriaNombre,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: negro,
                                  ),
                                ),
                              ),
                              _etiquetaEstado(
                                permitirPropuesta ? 'Disponible' : 'Aceptado',
                                permitirPropuesta ? Colors.orange : verde,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _tituloSeccion(
                            Icons.person_outline,
                            'Datos del cliente',
                          ),
                          const SizedBox(height: 12),
                          _datoCliente(
                            Icons.person,
                            'Nombre',
                            solicitud.clienteNombre.isNotEmpty
                                ? solicitud.clienteNombre
                                : 'No disponible',
                          ),
                          const SizedBox(height: 10),
                          _datoCliente(
                            Icons.phone_outlined,
                            'Teléfono',
                            solicitud.clienteTelefono.isNotEmpty
                                ? solicitud.clienteTelefono
                                : 'No disponible',
                          ),
                          if (solicitud.clienteTelefono.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _llamarCliente(
                                  solicitud.clienteTelefono,
                                ),
                                icon: const Icon(Icons.call),
                                label: const Text('Llamar al cliente'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: verde,
                                  side: const BorderSide(color: verde),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 23),
                          _tituloSeccion(
                            Icons.description_outlined,
                            'Descripción del problema',
                          ),
                          const SizedBox(height: 10),
                          _contenedorTexto(solicitud.descripcion),
                          const SizedBox(height: 23),
                          _tituloSeccion(
                            Icons.photo_library_outlined,
                            'Fotografías de referencia',
                          ),
                          const SizedBox(height: 11),
                          if (solicitud.fotografias.isEmpty)
                            const Text(
                              'El cliente no adjuntó fotografías.',
                              style: TextStyle(color: gris),
                            )
                          else
                            SizedBox(
                              height: 125,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: solicitud.fotografias.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _abrirGaleria(
                                      solicitud.fotografias,
                                      index,
                                      solicitud.id,
                                    ),
                                    child: Hero(
                                      tag: 'foto_${solicitud.id}_$index',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.network(
                                          solicitud.fotografias[index],
                                          width: 140,
                                          height: 125,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 140,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (solicitud.fotografias.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            const Text(
                              'Toca una fotografía para ampliarla.',
                              style: TextStyle(
                                color: gris,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 23),
                          _tituloSeccion(
                            Icons.location_on_outlined,
                            'Dirección del servicio',
                          ),
                          const SizedBox(height: 10),
                          _contenedorTexto(
                            solicitud.direccion.isNotEmpty
                                ? solicitud.direccion
                                : 'Dirección no disponible',
                            icono: Icons.location_on,
                          ),
                          const SizedBox(height: 11),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _abrirMapa(solicitud),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text(
                                'Ver ubicación en Google Maps',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: azul,
                                side: const BorderSide(color: azul),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                          if (!permitirPropuesta) ...[
                            const SizedBox(height: 23),
                            _tituloSeccion(
                              Icons.handshake_outlined,
                              'Acuerdo actual',
                            ),
                            const SizedBox(height: 12),
                            _datoCliente(
                              Icons.attach_money,
                              'Precio acordado',
                              solicitud.precioPropuesto != null
                                  ? '\$${solicitud.precioPropuesto!.toStringAsFixed(2)}'
                                  : 'Sin precio registrado',
                            ),
                            const SizedBox(height: 12),
                            _datoCliente(
                              Icons.calendar_month_outlined,
                              'Fecha acordada',
                              solicitud.fechaPropuesta != null
                                  ? _formatoFecha(solicitud.fechaPropuesta!)
                                  : 'Sin fecha registrada',
                            ),
                            const SizedBox(height: 12),
                            _datoCliente(
                              Icons.access_time,
                              'Hora acordada',
                              solicitud.horaPropuesta ?? 'Sin hora registrada',
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: gris,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _tiempoTranscurrido(solicitud.fechaCreacion),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: gris,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (permitirPropuesta)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _mostrarFormularioPropuesta(solicitud);
                        },
                        icon: const Icon(Icons.request_quote_outlined),
                        label: const Text('Enviar propuesta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: gris),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _etiquetaEstado(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _contenedorTexto(String texto, {IconData? icono}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, color: azul),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: negro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FORMULARIO PARA ENVIAR PROPUESTA O EDITAR ACUERDO
  Future<void> _mostrarFormularioPropuesta(
    Solicitud solicitud, {
    bool editar = false,
  }) async {
    final precioController = TextEditingController(
      text: editar && solicitud.precioPropuesto != null
          ? solicitud.precioPropuesto!.toString()
          : '',
    );

    DateTime? fechaSeleccionada =
        editar ? solicitud.fechaPropuesta : null;

    TimeOfDay? horaSeleccionada =
        editar ? _convertirHora(solicitud.horaPropuesta) : null;

    bool enviando = false;
    String? errorFormulario;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, actualizarDialogo) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 12,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: azul.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        editar
                            ? Icons.edit_calendar_outlined
                            : Icons.request_quote_outlined,
                        color: azul,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editar ? 'Editar acuerdo' : 'Enviar propuesta',
                            style: const TextStyle(
                              color: negro,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            editar
                                ? 'El cliente deberá aprobar los cambios'
                                : 'Ofrece tus servicios al cliente',
                            style: const TextStyle(
                              color: gris,
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5FA),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.handyman_outlined,
                              color: azul,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SERVICIO SOLICITADO',
                                    style: TextStyle(
                                      color: gris,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    solicitud.categoriaNombre,
                                    style: const TextStyle(
                                      color: negro,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (editar) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'El acuerdo actual no cambiará hasta que el cliente acepte tu solicitud.',
                          style: TextStyle(
                            color: gris,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 21),
                      const Text(
                        '¿Cuánto cobrarás?',
                        style: TextStyle(
                          color: negro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: precioController,
                        enabled: !enviando,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: negro,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej. 500.00',
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: azul,
                          ),
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(
                            color: azul,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F9FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E6ED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: azul,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 21),
                      const Text(
                        '¿Qué día puedes realizarlo?',
                        style: TextStyle(
                          color: negro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _campoSeleccionPropuesta(
                        icono: Icons.calendar_month_outlined,
                        texto: fechaSeleccionada == null
                            ? 'Seleccionar fecha'
                            : _formatoFecha(fechaSeleccionada!),
                        seleccionado: fechaSeleccionada != null,
                        onTap: enviando
                            ? null
                            : () async {
                                final ahora = DateTime.now();

                                final fecha = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: fechaSeleccionada ??
                                      DateTime(
                                        ahora.year,
                                        ahora.month,
                                        ahora.day,
                                      ),
                                  firstDate: DateTime(
                                    ahora.year,
                                    ahora.month,
                                    ahora.day,
                                  ),
                                  lastDate: ahora.add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: azul,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: negro,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (fecha != null) {
                                  actualizarDialogo(() {
                                    fechaSeleccionada = fecha;
                                    errorFormulario = null;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '¿A qué hora puedes asistir?',
                        style: TextStyle(
                          color: negro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _campoSeleccionPropuesta(
                        icono: Icons.access_time_rounded,
                        texto: horaSeleccionada == null
                            ? 'Seleccionar hora'
                            : _formatoHora(horaSeleccionada!),
                        seleccionado: horaSeleccionada != null,
                        onTap: enviando
                            ? null
                            : () async {
                                final hora = await showTimePicker(
                                  context: dialogContext,
                                  initialTime:
                                      horaSeleccionada ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: azul,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: negro,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (hora != null) {
                                  actualizarDialogo(() {
                                    horaSeleccionada = hora;
                                    errorFormulario = null;
                                  });
                                }
                              },
                      ),
                      if (errorFormulario != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.dangerColor,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorFormulario!,
                                  style: const TextStyle(
                                    color: AppTheme.dangerColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: enviando
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: gris,
                            side: const BorderSide(
                              color: Color(0xFFE0E6ED),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: enviando
                              ? null
                              : () async {
                                  final precio = double.tryParse(
                                    precioController.text
                                        .trim()
                                        .replaceAll(',', '.'),
                                  );

                                  if (precio == null ||
                                      !precio.isFinite ||
                                      precio <= 0) {
                                    actualizarDialogo(() {
                                      errorFormulario =
                                          'Ingresa un precio válido.';
                                    });
                                    return;
                                  }

                                  if (fechaSeleccionada == null) {
                                    actualizarDialogo(() {
                                      errorFormulario =
                                          'Selecciona una fecha disponible.';
                                    });
                                    return;
                                  }

                                  if (horaSeleccionada == null) {
                                    actualizarDialogo(() {
                                      errorFormulario =
                                          'Selecciona una hora disponible.';
                                    });
                                    return;
                                  }

                                  actualizarDialogo(() {
                                    enviando = true;
                                    errorFormulario = null;
                                  });

                                  try {
                                    final resultado = editar
                                        ? await _solicitudService
                                            .solicitarCambioAcuerdo(
                                            solicitudId: solicitud.id,
                                            precio: precio,
                                            fecha: fechaSeleccionada!,
                                            hora: _formatoHora(
                                              horaSeleccionada!,
                                            ),
                                          )
                                        : await _solicitudService.enviarPropuesta(
                                            solicitudId: solicitud.id,
                                            trabajadorId: widget.usuario.uid,
                                            precio: precio,
                                            fecha: fechaSeleccionada!,
                                            hora: _formatoHora(
                                              horaSeleccionada!,
                                            ),
                                          );

                                    if (!dialogContext.mounted) return;

                                    if (resultado) {
                                      Navigator.pop(dialogContext);

                                      if (mounted) {
                                        _mostrarMensaje(
                                          editar
                                              ? 'Solicitud de cambio enviada. Espera la respuesta del cliente.'
                                              : '¡Propuesta enviada correctamente!',
                                        );
                                      }
                                    } else {
                                      actualizarDialogo(() {
                                        enviando = false;
                                        errorFormulario = editar
                                            ? 'No se pudo solicitar el cambio. Comprueba que no exista otra solicitud pendiente.'
                                            : 'No se pudo enviar. El pedido puede ya no estar disponible o ya enviaste una propuesta.';
                                      });
                                    }
                                  } catch (e) {
                                    if (!dialogContext.mounted) return;

                                    actualizarDialogo(() {
                                      enviando = false;
                                      errorFormulario =
                                          'Ocurrió un error. Inténtalo nuevamente.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verde,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                verde.withValues(alpha: 0.5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: enviando
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  editar
                                      ? 'Solicitar cambios'
                                      : 'Enviar propuesta',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      precioController.dispose();
    }
  }

  // CONVERTIR HORA GUARDADA A TIMEOFDAY
  TimeOfDay? _convertirHora(String? horaTexto) {
    if (horaTexto == null || horaTexto.trim().isEmpty) {
      return null;
    }

    try {
      final texto = horaTexto.trim().toUpperCase();
      final partes = texto.split(' ');
      final horaPartes = partes[0].split(':');

      int hora = int.parse(horaPartes[0]);
      final minuto = int.parse(horaPartes[1]);

      if (partes.length > 1) {
        if (partes[1] == 'PM' && hora != 12) hora += 12;
        if (partes[1] == 'AM' && hora == 12) hora = 0;
      }

      return TimeOfDay(hour: hora, minute: minuto);
    } catch (_) {
      return null;
    }
  }

  String _formatoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  String _formatoHora(TimeOfDay hora) {
    final periodo = hora.period == DayPeriod.am ? 'AM' : 'PM';
    final horaFormato = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final minutos = hora.minute.toString().padLeft(2, '0');

    return '$horaFormato:$minutos $periodo';
  }

  // CAMPO PARA SELECCIONAR FECHA Y HORA
  Widget _campoSeleccionPropuesta({
    required IconData icono,
    required String texto,
    required bool seleccionado,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: seleccionado
                  ? azul.withValues(alpha: 0.5)
                  : const Color(0xFFE0E6ED),
            ),
          ),
          child: Row(
            children: [
              Icon(icono, color: azul, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: seleccionado ? negro : gris,
                    fontSize: 13,
                    fontWeight:
                        seleccionado ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: gris,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TÍTULO DE SECCIÓN
  Widget _tituloSeccion(IconData icono, String titulo) {
    return Row(
      children: [
        Icon(icono, color: azul, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            color: negro,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // DATOS DEL CLIENTE
  Widget _datoCliente(
    IconData icono,
    String etiqueta,
    String valor,
  ) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: azul.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icono, color: azul, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  color: gris,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: const TextStyle(
                  color: negro,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // LLAMAR AL CLIENTE
  Future<void> _llamarCliente(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);

    try {
      final resultado = await launchUrl(uri);

      if (!resultado && mounted) {
        _mostrarMensaje(
          'No se pudo abrir la aplicación de llamadas.',
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al intentar llamar al cliente.');
      }
    }
  }

  // ABRIR GOOGLE MAPS
  Future<void> _abrirMapa(Solicitud solicitud) async {
    final ubicacion = solicitud.ubicacion;

    final String consulta;

    if (ubicacion != null) {
      consulta = '${ubicacion.latitude},${ubicacion.longitude}';
    } else if (solicitud.direccion.isNotEmpty) {
      consulta = solicitud.direccion;
    } else {
      _mostrarMensaje(
        'Este pedido no tiene una ubicación disponible.',
      );
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': consulta,
      },
    );

    try {
      final resultado = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!resultado && mounted) {
        _mostrarMensaje('No se pudo abrir Google Maps.');
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('No se pudo abrir la ubicación.');
      }
    }
  }

  // ABRIR GALERÍA
  void _abrirGaleria(
    List<String> fotografias,
    int indiceInicial,
    String solicitudId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GaleriaFotografiasScreen(
          fotografias: fotografias,
          indiceInicial: indiceInicial,
          solicitudId: solicitudId,
        ),
      ),
    );
  }

  // PEDIDOS EN PROCESO
  Widget _construirPedidosProceso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus trabajos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'En proceso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Aquí encontrarás los pedidos que has aceptado.',
                style: TextStyle(
                  color: Color(0xFFDCE8F7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Solicitud>>(
            stream: _solicitudService.obtenerSolicitudesEnProceso(
              widget.usuario.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _construirEstado(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'No se pudieron cargar tus trabajos',
                  mensaje:
                      'Comprueba tu conexión e inténtalo nuevamente.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final solicitudes = snapshot.data ?? [];

              if (solicitudes.isEmpty) {
                return _construirEstado(
                  icono: Icons.handyman_outlined,
                  titulo: 'Todavía no tienes trabajos',
                  mensaje:
                      'Cuando un cliente acepte tu propuesta, aparecerá aquí automáticamente.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  return _tarjetaEnProceso(solicitudes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // TARJETA DE PEDIDO ACEPTADO
  Widget _tarjetaEnProceso(Solicitud solicitud) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: negro,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: verde.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _mostrarDetalleSolicitud(
                solicitud,
                permitirPropuesta: false,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          solicitud.categoriaNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _etiquetaEstado('Aceptado', verde),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    solicitud.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCFD6DE),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFF9AA5B1),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          solicitud.clienteNombre.isNotEmpty
                              ? solicitud.clienteNombre
                              : 'Cliente',
                          style: const TextStyle(
                            color: Color(0xFFCFD6DE),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: verde,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: verde,
                        size: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _datoAcuerdo(
                    Icons.attach_money,
                    'Precio',
                    solicitud.precioPropuesto != null
                        ? '\$${solicitud.precioPropuesto!.toStringAsFixed(2)}'
                        : 'Sin registrar',
                  ),
                  const SizedBox(height: 9),
                  _datoAcuerdo(
                    Icons.calendar_month_outlined,
                    'Fecha',
                    solicitud.fechaPropuesta != null
                        ? _formatoFecha(solicitud.fechaPropuesta!)
                        : 'Sin registrar',
                  ),
                  const SizedBox(height: 9),
                  _datoAcuerdo(
                    Icons.access_time,
                    'Hora',
                    solicitud.horaPropuesta ?? 'Sin registrar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _mostrarFormularioPropuesta(
                        solicitud,
                        editar: true,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text(
                      'Editar acuerdo',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: azul),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDialogoCancelar(solicitud),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text(
                      'Cancelar pedido',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7B7B),
                      side: const BorderSide(
                        color: Color(0xFFFF7B7B),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmarFinalizar(solicitud),
                icon: const Icon(Icons.check_circle_outline, size: 19),
                label: const Text('Finalizar trabajo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoAcuerdo(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          color: const Color(0xFFB8C7D8),
          size: 17,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 55,
          child: Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFFB8C7D8),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // CANCELAR PEDIDO
  Future<void> _mostrarDialogoCancelar(Solicitud solicitud) async {
    final motivoController = TextEditingController();
    bool procesando = false;
    String? error;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, actualizarDialogo) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.dangerColor,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Cancelar pedido',
                        style: TextStyle(
                          color: negro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Por qué necesitas cancelar este trabajo? '
                        'El cliente podrá consultar el motivo.',
                        style: TextStyle(
                          color: gris,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: motivoController,
                        enabled: !procesando,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Escribe el motivo de la cancelación...',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: AppTheme.dangerColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: procesando
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Volver'),
                  ),
                  ElevatedButton(
                    onPressed: procesando
                        ? null
                        : () async {
                            final motivo = motivoController.text.trim();

                            if (motivo.length < 5) {
                              actualizarDialogo(() {
                                error =
                                    'Escribe un motivo de al menos 5 caracteres.';
                              });
                              return;
                            }

                            actualizarDialogo(() {
                              procesando = true;
                              error = null;
                            });

                            try {
                              final resultado =
                                  await _solicitudService.cancelarSolicitud(
                                solicitudId: solicitud.id,
                                motivo: motivo,
                              );

                              if (!dialogContext.mounted) return;

                              if (resultado) {
                                Navigator.pop(dialogContext);

                                if (mounted) {
                                  _mostrarMensaje(
                                    'El pedido fue cancelado.',
                                  );
                                }
                              } else {
                                actualizarDialogo(() {
                                  procesando = false;
                                  error =
                                      'No se pudo cancelar el pedido. Inténtalo nuevamente.';
                                });
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              actualizarDialogo(() {
                                procesando = false;
                                error =
                                    'Ocurrió un error al cancelar el pedido.';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerColor,
                      foregroundColor: Colors.white,
                    ),
                    child: procesando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar cancelación'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      motivoController.dispose();
    }
  }

  // FINALIZAR TRABAJO
  Future<void> _confirmarFinalizar(Solicitud solicitud) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: verde),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Finalizar trabajo',
                style: TextStyle(
                  color: negro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Confirmas que realizaste y terminaste este trabajo? '
          'El pedido pasará a tu historial.',
          style: TextStyle(
            color: gris,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Todavía no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: verde,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final resultado =
          await _solicitudService.finalizarSolicitud(solicitud.id);

      if (!mounted) return;

      if (resultado) {
        _mostrarMensaje(
          '¡Trabajo finalizado! Ya puedes consultarlo en tu historial.',
        );
      } else {
        _mostrarMensaje(
          'No se pudo finalizar. Comprueba que no exista una modificación pendiente.',
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          'Ocurrió un error al finalizar el trabajo.',
        );
      }
    }
  }

  // HISTORIAL CON CALIFICACIONES
  Widget _construirHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus actividades',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Historial de trabajos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Consulta tus trabajos y las opiniones de tus clientes.',
                style: TextStyle(
                  color: Color(0xFFDCE8F7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // PROMEDIO Y TOTAL DE CALIFICACIONES
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _solicitudService.obtenerEstadisticasCalificaciones(
              widget.usuario.uid,
            ),
            builder: (context, snapshot) {
              final estadisticas = snapshot.data ?? {
                'promedio': 0.0,
                'total': 0,
              };

              final promedio =
                  (estadisticas['promedio'] as num?)?.toDouble() ?? 0.0;
              final total =
                  (estadisticas['total'] as num?)?.toInt() ?? 0;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: negro,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 53,
                      height: 53,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tu calificación',
                            style: TextStyle(
                              color: Color(0xFFCFD6DE),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                promedio.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 7),
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < promedio.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 17,
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: verde,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Opiniones',
                          style: TextStyle(
                            color: Color(0xFFCFD6DE),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // LISTA DEL HISTORIAL
        Expanded(
          child: StreamBuilder<List<Solicitud>>(
            stream: _solicitudService.obtenerHistorialTrabajador(
              widget.usuario.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _construirEstado(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'No se pudo cargar el historial',
                  mensaje:
                      'Comprueba tu conexión e inténtalo nuevamente.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final solicitudes = snapshot.data ?? [];

              if (solicitudes.isEmpty) {
                return _construirEstado(
                  icono: Icons.history,
                  titulo: 'Tu historial está vacío',
                  mensaje:
                      'Los trabajos que finalices o canceles aparecerán aquí.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  return _tarjetaHistorial(solicitudes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // TARJETA DEL HISTORIAL Y OPINIÓN DEL CLIENTE
  Widget _tarjetaHistorial(Solicitud solicitud) {
    final completada = solicitud.estado == 'completada';
    final colorEstado = completada ? verde : AppTheme.dangerColor;
    final textoEstado = completada ? 'Completado' : 'Cancelado';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: negro,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colorEstado.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  solicitud.categoriaNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _etiquetaEstado(textoEstado, colorEstado),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            solicitud.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCFD6DE),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          _datoAcuerdo(
            Icons.person_outline,
            'Cliente',
            solicitud.clienteNombre.isNotEmpty
                ? solicitud.clienteNombre
                : 'No disponible',
          ),
          const SizedBox(height: 9),
          _datoAcuerdo(
            Icons.attach_money,
            'Precio',
            solicitud.precioPropuesto != null
                ? '\$${solicitud.precioPropuesto!.toStringAsFixed(2)}'
                : 'No registrado',
          ),

          if (completada && solicitud.fechaFinalizacion != null) ...[
            const SizedBox(height: 9),
            _datoAcuerdo(
              Icons.event_available_outlined,
              'Finalizado',
              _formatoFecha(solicitud.fechaFinalizacion!),
            ),
          ],

          // CALIFICACIÓN DEL CLIENTE
          if (completada) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.25),
                ),
              ),
              child: solicitud.tieneCalificacion
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 19,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Calificación del cliente',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < (solicitud.estrellas ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 23,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${solicitud.estrellas}/5',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (solicitud.comentarioCalificacion != null &&
                            solicitud.comentarioCalificacion!.trim().isNotEmpty) ...[
                          const SizedBox(height: 11),
                          const Text(
                            'Comentario',
                            style: TextStyle(
                              color: Color(0xFFFFD77A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            solicitud.comentarioCalificacion!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: Colors.amber,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este trabajo todavía no tiene una calificación.',
                            style: TextStyle(
                              color: Color(0xFFDCE8F7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],

          // MOTIVO DE CANCELACIÓN
          if (!completada &&
              solicitud.motivoCancelacion != null &&
              solicitud.motivoCancelacion!.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motivo de cancelación',
                    style: TextStyle(
                      color: Color(0xFFFF9A9A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    solicitud.motivoCancelacion!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ESTADOS VACÍOS Y DE ERROR
  Widget _construirEstado({
    required IconData icono,
    required String titulo,
    required String mensaje,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icono,
                color: Colors.white,
                size: 43,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFDCE8F7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NAVEGACIÓN INFERIOR
  Widget _construirNavegacion() {
    final iconos = [
      Icons.mail_outline,
      Icons.handyman_outlined,
      Icons.access_time,
    ];

    final titulos = [
      'Pedidos',
      'En proceso',
      'Historial',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          child: Row(
            children: List.generate(3, (index) {
              final seleccionado = _pestanaSeleccionada == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _pestanaSeleccionada = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconos[index],
                          color: seleccionado ? verde : gris,
                          size: 25,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titulos[index],
                          style: TextStyle(
                            color: seleccionado ? verde : gris,
                            fontSize: 11,
                            fontWeight: seleccionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // MENSAJES
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // TIEMPO TRANSCURRIDO
  String _tiempoTranscurrido(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);

    if (diferencia.isNegative || diferencia.inMinutes < 1) {
      return 'Publicado hace un momento';
    }

    if (diferencia.inHours < 1) {
      return 'Publicado hace ${diferencia.inMinutes} min';
    }

    if (diferencia.inDays < 1) {
      return 'Publicado hace ${diferencia.inHours} h';
    }

    if (diferencia.inDays == 1) {
      return 'Publicado hace 1 día';
    }

    return 'Publicado hace ${diferencia.inDays} días';
  }
}

// GALERÍA DE FOTOGRAFÍAS
class GaleriaFotografiasScreen extends StatefulWidget {
  final List<String> fotografias;
  final int indiceInicial;
  final String solicitudId;

  const GaleriaFotografiasScreen({
    super.key,
    required this.fotografias,
    required this.indiceInicial,
    required this.solicitudId,
  });

  @override
  State<GaleriaFotografiasScreen> createState() =>
      _GaleriaFotografiasScreenState();
}

class _GaleriaFotografiasScreenState
    extends State<GaleriaFotografiasScreen> {
  late final PageController _pageController;
  late int _indiceActual;

  @override
  void initState() {
    super.initState();

    _indiceActual = widget.indiceInicial;
    _pageController = PageController(
      initialPage: widget.indiceInicial,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_indiceActual + 1} de ${widget.fotografias.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.fotografias.length,
        onPageChanged: (indice) {
          setState(() {
            _indiceActual = indice;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: Hero(
              tag: 'foto_${widget.solicitudId}_$index',
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  widget.fotografias[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
