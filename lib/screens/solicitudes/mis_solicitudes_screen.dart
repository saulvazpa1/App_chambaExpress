
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() =>
      _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState
    extends State<MisSolicitudesScreen> {
  final SolicitudService _service = SolicitudService();

  final Map<String, int> _estrellasSeleccionadas = {};
  final Map<String, TextEditingController> _comentarios = {};
  final Set<String> _enviando = {};
  final Set<String> _respondiendo = {};

  static const Color _azul = Color(0xFF1E5CA8);
  static const Color _fondo = Color(0xFFF4F6FA);
  static const Color _texto = Color(0xFF202938);
  static const Color _gris = Color(0xFF687386);
  static const Color _verde = Color(0xFF25A55B);
  static const Color _rojo = Color(0xFFCF4050);

  String? get _clienteId =>
      FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    for (final controller in _comentarios.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controladorComentario(String id) {
    return _comentarios.putIfAbsent(
      id,
      () => TextEditingController(),
    );
  }

  void _mensaje(String mensaje) {
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

  String _fecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  DateTime? _convertirFecha(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completada':
        return _verde;
      case 'aceptado':
        return _azul;
      case 'cancelada':
        return _rojo;
      default:
        return const Color(0xFFD18A24);
    }
  }

  String _nombreEstado(String estado) {
    switch (estado) {
      case 'completada':
        return 'Completada';
      case 'aceptado':
        return 'En proceso';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _calificar(Solicitud solicitud) async {
    final estrellas =
        _estrellasSeleccionadas[solicitud.id] ?? 0;

    if (estrellas < 1 || estrellas > 5) {
      _mensaje('Selecciona de 1 a 5 estrellas.');
      return;
    }

    setState(() => _enviando.add(solicitud.id));

    final correcto = await _service.calificarSolicitud(
      solicitudId: solicitud.id,
      estrellas: estrellas,
      comentario: _controladorComentario(solicitud.id).text,
    );

    if (!mounted) return;

    setState(() => _enviando.remove(solicitud.id));

    if (correcto) {
      _mensaje('¡Gracias por calificar al trabajador!');
    } else {
      _mensaje(
        'No se pudo registrar la calificación. '
        'Verifica que el trabajo esté completado y no haya sido calificado.',
      );
    }
  }

  Future<bool> _confirmarRespuesta({
    required String titulo,
    required String mensaje,
    required String textoBoton,
    required Color color,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          titulo,
          style: const TextStyle(
            color: _texto,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: _gris),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Volver',
              style: TextStyle(color: _gris),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(textoBoton),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  Future<void> _responderPropuesta({
    required String solicitudId,
    required String trabajadorId,
    required bool aceptar,
  }) async {
    final confirmado = await _confirmarRespuesta(
      titulo: aceptar ? 'Aceptar propuesta' : 'Rechazar propuesta',
      mensaje: aceptar
          ? '¿Deseas aceptar esta propuesta? El trabajo quedará asignado a este trabajador.'
          : '¿Deseas rechazar esta propuesta?',
      textoBoton: aceptar ? 'Aceptar' : 'Rechazar',
      color: aceptar ? _verde : _rojo,
    );

    if (!confirmado || !mounted) return;

    final llave = '${solicitudId}_$trabajadorId';

    setState(() => _respondiendo.add(llave));

    final correcto = aceptar
        ? await _service.aceptarPropuesta(
            solicitudId: solicitudId,
            trabajadorId: trabajadorId,
          )
        : await _service.rechazarPropuesta(
            solicitudId: solicitudId,
            trabajadorId: trabajadorId,
          );

    if (!mounted) return;

    setState(() => _respondiendo.remove(llave));

    if (correcto) {
      _mensaje(
        aceptar
            ? '¡Propuesta aceptada! El trabajo está en proceso.'
            : 'Propuesta rechazada.',
      );
    } else {
      _mensaje(
        'No se pudo procesar la propuesta. '
        'Es posible que la solicitud ya haya cambiado de estado.',
      );
    }
  }

  Widget _etiquetaEstado(String estado) {
    final color = _colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _nombreEstado(estado),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _datoSolicitud({
    required IconData icono,
    required String texto,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 17, color: _gris),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: _gris,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezadoSeccion({
    required IconData icono,
    required String titulo,
  }) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: _azul.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: _azul, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: _texto,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _estrellas({
    required int seleccionadas,
    required ValueChanged<int> onSeleccionar,
    bool bloqueadas = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final numero = indice + 1;

        return IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: bloqueadas
              ? null
              : () => onSeleccionar(numero),
          icon: Icon(
            numero <= seleccionadas
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _propuestas(Solicitud solicitud) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.obtenerPropuestas(solicitud.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'No se pudieron cargar las propuestas.',
              style: TextStyle(color: _rojo),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(color: _azul),
            ),
          );
        }

        final propuestas = snapshot.data!
            .where((p) =>
                p['estado'] == 'enviada' ||
                p['estado'] == 'aceptada' ||
                p['estado'] == 'rechazada')
            .toList();

        propuestas.sort((a, b) {
          final fechaA = _convertirFecha(a['fechaEnvio']);
          final fechaB = _convertirFecha(b['fechaEnvio']);

          return (fechaB ?? DateTime(2000))
              .compareTo(fechaA ?? DateTime(2000));
        });

        final pendientes = propuestas
            .where((p) => p['estado'] == 'enviada')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            _encabezadoSeccion(
              icono: Icons.people_alt_outlined,
              titulo: 'Propuestas recibidas',
            ),
            const SizedBox(height: 12),

            if (propuestas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  pendientes == 1
                      ? 'Tienes 1 propuesta pendiente de revisar.'
                      : 'Tienes $pendientes propuestas pendientes de revisar.',
                  style: const TextStyle(
                    color: _gris,
                    fontSize: 12,
                  ),
                ),
              ),

            if (propuestas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: _fondo,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7EAF0)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: Color(0xFF9AA4B2),
                      size: 32,
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Aún no tienes propuestas',
                      style: TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Cuando un trabajador se interese en tu servicio, su propuesta aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _gris,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            ...propuestas.map((propuesta) {
              final trabajadorId =
                  propuesta['trabajadorId']?.toString() ?? '';

              final precio =
                  (propuesta['precio'] as num?)?.toDouble() ?? 0;

              final fecha = _convertirFecha(propuesta['fecha']);
              final hora = propuesta['hora']?.toString() ?? 'Sin hora';
              final estado = propuesta['estado']?.toString() ?? '';

              final llave = '${solicitud.id}_$trabajadorId';
              final procesando = _respondiendo.contains(llave);

              final esNueva = estado == 'enviada';
              final esAceptada = estado == 'aceptada';

              return Container(
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: esAceptada
                        ? _verde.withValues(alpha: 0.35)
                        : const Color(0xFFE5EAF1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 43,
                          width: 43,
                          decoration: BoxDecoration(
                            color: _azul.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: _azul,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trabajador interesado',
                                style: TextStyle(
                                  color: _texto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ID: $trabajadorId',
                                style: const TextStyle(
                                  color: _gris,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: esAceptada
                                ? const Color(0xFFE5F6EB)
                                : estado == 'rechazada'
                                    ? const Color(0xFFFFE9E9)
                                    : const Color(0xFFE8F0FC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            esAceptada
                                ? 'Aceptada'
                                : estado == 'rechazada'
                                    ? 'Rechazada'
                                    : 'Nueva',
                            style: TextStyle(
                              color: esAceptada
                                  ? _verde
                                  : estado == 'rechazada'
                                      ? _rojo
                                      : _azul,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRECIO OFRECIDO',
                            style: TextStyle(
                              color: _gris,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: _verde,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 13),
                    _datoSolicitud(
                      icono: Icons.calendar_month_outlined,
                      texto: 'Fecha propuesta: ${_fecha(fecha)}',
                    ),
                    _datoSolicitud(
                      icono: Icons.access_time_rounded,
                      texto: 'Horario propuesto: $hora',
                    ),

                    if (esNueva &&
                        solicitud.estado == 'pendiente') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _rojo,
                                side: const BorderSide(color: _rojo),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: procesando
                                  ? null
                                  : () => _responderPropuesta(
                                        solicitudId: solicitud.id,
                                        trabajadorId: trabajadorId,
                                        aceptar: false,
                                      ),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Rechazar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _verde,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: procesando
                                  ? null
                                  : () => _responderPropuesta(
                                        solicitudId: solicitud.id,
                                        trabajadorId: trabajadorId,
                                        aceptar: true,
                                      ),
                              icon: procesando
                                  ? const SizedBox(
                                      height: 17,
                                      width: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                              label: Text(
                                procesando ? 'Procesando...' : 'Aceptar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _seccionAcuerdo(Solicitud solicitud) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoSeccion(
            icono: Icons.handshake_outlined,
            titulo: 'Acuerdo del servicio',
          ),
          const SizedBox(height: 13),
          _datoSolicitud(
            icono: Icons.payments_outlined,
            texto: 'Precio: \$${solicitud.precioPropuesto?.toStringAsFixed(2) ?? 'Sin definir'}',
          ),
          _datoSolicitud(
            icono: Icons.calendar_month_outlined,
            texto: 'Fecha: ${_fecha(solicitud.fechaPropuesta)}',
          ),
          _datoSolicitud(
            icono: Icons.access_time_rounded,
            texto: 'Hora: ${solicitud.horaPropuesta ?? 'Sin definir'}',
          ),
        ],
      ),
    );
  }

  Widget _seccionCalificacion(Solicitud solicitud) {
    if (solicitud.tieneCalificacion) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAEC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFF3E7C7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezadoSeccion(
              icono: Icons.star_rounded,
              titulo: 'Tu calificación',
            ),
            const SizedBox(height: 10),
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
                    color: _texto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if ((solicitud.comentarioCalificacion ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${solicitud.comentarioCalificacion}"',
                style: const TextStyle(
                  color: _gris,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF3E7C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoSeccion(
            icono: Icons.star_outline_rounded,
            titulo: 'Califica el servicio',
          ),
          const SizedBox(height: 7),
          const Text(
            '¿Cómo fue tu experiencia con el trabajador?',
            style: TextStyle(
              color: _gris,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Center(
            child: _estrellas(
              seleccionadas:
                  _estrellasSeleccionadas[solicitud.id] ?? 0,
              onSeleccionar: (valor) {
                setState(() {
                  _estrellasSeleccionadas[solicitud.id] = valor;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controladorComentario(solicitud.id),
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: _texto),
            decoration: InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: 'Cuéntanos cómo fue el servicio.',
              labelStyle: const TextStyle(color: _gris),
              hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _azul, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              onPressed: _enviando.contains(solicitud.id)
                  ? null
                  : () => _calificar(solicitud),
              icon: _enviando.contains(solicitud.id)
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.star_rounded),
              label: Text(
                _enviando.contains(solicitud.id)
                    ? 'Enviando...'
                    : 'Enviar calificación',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Solicitud solicitud) {
    final estado = solicitud.estado;

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.045),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE9EDF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: DefaultTextStyle(
          style: const TextStyle(color: _texto),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: _azul.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: _azul,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERVICIO SOLICITADO',
                            style: TextStyle(
                              color: _gris,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            solicitud.categoriaNombre,
                            style: const TextStyle(
                              color: _texto,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _etiquetaEstado(estado),
                ],
              ),

              const SizedBox(height: 17),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _fondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  solicitud.descripcion,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 14),
              _datoSolicitud(
                icono: Icons.location_on_outlined,
                texto: solicitud.direccion,
              ),
              _datoSolicitud(
                icono: Icons.calendar_today_outlined,
                texto: 'Publicada el ${_fecha(solicitud.fechaCreacion)}',
              ),

              if (solicitud.trabajadorId != null)
                _seccionAcuerdo(solicitud),

              if (estado == 'pendiente')
                _propuestas(solicitud),

              if (estado == 'cancelada') ...[
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            color: _rojo,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Solicitud cancelada',
                            style: TextStyle(
                              color: _rojo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Motivo: ${solicitud.motivoCancelacion ?? 'No especificado'}',
                        style: const TextStyle(
                          color: _texto,
                          fontSize: 12,
                        ),
                      ),
                      if (solicitud.canceladoPor != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          solicitud.canceladoPor == 'trabajador'
                              ? 'Cancelado por el trabajador'
                              : 'Cancelado por el cliente',
                          style: const TextStyle(
                            color: _gris,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (estado == 'completada') ...[
                const SizedBox(height: 14),
                _datoSolicitud(
                  icono: Icons.check_circle_outline,
                  texto: 'Trabajo finalizado: ${_fecha(solicitud.fechaFinalizacion)}',
                ),
                _seccionCalificacion(solicitud),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pantallaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 95,
              width: 95,
              decoration: BoxDecoration(
                color: _azul.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_off_outlined,
                size: 43,
                color: _azul,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no tienes solicitudes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _texto,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Cuando publiques un servicio, podrás consultar aquí su estado y las propuestas de los trabajadores.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _gris,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clienteId = _clienteId;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _texto,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mis solicitudes',
          style: TextStyle(
            color: _texto,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: clienteId == null
          ? const Center(
              child: Text(
                'Debes iniciar sesión para ver tus solicitudes.',
                style: TextStyle(color: _texto),
              ),
            )
          : StreamBuilder<List<Solicitud>>(
              stream: _service.obtenerSolicitudesCliente(clienteId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error al cargar tus solicitudes.',
                      style: TextStyle(color: _rojo),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _azul),
                  );
                }

                final solicitudes = [...snapshot.data!];

                if (solicitudes.isEmpty) {
                  return _pantallaVacia();
                }

                solicitudes.sort(
                  (a, b) =>
                      b.fechaCreacion.compareTo(a.fechaCreacion),
                );

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 25),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    return _tarjeta(solicitudes[index]);
                  },
                );
              },
            ),
    );
  }
}
