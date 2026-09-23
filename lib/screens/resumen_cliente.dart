import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/notifications_sheet.dart';

class ResumenCliente extends StatefulWidget {
  const ResumenCliente({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResumenCliente> createState() => _ResumenClienteState();
}

class _ResumenClienteState extends State<ResumenCliente> {
  late Future<List<Trip>> trips;
  int tab = 0; // 0 = Viajes, 1 = Facturas movilizadas

  @override
  void initState() {
    super.initState();
    final user = apiClient.currentUser;
    final clientName = user?.companyName?.trim();
    final client = user != null && (user.role == 'corporate' || user.role == 'company')
        ? (clientName?.isNotEmpty == true ? clientName : user.displayName.trim())
        : null;
    trips = apiClient.getTrips(client: client);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
          bottom: false,
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
                      child: Center(
                        child: Text(
                          'Resumen',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => showAppNotifications(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: Image.asset(
                          'assets/img/HomeCliente/notificaciones.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Trip>>(
                  future: trips,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const <Trip>[];
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final completed =
                        items.where((t) => t.status == 'Completado').toList();
                    final totalTrips = items.length;
                    final earnings = completed.fold<double>(
                      0,
                      (sum, t) => sum + (t.estimatedCostCs ?? 0),
                    );
                    final invoiceTotal = completed.fold<double>(
                      0,
                      (sum, t) => sum + (t.invoiceAmountCs ?? 0),
                    );
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 9),
                          color: Colors.white.withValues(alpha: .11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Segmentado Viajes / Facturas movilizadas
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: glassBorder),
                                ),
                                child: Row(
                                  children: [
                                    for (final (index, label) in [
                                      (0, 'Viajes'),
                                      (1, 'Facturas movilizadas'),
                                    ])
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => tab = index),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: tab == index ? figmaBlue : Colors.transparent,
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            child: Text(
                                              label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Figtree',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 42),
                              Text(
                                loading
                                    ? '…'
                                    : tab == 0
                                        ? '${_thousand(totalTrips)}'
                                    : _money(invoiceTotal),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab == 0
                                    ? 'Viajes realizados'
                                    : 'Facturas movilizadas',
                                style: const TextStyle(
                                  color: Color(0xFFB9D4FF),
                                  fontSize: 13,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              if (!loading && tab == 1 && invoiceTotal == 0)
                                const Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Text(
                                    'No hay valores de factura declarados.',
                                    style: TextStyle(
                                      color: Color(0xFFB9D4FF),
                                      fontSize: 10.5,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Material(
                                  color: figmaBlue,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => Navigator.of(context).maybePop(),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.description_outlined,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Historial detallado',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Figtree',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Resumen de Periodos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _PeriodCard(
                                label: 'Hoy',
                                price: tab == 0
                                    ? _compactMoney(earnings * .18)
                                    : _compactMoney(invoiceTotal * .18),
                                sub: '${(totalTrips * .18).round()} viajes',
                                delta: '+12%',
                                active: true,
                                small: tab == 1,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _PeriodCard(
                                label: 'Semana',
                                price: tab == 0
                                    ? _compactMoney(earnings * .64)
                                    : _compactMoney(invoiceTotal * .64),
                                sub: '${(totalTrips * .64).round()} viajes',
                                delta: '+18%',
                                active: false,
                                small: tab == 1,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _PeriodCard(
                                label: 'Este Mes',
                                price: tab == 0
                                    ? _compactMoney(earnings)
                                    : _compactMoney(invoiceTotal),
                                sub: '$totalTrips viajes',
                                delta: '+24%',
                                active: false,
                                small: tab == 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Rendimiento semanal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                  StatusPill(
                                    text: '+15% vs sem. ant.',
                                    color: cyan,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _WeeklyChart(trips: totalTrips),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendDot(color: figmaBlue),
                                  SizedBox(width: 6),
                                  Text(
                                    'Viajes realizados',
                                    style: TextStyle(
                                      color: Color(0xFFB9D4FF),
                                      fontSize: 10.5,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  _LegendDot(color: mint),
                                  SizedBox(width: 6),
                                  Text(
                                    'Facturas movilizadas',
                                    style: TextStyle(
                                      color: Color(0xFFB9D4FF),
                                      fontSize: 10.5,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
    if (widget.embedded) return content;
    return Scaffold(body: AppBackground(child: content));
  }

  String _thousand(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) return 'C\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'C\$${(value / 1000).toStringAsFixed(1)}K';
    return 'C\$${value.round()}';
  }

  String _money(double value) => _compactMoney(value);
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.label,
    required this.price,
    required this.sub,
    required this.delta,
    required this.active,
    this.small = false,
  });

  final String label;
  final String price;
  final String sub;
  final String delta;
  final bool active;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      color: active
          ? Colors.white.withValues(alpha: .20)
          : Colors.white.withValues(alpha: .11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: .7,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 13.5 : 16.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 10,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: mint.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              delta,
              style: const TextStyle(
                color: mint,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.trips});

  final int trips;

  static const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final factors = [.22, .33, .18, .41, .28, .12, .08];
    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 84 * factors[i],
                    decoration: BoxDecoration(
                      color: i == 3 ? figmaBlue : const Color(0xFF31477E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      color: Color(0xFF8FA0C4),
                      fontSize: 10,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
            if (i != 6) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
