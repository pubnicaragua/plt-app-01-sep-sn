import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'viaje_en_curso.dart';

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
      if (mounted) setState(() {
        loading = false;
        error = 'No se pudo cargar el viaje.';
      });
    });
  }

  Future<void> _startTrip(Trip trip) async {
    try {
      final updated = await apiClient.updateTripStatus(trip.id, 'En camino');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ViajeEnCurso(trip: updated)),
      );
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo iniciar el viaje.');
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
                          fontFamily: 'Acumin Pro',
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
                              return _DetailBody(
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
                fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
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
                        fontFamily: 'Acumin Pro',
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
                      fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
                value: '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}',
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
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      trip.description ?? 'Manejar con cuidado. Contiene material frágil.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontFamily: 'Acumin Pro',
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
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: mint,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
                        fontFamily: 'Acumin Pro',
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
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const Text(
                          'Remitente',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 11,
                            fontFamily: 'Acumin Pro',
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
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Entregar en recepción, piso 4',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontFamily: 'Acumin Pro',
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
                    fontFamily: 'Acumin Pro',
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
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${trip.recipientName ?? trip.contactName ?? 'Cliente'} · $phone',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledDot extends StatelessWidget {
  const _LabeledDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

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
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
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
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9FB2DC),
              fontSize: 10,
              fontFamily: 'Acumin Pro',
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
                  fontFamily: 'Acumin Pro',
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
