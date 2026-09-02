import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

class ResumenCliente extends StatefulWidget {
  const ResumenCliente({super.key});

  @override
  State<ResumenCliente> createState() => _ResumenClienteState();
}

class _ResumenClienteState extends State<ResumenCliente> {
  late Future<List<Trip>> trips;
  String periodo = 'HOY';

  @override
  void initState() {
    super.initState();
    trips = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    const periodos = ['HOY', 'SEMANA', 'MES'];    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Resumen del periodo',
          style: TextStyle(
            fontFamily: 'Acumin Pro',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 72, 22, 28),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: List.generate(
                    periodos.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => periodo = periodos[index]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: periodo == periodos[index]
                                ? figmaBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            periodos[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Trip>>(
                future: trips,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <Trip>[];
                  final completed =
                      items.where((t) => t.status == 'Completado').length;
                  return Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _stat(
                              value: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? '…'
                                  : '${items.length}',
                              label: 'Viajes',
                              icon: Icons.route_outlined,
                              color: cyan,
                            ),
                            const SizedBox(
                              height: 52,
                              child: VerticalDivider(
                                color: Color(0x22FFFFFF),
                              ),
                            ),
                            _stat(
                              value:
                                  snapshot.connectionState == ConnectionState.waiting
                                      ? '…'
                                      : 'C\$${completed * 185}',
                              label: 'Ganancias',
                              icon: Icons.payments_outlined,
                              color: mint,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history_rounded,
                                    color: cyan, size: 19),
                                SizedBox(width: 9),
                                Text(
                                  'Historial detallado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Acumin Pro',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 13),
                            Text(
                              'Aquí se listarán las guías, fechas y estados de todos tus envíos del periodo, exportables a la web.',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 12,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final trip in items.take(3)) ...[
                              _row(icon: Icons.space_dashboard_outlined, text: '${trip.origin} → ${trip.destination} · ${trip.status}'),
                              const SizedBox(height: 9),
                            ],
                            if (items.isEmpty)
                              const Text(
                                'Sin viajes registrados en este periodo.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 11,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: cyan, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
      ],
    );
  }
}
