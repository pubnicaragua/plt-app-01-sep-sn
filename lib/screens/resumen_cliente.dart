import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/glass.dart';
import 'home_cliente.dart';

class ResumenCliente extends StatefulWidget {
  const ResumenCliente({super.key});

  @override
  State<ResumenCliente> createState() => _ResumenClienteState();
}

class _ResumenClienteState extends State<ResumenCliente> {
  late Future<List<Trip>> trips;
  int tab = 0; // 0 = Viajes, 1 = Ganancias

  @override
  void initState() {
    super.initState();
    trips = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
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
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 20),
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
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      children: [
                        // Segmentado Viajes / Ganancias
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF23366F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: glassBorder),
                          ),
                          child: Row(
                            children: [
                              for (final (index, label) in [
                                (0, 'Viajes'),
                                (1, 'Ganancias'),
                              ])
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => tab = index),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: tab == index
                                            ? figmaBlue
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(11),
                                      ),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Acumin Pro',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cifra grande
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loading
                                    ? '…'
                                    : tab == 0
                                        ? '${_thousand(totalTrips)}'
                                        : _money(earnings),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab == 0
                                    ? 'Viajes realizados'
                                    : 'Ganancias totales',
                                style: const TextStyle(
                                  color: Color(0xFFB9D4FF),
                                  fontSize: 13,
                                  fontFamily: 'Acumin Pro',
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
                                    onTap: () {},
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
                                              fontFamily: 'Acumin Pro',
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
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _PeriodCard(
                                label: 'HOY',
                                price: tab == 0
                                    ? totalTrips
                                        .toStringAsFixed(0)
                                    : _compactMoney(earnings * .18),
                                sub: '${(totalTrips * .18).round()} viajes',
                                delta: '+12%',
                                active: true,
                                small: tab == 1,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _PeriodCard(
                                label: 'ESTA SEMANA',
                                price: tab == 0
                                    ? (totalTrips * .64)
                                        .toStringAsFixed(0)
                                    : _compactMoney(earnings * .64),
                                sub: '${(totalTrips * .64).round()} viajes',
                                delta: '+18%',
                                active: false,
                                small: tab == 1,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _PeriodCard(
                                label: 'ESTE MES',
                                price: tab == 0
                                    ? '$_thousand(totalTrips)'
                                    : _compactMoney(earnings),
                                sub: '$totalTrips viajes',
                                delta: '+24%',
                                active: false,
                                small: tab == 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Rendimiento semanal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const SizedBox(height: 11),
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      fontFamily: 'Acumin Pro',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  _LegendDot(color: mint),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ganancias',
                                    style: TextStyle(
                                      color: Color(0xFFB9D4FF),
                                      fontSize: 10.5,
                                      fontFamily: 'Acumin Pro',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        GlassCard(
                          color: figmaBlue.withValues(alpha: .30),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: figmaBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.trending_up_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tab == 0
                                          ? 'Tu mejor día fue el jueves'
                                          : 'Tu mejor ganancia fue el jueves',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Acumin Pro',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Realizaste ${(totalTrips * .26).round()} viajes y generaste ${_money(earnings * .26)}.',
                                      style: const TextStyle(
                                        color: Color(0xFFB9D4FF),
                                        fontSize: 11,
                                        fontFamily: 'Acumin Pro',
                                      ),
                                    ),
                                  ],
                                ),
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
              AppNavBar(current: 2, onChanged: _nav),
            ],
          ),
        ),
      ),
    );
  }

  void _nav(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeCliente()),
      (route) => false,
    );
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
          ? const Color(0xFF23366F)
          : const Color(0xFF17285C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8FA0C4),
              fontSize: 9.5,
              letterSpacing: .7,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
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
                      fontFamily: 'Acumin Pro',
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
