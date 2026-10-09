import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/trip_routing.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

String weeklyChartValueLabel(int total, String unit) {
  final formatted = total.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
  if (unit == 'C\$') return 'C\$$formatted';
  return '$unit: $formatted';
}

DateTime? summaryDateForTrip(Trip trip, DateTime now) {
  final status = trip.status.trim().toLowerCase();
  final active =
      !{'completado', 'cancelado', 'anulado', 'finalizado'}.contains(status);
  final scheduled = trip.isScheduled ||
      trip.serviceType?.trim().toLowerCase() == 'programado';

  if (active && !scheduled) return DateUtils.dateOnly(now);

  final raw = scheduled ? trip.scheduledDate : trip.date;
  final parsed = DateTime.tryParse(raw ?? '');
  return parsed == null ? null : DateUtils.dateOnly(parsed.toLocal());
}

int summaryTripCount(Iterable<Trip> trips) => trips.length;

double summaryInvoiceTotal(Iterable<Trip> trips) => trips.fold<double>(
      0,
      (sum, trip) => sum + (trip.invoiceAmountCs ?? 0),
    );

double summaryInvoiceTotalInRange(
  Iterable<Trip> trips,
  DateTimeRange range,
  DateTime now,
) {
  return trips.where((trip) {
    final date = summaryDateForTrip(trip, now);
    return date != null &&
        !date.isBefore(range.start) &&
        date.isBefore(range.end);
  }).fold<double>(
    0,
    (sum, trip) => sum + (trip.invoiceAmountCs ?? 0),
  );
}

class ResumenCliente extends StatefulWidget {
  const ResumenCliente({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResumenCliente> createState() => _ResumenClienteState();
}

class _ResumenClienteState extends State<ResumenCliente> {
  late Future<List<Trip>> trips;
  int tab = 0; // 0 = Envíos, 1 = Viajes, 2 = Facturas movilizadas

  @override
  void initState() {
    super.initState();
    final user = apiClient.currentUser;
    final clientName = user?.companyName?.trim();
    final client =
        user != null && (user.role == 'corporate' || user.role == 'company')
            ? (clientName?.isNotEmpty == true
                ? clientName
                : user.displayName.trim())
            : null;
    trips = apiClient.getTrips(client: client);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Trip>>(
              future: trips,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <Trip>[];
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;
                final activity = items
                    .where((trip) => !{'cancelado', 'anulado'}
                        .contains(trip.status.toLowerCase()))
                    .toList();
                final selectedTrips = tab == 0
                    ? activity.where((trip) => !_isTrip(trip)).toList()
                    : tab == 1
                        ? activity.where(_isTrip).toList()
                        : activity;
                final summaryNow = DateTime.now();
                final today = DateUtils.dateOnly(summaryNow);
                final tomorrow = today.add(const Duration(days: 1));
                final weekStart =
                    today.subtract(Duration(days: today.weekday - 1));
                final weekEnd = weekStart.add(const Duration(days: 7));
                final monthStart = DateTime(today.year, today.month);
                final monthEnd = DateTime(today.year, today.month + 1);
                final previousWeekStart =
                    weekStart.subtract(const Duration(days: 7));
                final previousWeekEnd = weekStart;
                final previousMonthStart =
                    DateTime(today.year, today.month - 1);
                final previousMonthEnd = monthStart;
                final todayCount = _countIn(
                    selectedTrips, DateTimeRange(start: today, end: tomorrow));
                final weekCount = _countIn(selectedTrips,
                    DateTimeRange(start: weekStart, end: weekEnd));
                final monthCount = _countIn(selectedTrips,
                    DateTimeRange(start: monthStart, end: monthEnd));
                final todayRange = DateTimeRange(start: today, end: tomorrow);
                final weekRange = DateTimeRange(start: weekStart, end: weekEnd);
                final monthRange =
                    DateTimeRange(start: monthStart, end: monthEnd);
                final todayInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips, todayRange, summaryNow);
                final weekInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips, weekRange, summaryNow);
                final monthInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips, monthRange, summaryNow);
                final previousDay = today.subtract(const Duration(days: 1));
                final yesterdayCount = _countIn(selectedTrips,
                    DateTimeRange(start: previousDay, end: today));
                final previousWeekCount = _countIn(
                    selectedTrips,
                    DateTimeRange(
                        start: previousWeekStart, end: previousWeekEnd));
                final previousMonthCount = _countIn(
                    selectedTrips,
                    DateTimeRange(
                        start: previousMonthStart, end: previousMonthEnd));
                final yesterdayInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips,
                    DateTimeRange(start: previousDay, end: today),
                    summaryNow);
                final previousWeekInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips,
                    DateTimeRange(
                        start: previousWeekStart, end: previousWeekEnd),
                    summaryNow);
                final previousMonthInvoiceAmount = summaryInvoiceTotalInRange(
                    selectedTrips,
                    DateTimeRange(
                        start: previousMonthStart, end: previousMonthEnd),
                    summaryNow);
                final totalTripCount = summaryTripCount(selectedTrips);
                final totalAmount = summaryInvoiceTotal(selectedTrips);
                final weeklyCounts = _weeklyCounts(selectedTrips);
                final weeklyValues = tab == 2
                    ? _weeklyInvoiceAmounts(selectedTrips, summaryNow)
                    : weeklyCounts;
                final unit = tab == 0
                    ? 'envío'
                    : tab == 1
                        ? 'viaje'
                        : 'factura';
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Todo lo que necesitas saber',
                              style: TextStyle(
                                color: Color(0xE0FFFFFF),
                                fontSize: 10,
                                fontFamily: 'Figtree',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Row(
                        children: [
                          for (final (index, label) in [
                            (0, 'Envíos'),
                            (1, 'Viajes'),
                            (2, 'Facturas movilizadas'),
                          ])
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => tab = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: tab == index
                                        ? figmaBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
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
                    const SizedBox(height: 8),
                    AppGlassSurface(
                      borderRadius: 22,
                      selected: true,
                      fillColor: const Color(0x3A0A2C73),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tab == 0
                                            ? 'Total de envíos realizados'
                                            : tab == 1
                                                ? 'Total de viajes realizados'
                                                : 'Facturas movilizadas',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Figtree',
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        loading
                                            ? '…'
                                            : tab == 2
                                                ? _money(totalAmount)
                                                : _thousand(totalTripCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1,
                                          fontFamily: 'Figtree',
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  mint.withValues(alpha: .22),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _delta(monthCount,
                                                  previousMonthCount),
                                              style: const TextStyle(
                                                color: mint,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Figtree',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'vs. mes anterior',
                                            style: TextStyle(
                                              color: Color(0xFFB9D4FF),
                                              fontSize: 8.5,
                                              fontFamily: 'Figtree',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 188,
                                  height: 104,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        bottom: 8,
                                        width: 136,
                                        height: 78,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform:
                                              Matrix4.diagonal3Values(-1, 1, 1),
                                          child: Image.asset(
                                            'assets/img/HomeCliente/figma_carga.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        width: 112,
                                        height: 68,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform:
                                              Matrix4.diagonal3Values(-1, 1, 1),
                                          child: Image.asset(
                                            'assets/img/HomeCliente/figma_auto.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 78,
                                        bottom: 2,
                                        width: 66,
                                        height: 50,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform:
                                              Matrix4.diagonal3Values(-1, 1, 1),
                                          child: Image.asset(
                                            'assets/img/HomeCliente/figma_moto.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!loading && tab == 2 && totalAmount == 0)
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
                          ],
                        ),
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
                            price: tab == 2
                                ? _money(todayInvoiceAmount)
                                : _thousand(todayCount),
                            sub: tab == 2
                                ? 'facturado'
                                : todayCount == 1
                                    ? unit
                                    : '${unit}s',
                            delta: tab == 2
                                ? _deltaAmount(
                                    todayInvoiceAmount, yesterdayInvoiceAmount)
                                : _delta(todayCount, yesterdayCount),
                            active: false,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _PeriodCard(
                            label: 'Esta semana',
                            price: tab == 2
                                ? _money(weekInvoiceAmount)
                                : _thousand(weekCount),
                            sub: tab == 2
                                ? 'facturado'
                                : weekCount == 1
                                    ? unit
                                    : '${unit}s',
                            delta: tab == 2
                                ? _deltaAmount(weekInvoiceAmount,
                                    previousWeekInvoiceAmount)
                                : _delta(weekCount, previousWeekCount),
                            active: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _PeriodCard(
                      label: 'Este mes',
                      price: tab == 2
                          ? _money(monthInvoiceAmount)
                          : _thousand(monthCount),
                      sub: tab == 2
                          ? 'facturado'
                          : monthCount == 1
                              ? unit
                              : '${unit}s',
                      delta: tab == 2
                          ? _deltaAmount(
                              monthInvoiceAmount, previousMonthInvoiceAmount)
                          : _delta(monthCount, previousMonthCount),
                      active: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: AppGlassSurface(
                        borderRadius: 12,
                        selected: true,
                        fillColor: const Color(0x55106EFF),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/img/HomeCliente/resumen_mejor_dia.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _bestDay(
                                    weeklyValues,
                                    tab == 2 ? 'C\$' : unit,
                                    money: tab == 2,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppGlassSurface(
                      borderRadius: 18,
                      selected: true,
                      fillColor: const Color(0x3A0A2C73),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/img/HomeCliente/resumen_rendimiento.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rendimiento semanal',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Figtree',
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          tab == 0
                                              ? 'Comparativa de envíos realizados'
                                              : tab == 1
                                                  ? 'Comparativa de viajes realizados'
                                                  : 'Comparativa de facturas movilizadas',
                                          style: TextStyle(
                                            color: Color(0xFFB9D4FF),
                                            fontSize: 9,
                                            fontFamily: 'Figtree',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                StatusPill(
                                  text:
                                      '${tab == 2 ? _deltaAmount(weekInvoiceAmount, previousWeekInvoiceAmount) : _delta(weekCount, previousWeekCount)} vs sem. ant.',
                                  color: cyan,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _WeeklyChart(
                              counts: weeklyValues,
                              unit: tab == 0
                                  ? 'Envíos'
                                  : tab == 1
                                      ? 'Viajes'
                                      : 'C\$',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _LegendDot(color: figmaBlue),
                                SizedBox(width: 6),
                                Text(
                                  tab == 0
                                      ? 'Envíos realizados'
                                      : tab == 1
                                          ? 'Viajes realizados'
                                          : 'Facturas movilizadas',
                                  style: const TextStyle(
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
                    ),
                    const SizedBox(height: 96),
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

  bool _isTrip(Trip trip) {
    final mode = trip.serviceMode?.trim();
    if (mode?.isNotEmpty == true) return isTripServiceMode(mode);
    final legacyText = '${trip.id} ${trip.description ?? ''}'.toLowerCase();
    return legacyText.contains('taxi') ||
        trip.id.trim().toLowerCase().startsWith(RegExp(r'#?vj'));
  }

  DateTime? _tripDate(Trip trip) => summaryDateForTrip(trip, DateTime.now());

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  int _countIn(List<Trip> trips, DateTimeRange range) {
    return trips.where((trip) {
      final date = _tripDate(trip);
      return date != null &&
          !date.isBefore(range.start) &&
          date.isBefore(range.end);
    }).length;
  }

  String _delta(int current, int previous) {
    if (previous == 0) return current == 0 ? '0%' : 'Nuevo';
    final percent = ((current - previous) / previous * 100).round();
    return '${percent >= 0 ? '+' : ''}$percent%';
  }

  String _deltaAmount(double current, double previous) {
    if (previous == 0) return current == 0 ? '0%' : 'Nuevo';
    final percent = ((current - previous) / previous * 100).round();
    return '${percent >= 0 ? '+' : ''}$percent%';
  }

  List<int> _weeklyCounts(List<Trip> trips) {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return trips.where((trip) {
        final date = _tripDate(trip);
        return date != null && _sameDay(date, day);
      }).length;
    });
  }

  List<int> _weeklyInvoiceAmounts(List<Trip> trips, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final amount = summaryInvoiceTotalInRange(
        trips,
        DateTimeRange(start: day, end: day.add(const Duration(days: 1))),
        now,
      );
      return amount.round();
    });
  }

  String _bestDay(List<int> counts, String unit, {bool money = false}) {
    if (counts.every((value) => value == 0)) return 'Aún no hay actividad';
    const names = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    final index = counts.indexOf(counts.reduce((a, b) => a > b ? a : b));
    final total = counts[index];
    if (money) {
      return 'Tu mejor día fue el ${names[index]}\nFacturaste ${_money(total.toDouble())}';
    }
    return 'Tu mejor día fue el ${names[index]}\nRealizaste ${_thousand(total)} ${total == 1 ? unit : '${unit}s'}';
  }
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
    return AppGlassSurface(
      borderRadius: 18,
      selected: active,
      fillColor: active ? const Color(0x552F5FB0) : const Color(0x3A0A2C73),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                letterSpacing: .7,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: small ? 12.5 : 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 9,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                delta,
                style: const TextStyle(
                  color: mint,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatefulWidget {
  const _WeeklyChart({required this.counts, required this.unit});

  final List<int> counts;
  final String unit;

  @override
  State<_WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<_WeeklyChart> {
  static const shortLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const dayLabels = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = _bestIndex(widget.counts);
  }

  static int? _bestIndex(List<int> counts) {
    if (counts.isEmpty || counts.every((value) => value == 0)) return null;
    var index = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[index]) index = i;
    }
    return index;
  }

  @override
  void didUpdateWidget(covariant _WeeklyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.counts != widget.counts || oldWidget.unit != widget.unit) {
      selectedIndex = _bestIndex(widget.counts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highest =
        widget.counts.fold<int>(0, (max, value) => value > max ? value : max);
    return SizedBox(
      height: 136,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 7; i++)
            SizedBox(
              width: 32,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => selectedIndex = i),
                child: Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: selectedIndex == i
                          ? OverflowBox(
                              maxWidth: 96,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: 88,
                                child: _ChartTooltip(
                                  day: dayLabels[i],
                                  value: weeklyChartValueLabel(
                                    widget.counts[i],
                                    widget.unit,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 74,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 10,
                          height: highest == 0
                              ? 4
                              : (74 * widget.counts[i] / highest)
                                  .clamp(4, 74)
                                  .toDouble(),
                          decoration: BoxDecoration(
                            color: selectedIndex == i && highest > 0
                                ? figmaBlue
                                : const Color(0xFF31477E),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortLabels[i],
                      style: const TextStyle(
                        color: Color(0xFF8FA0C4),
                        fontSize: 10,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({required this.day, required this.value});

  final String day;
  final String value;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 8,
        fillColor: const Color(0x66334B83),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(day,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              Text(value,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree')),
            ],
          ),
        ),
      );
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
