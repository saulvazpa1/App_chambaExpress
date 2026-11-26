import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/solicitud.dart';
import '../../services/solicitud_service.dart';

class PropuestasScreen extends StatelessWidget {
  final Solicitud solicitud;

  const PropuestasScreen({super.key, required this.solicitud});

  static const Color _azul = Color(0xFF1E56A0);
  static const Color _verde = Color(0xFF1DB91D);

  DateTime? _fecha(dynamic v) => v is Timestamp ? v.toDate() : null;

  String _etiquetaDia(DateTime f) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(f.year, f.month, f.day);
    final texto = '${f.day} ${meses[f.month - 1]} ${f.year}';
    final diff = dia.difference(hoy).inDays;
    if (diff == 0) return 'Hoy - $texto';
    if (diff == 1) return 'Mañana - $texto';
    return texto;
  }

  Future<void> _confirmar(BuildContext context, Map<String, dynamic> p) async {
    final f = _fecha(p['fecha']);
    final fechaTxt = f == null
        ? ''
        : '${f.day.toString().padLeft(2, '0')}/'
              '${f.month.toString().padLeft(2, '0')}/${f.year}';
    final precio = (p['precio'] as num?)?.toDouble() ?? 0;

    final aceptar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '¿Quieres aceptar esta propuesta?',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(solicitud.categoriaNombre),
            const SizedBox(height: 14),
            const Text('Fecha y hora del trabajo:'),
            Text(
              '$fechaTxt - ${p['hora']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text('Precio:'),
            Text(
              '\$${precio.toStringAsFixed(0)} pesos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar propuesta'),
          ),
        ],
      ),
    );

    if (aceptar != true || !context.mounted) return;

    final exito = await SolicitudService().aceptarPropuesta(
      solicitudId: solicitud.id,
      trabajadorId: p['id'] as String,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito ? '¡Propuesta aceptada!' : 'No se pudo aceptar la propuesta',
        ),
        backgroundColor: exito ? _verde : Colors.red,
      ),
    );
    if (exito) Navigator.pop(context);
  }

  Widget _fila(BuildContext context, Map<String, dynamic> p, int n) {
    final precio = (p['precio'] as num?)?.toDouble() ?? 0;
    final nombre = (p['trabajadorNombre'] ?? 'Propuesta $n').toString();
    final promedio = (p['promedio'] as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (promedio != null)
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < promedio.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                Text(
                  '${solicitud.categoriaNombre} - ${p['hora']} - '
                  '\$${precio.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _confirmar(context, p),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
    Future<void> _cancelar(BuildContext context) async {
    const motivos = [
      'Ya no lo necesito',
      'Encontré otro servicio',
      'Tardó demasiado',
      'Otro motivo',
    ];
    String motivo = motivos.first;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text(
            '¿Estás seguro de cancelar la solicitud?',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elige el motivo por el que cancelas la solicitud.'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: motivo,
                isExpanded: true,
                items: motivos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setLocal(() => motivo = v ?? motivo),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA50034),
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar solicitud'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(solicitud.id)
          .update({
        'estado': 'cancelada',
        'motivoCancelacion': motivo,
        'canceladoPor': 'cliente',
        'fechaCancelacion': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ERROR AL CANCELAR: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar la solicitud'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azul,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'ChambaExpress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SolicitudService().obtenerPropuestas(solicitud.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar las propuestas',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final lista =
              snapshot.data!.where((p) => p['estado'] == 'enviada').toList()
                ..sort((a, b) {
                  final fa = _fecha(a['fecha']) ?? DateTime(2100);
                  final fb = _fecha(b['fecha']) ?? DateTime(2100);
                  return fa.compareTo(fb);
                });

          final filas = <Widget>[];
          String? ultima;
          for (var i = 0; i < lista.length; i++) {
            final f = _fecha(lista[i]['fecha']);
            final etiqueta = f == null ? 'Sin fecha' : _etiquetaDia(f);
            if (etiqueta != ultima) {
              ultima = etiqueta;
              filas.add(
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    etiqueta,
                    style: const TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
              filas.add(const Divider(color: Colors.white));
            }
            filas.add(_fila(context, lista[i], i + 1));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Propuestas recibidas:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.categoriaNombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                                        Text(solicitud.descripcion,
                          style: const TextStyle(color: Colors.white)),
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          title: const Text('Ver detalles',
                              style: TextStyle(color: Colors.greenAccent)),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (solicitud.fotografias.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        solicitud.fotografias.first,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Text(
                                                'No se pudo cargar la foto',
                                                style: TextStyle(
                                                    color: Colors.white70)),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  const Text('Dirección:',
                                      style: TextStyle(color: Colors.white70)),
                                  Text(solicitud.direccion,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                  const SizedBox(height: 10),
                                  const Text('Número de contacto:',
                                      style: TextStyle(color: Colors.white70)),
                                  Text(solicitud.clienteTelefono,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (solicitud.estado == 'pendiente')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA50034),
                              foregroundColor: Colors.white),
                          onPressed: () => _cancelar(context),
                          child: const Text('Cancelar solicitud'),
                        ),
                    ],    
                  ),
                ),
              ),
              if (filas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Aún no hay propuestas de trabajadores.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ...filas,
            ],
          );
        },
      ),
    );
  }
}
