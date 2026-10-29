import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'viaje_en_curso.dart';
import 'finalizar_viaje.dart';

String conductorServiceLabel(Trip trip) {
  final mode = (trip.serviceMode ?? '').trim().toLowerCase();
  final service =
      mode.contains('taxi') || mode.contains('viaje') ? 'Viajes' : 'Envíos';
  final vehicle = conductorVehicleLabel(trip);
  return vehicle.isEmpty ? service : '$service · $vehicle';
}

String conductorVehicleLabel(Trip trip) {
  for (final value in [trip.vehicleVariant, trip.truckType, trip.transport]) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return '';
}

String conductorQuantityLabel(Trip trip) {
  final mode = (trip.serviceMode ?? '').toLowerCase();
  if (mode.contains('taxi') || mode.contains('viaje')) {
    final passengers = trip.passengerCount ?? 0;
    return '$passengers pasajero${passengers == 1 ? '' : 's'}';
  }
  return '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}';
}

String _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return '';
}

String conductorPaymentLabel(Trip trip) {
  final rawStatus = _firstNonEmpty(
    [trip.servicePaymentStatus, trip.paymentStatus],
  ).toLowerCase();
  final status = rawStatus == 'pagado'
      ? 'Pagado'
      : rawStatus == 'parcial'
          ? 'Parcial'
          : 'Pendiente';
  final method = _firstNonEmpty(
    [trip.servicePaymentMethod, trip.paymentMethod],
  );
  return method.isEmpty ? status : '$status · $method';
}

String conductorPaymentMethodLabel(Trip trip) =>
    _firstNonEmpty([trip.servicePaymentMethod, trip.paymentMethod]);

/// Las fotos del paquete se guardan actualmente en la descripción como
/// `Evidencias: url1, url2`. Se mantiene este lector para que los viajes
/// existentes también puedan mostrar su foto sin cambiar el contrato de la API.
List<String> conductorPackagePhotoUrls(Trip trip) {
  if (trip.packagePhotos.isNotEmpty) {
    return trip.packagePhotos.map(_resolveEvidenceUrl).toList();
  }
  final description = trip.description ?? '';
  final match = RegExp(
    r'Evidencias:\s*(.*?)(?:\s·\s|$)',
    caseSensitive: false,
  ).firstMatch(description);
  if (match == null) return const [];
  return match
      .group(1)!
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .map(_resolveEvidenceUrl)
      .toList();
}

String _resolveEvidenceUrl(String value) {
  final base = Uri.parse(apiClient.baseUrl);
  final parsed = Uri.tryParse(value);
  var rawPath = parsed?.path.isNotEmpty == true ? parsed!.path : value;
  if (!rawPath.startsWith('/') && !rawPath.contains('/')) {
    rawPath = '/uploads/evidence/$rawPath';
  }
  final basePath = base.path.replaceFirst(RegExp(r'/$'), '');
  final path = rawPath.startsWith(basePath)
      ? rawPath
      : '$basePath${rawPath.startsWith('/') ? rawPath : '/$rawPath'}';
  return base.replace(path: path, query: parsed?.query ?? '').toString();
}

String conductorPackageLabel(Trip trip) {
  final description = trip.description ?? '';
  final candidate =
      description.split(' · ').map((value) => value.trim()).firstWhere(
            (value) =>
                value.isNotEmpty &&
                !value.toLowerCase().startsWith('evidencias') &&
                !value.toLowerCase().startsWith('peso ') &&
                !value.toLowerCase().startsWith('valor de factura') &&
                !value.toLowerCase().startsWith('factura ') &&
                !value.toLowerCase().startsWith('estado ') &&
                !value.toLowerCase().startsWith('método ') &&
                !value.toLowerCase().startsWith('quién paga') &&
                !value.toLowerCase().startsWith('tipo valor'),
            orElse: () => '',
          );
  return candidate.isEmpty ? 'Paquete' : candidate;
}

String _shipmentDescriptionValue(Trip trip, String label) {
  final match = RegExp(
    '$label:\\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(trip.description ?? '');
  return match?.group(1)?.trim() ?? '';
}

String conductorSenderName(Trip trip) =>
    _shipmentDescriptionValue(trip, 'Recojo');

String conductorSenderPhone(Trip trip) {
  final match = RegExp(
    r'Recojo:.*?Teléfono:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(trip.description ?? '');
  return match?.group(1)?.trim() ?? '';
}

String conductorRecipientName(Trip trip) {
  final parsed = _shipmentDescriptionValue(trip, 'Envío');
  return parsed.isNotEmpty ? parsed : (trip.recipientName ?? trip.client);
}

String conductorRecipientPhone(Trip trip) {
  final match = RegExp(
    r'Envío:.*?Teléfono:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(trip.description ?? '');
  return match?.group(1)?.trim() ?? trip.recipientPhone ?? '';
}

String conductorInstructionText(Trip trip) {
  final raw = (trip.description ?? '')
      .replaceAll(RegExp(r'\s*\[INCOEX_RETURN_AT=[^\]]+\]'), '')
      .trim();
  if (raw.isEmpty) return '';
  const internalPrefixes = [
    'peso ',
    'valor de factura',
    'factura ',
    'estado factura',
    'método factura',
    'estado pago envío',
    'método pago envío',
    'quién paga envío',
    'tipo valor producto',
    'evidencias',
    'regreso programado',
  ];
  final visible = raw
      .split(' · ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .where((item) => !internalPrefixes.any(item.toLowerCase().startsWith))
      .toList();
  return visible.join(' · ');
}

String conductorScheduleLabel(Trip trip) {
  final rawDate = (trip.scheduledDate ?? trip.date).trim();
  final date = DateTime.tryParse(rawDate);
  final time = (trip.scheduledTime ?? trip.pickupTime ?? '').trim();
  if (date == null) return time.isEmpty ? rawDate : '$rawDate · $time';
  const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final weekday = weekdays[date.weekday - 1];
  final capitalizedWeekday =
      '${weekday[0].toUpperCase()}${weekday.substring(1)}';
  final label =
      '$capitalizedWeekday, ${date.day} ${months[date.month - 1]} ${date.year}';
  return time.isEmpty ? label : '$label · $time';
}

String conductorTodayLabel() {
  final now = DateTime.now();
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

double conductorTotalAmount(Trip trip) =>
    trip.quotedServiceTotalCs ?? trip.estimatedCostCs ?? 0;

class ViajeAsignado extends StatefulWidget {
  const ViajeAsignado({super.key, required this.tripId});

  final String tripId;

  @override
  State<ViajeAsignado> createState() => _ViajeAsignadoState();
}

class _ViajeAsignadoState extends State<ViajeAsignado> {
  Future<Trip>? _future;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      loading = true;
      error = null;
    });
    _future = apiClient.getTrip(widget.tripId);
    _future!.then((_) {
      if (mounted) setState(() => loading = false);
    }).catchError((_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'No se pudo cargar el viaje.';
        });
      }
    });
  }

  Future<void> _startTrip(Trip trip) async {
    if (trip.status == 'En camino' || trip.status == 'En entrega') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ViajeEnCurso(trip: trip)),
      );
      return;
    }
    if (trip.status != 'Asignado') {
      if (mounted) {
        setState(() => error =
            'El viaje está en estado «${trip.status}» y no se puede iniciar. Vuelve a atrás y refresca la lista.');
      }
      return;
    }
    try {
      final updated = await apiClient.updateTripStatus(trip.id, 'En camino');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ViajeEnCurso(trip: updated)),
      );
    } catch (failure) {
      final message = failure is ApiException
          ? failure.message
          : 'No se pudo iniciar el viaje.';
      if (mounted) setState(() => error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F52),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Viaje asignado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: cyan),
                      )
                    : error != null
                        ? _ErrorView(message: error!, onRetry: _load)
                        : FutureBuilder<Trip>(
                            future: _future,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              return _DetailBodyV2(
                                trip: snapshot.data!,
                                onStart: _startTrip,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.trip, required this.onStart});

  final Trip trip;
  final void Function(Trip trip) onStart;

  @override
  Widget build(BuildContext context) {
    final distance = trip.distanceKm ?? 12.4;
    final minutes = (distance * 2.8).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF0D47D9), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Asignado',
              style: TextStyle(
                color: Color(0xFF0D47D9),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Viaje ${trip.id}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Figtree',
            ),
          ),
        ),
        const SizedBox(height: 11),
        _MetadataChips(trip: trip),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5FB),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Color(0xFF0D47D9), size: 16),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Miércoles, 27 agosto 2026',
                      style: TextStyle(
                        color: Color(0xFF10224A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Color(0x2210224A), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: Color(0xFF0D47D9), size: 16),
                  const SizedBox(width: 10),
                  Text(
                    '${trip.pickupTime ?? '08:30 AM'} (Hora de recogida)',
                    style: const TextStyle(
                      color: Color(0xFF10224A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF23366F),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledDot(
                color: Colors.white,
                label: 'RECOGIDA',
                value: trip.origin,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: Column(
                  children: [
                    const SizedBox(height: 7),
                    Container(
                      width: 2,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: .55),
                            Colors.white.withValues(alpha: .12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              _LabeledDot(
                color: const Color(0xFFE5484D),
                label: 'DESTINO',
                value: trip.destination,
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF23366F),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              _Stat(
                icon: Icons.near_me_rounded,
                value: '${distance.toStringAsFixed(1)} km',
                label: 'Distancia',
              ),
              _statDivider,
              _Stat(
                icon: Icons.timeline_rounded,
                value: '$minutes min',
                label: 'Tiempo est.',
              ),
              _statDivider,
              _Stat(
                icon: Icons.inventory_2_rounded,
                value: '${trip.packages}',
                label: 'Cantidad',
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'INFORMACIÓN DEL ENVÍO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            letterSpacing: .8,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF23366F),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            children: [
              DetailRow(
                label: 'Tipo',
                value: trip.serviceType == 'Express'
                    ? 'Express'
                    : 'Documentos y paquetería',
              ),
              const SizedBox(height: 4),
              DetailRow(
                label: 'Cantidad',
                value:
                    '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 4),
              const DetailRow(label: 'Tamaño', value: 'Mediano (máx. 20kg)'),
              const SizedBox(height: 11),
              Divider(color: glassBorder, height: 1),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instrucciones',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      (trip.description ??
                              'Manejar con cuidado. Contiene material frágil.')
                          .replaceAll(
                            RegExp(r'\s*\[INCOEX_RETURN_AT=[^\]]+\]'),
                            '',
                          )
                          .trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ],
              ),
              if (trip.estimatedCostCs != null) ...[
                const SizedBox(height: 11),
                Divider(color: glassBorder, height: 1),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Text(
                      'Precio del viaje',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 12,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatFareCs(trip.estimatedCostCs!),
                      style: const TextStyle(
                        color: mint,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'CLIENTE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            letterSpacing: .8,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF23366F),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D47D9), Color(0xFF083EC0)],
                      ),
                    ),
                    child: Text(
                      initials(trip.contactName ?? trip.recipientName ?? 'Cl'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.recipientName ?? trip.contactName ?? 'Cliente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        const Text(
                          'Remitente',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 11,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _dial(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .10),
                        border: Border.all(color: glassBorder),
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Divider(color: glassBorder, height: 1),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nota de entrega',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      trip.destinationRefs?.trim().isNotEmpty == true
                          ? trip.destinationRefs!.trim()
                          : 'Sin referencia de entrega',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 54,
          child: Material(
            color: const Color(0xFF0D47D9),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => onStart(trip),
              child: const Center(
                child: Text(
                  'Iniciar viaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _dial(BuildContext context) {
    final phone = trip.contactPhone ?? trip.recipientPhone;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1D4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Llamar al cliente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${trip.recipientName ?? trip.contactName ?? 'Cliente'} · $phone',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBodyV2 extends StatelessWidget {
  const _DetailBodyV2({required this.trip, required this.onStart});

  final Trip trip;
  final void Function(Trip trip) onStart;

  @override
  Widget build(BuildContext context) {
    final distance = trip.distanceKm ?? 12.4;
    final minutes = (distance * 2.8).round();
    final isTrip = (trip.serviceMode ?? '').toLowerCase().contains('taxi');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const SizedBox(height: 6),
        Center(child: _StatusPill(status: trip.statusLabel)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Viaje ${trip.id}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Figtree',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ScheduleCard2(trip: trip),
        const SizedBox(height: 13),
        _BlueCard2(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Positioned(
                    left: 5,
                    top: 8,
                    child: Container(
                      width: 2,
                      height: 72,
                      color: Colors.white.withValues(alpha: .45),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledDot(
                        color: Colors.white,
                        label: 'RECOGIDA',
                        value: trip.origin,
                        detail: trip.originRefs,
                      ),
                      const SizedBox(height: 14),
                      _LabeledDot(
                        color: const Color(0xFFE5484D),
                        label: 'DESTINO',
                        value: trip.destination,
                        detail: trip.destinationRefs,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (trip.stops.isNotEmpty) ...[
          const SizedBox(height: 13),
          _StopsCard2(stops: trip.stops),
        ],
        const SizedBox(height: 13),
        _BlueCard2(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              _Stat(
                icon: Icons.near_me_rounded,
                value: '${distance.toStringAsFixed(1)} km',
                label: 'Distancia',
              ),
              _statDivider,
              _Stat(
                icon: Icons.timeline_rounded,
                value: '$minutes min',
                label: 'Tiempo est.',
              ),
              _statDivider,
              _Stat(
                icon: isTrip
                    ? Icons.people_alt_rounded
                    : Icons.inventory_2_rounded,
                value: conductorQuantityLabel(trip),
                label: isTrip ? 'Pasajeros' : 'Cantidad',
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _SectionTitle2('PAQUETE'),
        const SizedBox(height: 9),
        _PackagePhotoCard(trip: trip),
        const SizedBox(height: 17),
        const _SectionTitle2('INFORMACIÓN DEL SERVICIO'),
        const SizedBox(height: 9),
        _ServiceCard2(trip: trip),
        if (trip.options.isNotEmpty) ...[
          const SizedBox(height: 13),
          const _SectionTitle2('SERVICIOS ADICIONALES'),
          const SizedBox(height: 9),
          _OptionsCard2(trip: trip),
        ],
        const SizedBox(height: 17),
        const _SectionTitle2('PAGO Y FACTURACIÓN'),
        const SizedBox(height: 9),
        _PaymentCard2(trip: trip),
        const SizedBox(height: 17),
        const _SectionTitle2('CLIENTE Y ENTREGA'),
        const SizedBox(height: 9),
        _ContactCard2(trip: trip, onCall: () => _dial(context)),
        if (trip.returnTrip) ...[
          const SizedBox(height: 13),
          _NoteCard2(
            title: 'Regreso programado',
            text:
                'El servicio incluye regreso. Hora prevista: ${trip.scheduledTime ?? trip.pickupTime ?? 'Hora pendiente'}.',
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          height: 54,
          child: Material(
            color: const Color(0xFF0D47D9),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => onStart(trip),
              child: const Center(
                child: Text(
                  'Iniciar viaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _dial(BuildContext context) {
    final phone = trip.contactPhone ?? trip.recipientPhone;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1D4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Llamar al contacto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${trip.contactName ?? trip.recipientName ?? trip.client} · ${phone?.isNotEmpty == true ? phone : 'Teléfono no disponible'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D5BFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF5FA6FF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final payment = conductorPaymentLabel(trip);
    final paymentIsDone = payment.toLowerCase().startsWith('pagado');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        _DesignChip(
          icon: Icons.local_shipping_outlined,
          label: conductorServiceLabel(trip),
          color: const Color(0xFF0D5BFF),
        ),
        _DesignChip(
          icon: paymentIsDone
              ? Icons.check_circle_outline_rounded
              : Icons.schedule_rounded,
          label: payment,
          color: paymentIsDone ? const Color(0xFF16C784) : cyan,
        ),
      ],
    );
  }
}

class _DesignChip extends StatelessWidget {
  const _DesignChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .24),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard2 extends StatelessWidget {
  const _ScheduleCard2({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final isScheduled = trip.isScheduled ||
        (trip.serviceType ?? '').trim().toLowerCase() == 'programado';
    final time = (trip.scheduledTime ?? '').trim();
    final date = isScheduled
        ? conductorScheduleLabel(trip).split(' · ').first
        : conductorTodayLabel();
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: cyan, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ],
          ),
          if (isScheduled) ...[
            const SizedBox(height: 12),
            Divider(color: glassBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: cyan, size: 16),
                const SizedBox(width: 10),
                Text(
                  time.isEmpty ? 'Hora pendiente' : '$time (Hora de recogida)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceCard2 extends StatelessWidget {
  const _ServiceCard2({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final reference = _firstNonEmpty([trip.destinationRefs, trip.originRefs]);
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          DetailRow(
            label: 'Servicio',
            value: (trip.serviceMode ?? '').toLowerCase().contains('taxi')
                ? 'Taxi privado'
                : 'Envíos',
          ),
          const SizedBox(height: 4),
          DetailRow(label: 'Cliente', value: trip.client),
          const SizedBox(height: 4),
          DetailRow(label: 'Paquete', value: conductorPackageLabel(trip)),
          if (reference.isNotEmpty) ...[
            const SizedBox(height: 4),
            DetailRow(label: 'Referencia', value: reference),
          ],
          if (trip.weight != null) ...[
            const SizedBox(height: 4),
            DetailRow(
              label: 'Peso',
              value:
                  '${trip.weight!.toStringAsFixed(trip.weight! % 1 == 0 ? 0 : 1)} ${trip.weightUnit ?? 'kg'}',
            ),
          ],
          if (trip.fragile) ...[
            const SizedBox(height: 11),
            Divider(color: glassBorder, height: 1),
            const SizedBox(height: 11),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 17),
                SizedBox(width: 8),
                Text(
                  'Carga frágil: manipular con cuidado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionsCard2 extends StatelessWidget {
  const _OptionsCard2({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          for (var index = 0; index < trip.options.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _OptionRow2(option: trip.options[index]),
          ],
          if (trip.optionsTotalCs > 0) ...[
            const SizedBox(height: 11),
            Divider(color: glassBorder, height: 1),
            const SizedBox(height: 11),
            DetailRow(
              label: 'Total adicionales',
              value: formatFareCs(trip.optionsTotalCs),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow2 extends StatelessWidget {
  const _OptionRow2({required this.option});

  final TripOptionSelection option;

  @override
  Widget build(BuildContext context) {
    final quantity = option.quantity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.add_circle_outline_rounded, color: cyan, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
              if (quantity > 1)
                Text(
                  'Cantidad: $quantity',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11,
                    fontFamily: 'Figtree',
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatFareCs(option.priceCs * quantity),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Figtree',
          ),
        ),
      ],
    );
  }
}

class _PaymentCard2 extends StatelessWidget {
  const _PaymentCard2({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final total = conductorTotalAmount(trip);
    final paymentMethod = invoiceServicePaymentMethodForTrip(trip);
    final productAmount = trip.invoiceAmountCs ?? 0;
    final productIsSale = invoiceProductIsSaleForTrip(trip);
    final optionsTotal = trip.optionsTotalCs > 0
        ? trip.optionsTotalCs
        : trip.options.fold<double>(
            0,
            (sum, option) =>
                sum +
                option.priceCs *
                    (option.currency.toUpperCase() == 'USD' ? 36.5 : 1) *
                    (option.quantity < 1 ? 1 : option.quantity),
          );
    final base = trip.quotedBaseCs ??
        (total - optionsTotal - (trip.quotedAdditionalCs ?? 0))
            .clamp(0, double.infinity)
            .toDouble();
    final additional = trip.quotedAdditionalCs ??
        (total - base - optionsTotal).clamp(0, double.infinity).toDouble();
    final shippingRate = base + additional;
    final payer = invoiceServicePayerForTrip(trip);
    // La distancia adicional es parte del cálculo normal de la tarifa.
    // Solo mostramos el desglose extendido si existe producto o un adicional
    // seleccionado explícitamente por el cliente.
    final hasAdditionalConcepts = productAmount > 0 || trip.options.isNotEmpty;
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        children: [
          if (!hasAdditionalConcepts) ...[
            if (total > 0)
              DetailRow(
                label: 'Tarifa de envío',
                value: formatFareCs(total),
              ),
            const SizedBox(height: 4),
            DetailRow(
              label: 'Subtotal del envío',
              value: formatFareCs(total),
            ),
          ] else ...[
            DetailRow(label: 'Quién paga', value: payer),
            if (paymentMethod.isNotEmpty && paymentMethod != 'No definido') ...[
              const SizedBox(height: 4),
              DetailRow(
                label: 'Método de pago',
                value: paymentMethod,
              ),
            ],
            const SizedBox(height: 11),
            Divider(color: glassBorder, height: 1),
            const SizedBox(height: 11),
            if (productAmount > 0) ...[
              DetailRow(
                label: productIsSale
                    ? 'Factura del producto'
                    : 'Valor aproximado del producto',
                value: formatFareCs(productAmount),
              ),
              const SizedBox(height: 4),
            ],
            DetailRow(
              label: 'Tarifa de envío',
              value: formatFareCs(shippingRate),
            ),
            for (final option in trip.options) ...[
              const SizedBox(height: 4),
              DetailRow(
                label: option.quantity == 1
                    ? option.title
                    : '${option.title} (x${option.quantity})',
                value: formatFareCs(
                  option.priceCs *
                      (option.currency.toUpperCase() == 'USD' ? 36.5 : 1) *
                      (option.quantity < 1 ? 1 : option.quantity),
                ),
              ),
            ],
            const SizedBox(height: 4),
            DetailRow(
              label: 'Subtotal del envío',
              value: formatFareCs(total),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackagePhotoCard extends StatelessWidget {
  const _PackagePhotoCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final photos = conductorPackagePhotoUrls(trip);
    return _BlueCard2(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.packages} ${trip.packages == 1 ? 'paquete' : 'paquetes'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  photos.isEmpty
                      ? 'No se adjuntó foto'
                      : 'Foto del paquete adjunta',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 12,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PackagePhotoPreview(
            url: photos.isEmpty ? null : photos.first,
            photoCount: photos.length,
            onTap: photos.isEmpty
                ? null
                : () => _showPackagePhotoCarousel(context, photos),
          ),
        ],
      ),
    );
  }
}

class _PackagePhotoPreview extends StatelessWidget {
  const _PackagePhotoPreview({this.url, this.photoCount = 0, this.onTap});

  final String? url;
  final int photoCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 78,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBorder),
      ),
      child: const Icon(
        Icons.photo_camera_back_outlined,
        color: Color(0xFFB9D4FF),
        size: 25,
      ),
    );
    if (url == null) return placeholder;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url!,
              width: 78,
              height: 68,
              fit: BoxFit.cover,
              headers: apiClient.accessToken?.isNotEmpty == true
                  ? {'Authorization': 'Bearer ${apiClient.accessToken}'}
                  : null,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          ),
          if (photoCount > 1)
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$photoCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showPackagePhotoCarousel(BuildContext context, List<String> photos) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .86),
    builder: (_) {
      var currentIndex = 0;
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (index) =>
                        setState(() => currentIndex = index),
                    itemBuilder: (_, index) => InteractiveViewer(
                      minScale: .8,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.contain,
                          headers: apiClient.accessToken?.isNotEmpty == true
                              ? {
                                  'Authorization':
                                      'Bearer ${apiClient.accessToken}'
                                }
                              : null,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (photos.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22, top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < photos.length; index++)
                          Container(
                            width: index == currentIndex ? 18 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
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

class _ContactCard2 extends StatelessWidget {
  const _ContactCard2({required this.trip, required this.onCall});

  final Trip trip;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final sender = conductorSenderName(trip);
    final senderPhone = conductorSenderPhone(trip);
    final recipient = conductorRecipientName(trip);
    final recipientPhone = conductorRecipientPhone(trip);
    return Column(
      children: [
        _BlueCard2(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: _PartyRow(
            label: 'Remitente',
            name: sender.isEmpty ? trip.client : sender,
            phone: senderPhone,
            onCall: onCall,
          ),
        ),
        const SizedBox(height: 10),
        _BlueCard2(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: _PartyRow(
            label: 'Destinatario',
            name: recipient,
            phone: recipientPhone,
            onCall: onCall,
          ),
        ),
      ],
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.label,
    required this.name,
    required this.phone,
    required this.onCall,
  });

  final String label;
  final String name;
  final String phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFB9D4FF),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47D9), Color(0xFF083EC0)],
                ),
              ),
              child: Text(
                initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 11,
                        fontFamily: 'Figtree',
                      ),
                    ),
                ],
              ),
            ),
            if (phone.isNotEmpty)
              InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .10),
                    border: Border.all(color: glassBorder),
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StopsCard2 extends StatelessWidget {
  const _StopsCard2({required this.stops});

  final List<TripStop> stops;

  @override
  Widget build(BuildContext context) {
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARADAS ADICIONALES',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < stops.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: cyan, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${stops[index].label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      Text(
                        stops[index].address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 11,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard2 extends StatelessWidget {
  const _NoteCard2({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _BlueCard2(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded, color: cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueCard2 extends StatelessWidget {
  const _BlueCard2(
      {required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xA8143474),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x6687B7FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle2 extends StatelessWidget {
  const _SectionTitle2(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        letterSpacing: .8,
        fontWeight: FontWeight.w800,
        fontFamily: 'Figtree',
      ),
    );
  }
}

class _LabeledDot extends StatelessWidget {
  const _LabeledDot({
    required this.color,
    required this.label,
    required this.value,
    this.detail,
  });

  final Color color;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 11,
          height: 11,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9FB2DC),
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
              if (detail?.trim().isNotEmpty == true)
                Text(
                  detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11,
                    fontFamily: 'Figtree',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RouteText extends StatelessWidget {
  const _RouteText({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9FB2DC),
            fontSize: 9,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Figtree',
          ),
        ),
        if (detail?.trim().isNotEmpty == true)
          Text(
            detail!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 11,
              fontFamily: 'Figtree',
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9FB2DC),
              fontSize: 10,
              fontFamily: 'Figtree',
            ),
          ),
        ],
      ),
    );
  }
}

Widget get _statDivider => Container(
      width: 1,
      height: 44,
      color: Colors.white.withValues(alpha: .18),
    );

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF17285C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFFFFB4B4), size: 36),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 150,
                child: GlassButton(
                  label: 'Reintentar',
                  onPressed: onRetry,
                  height: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
