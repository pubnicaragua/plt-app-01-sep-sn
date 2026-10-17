import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/invoice_selection.dart';
import '../core/theme.dart';
import '../core/trip_routing.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'finalizar_viaje.dart';

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
  final terminal = {
    'completado',
    'finalizado',
    'entregado',
    'entregada',
  }.contains(status);
  final active = !terminal && !{'cancelado', 'anulado'}.contains(status);
  final scheduled = trip.isScheduled ||
      trip.serviceType?.trim().toLowerCase() == 'programado';

  if (active && !scheduled) return DateUtils.dateOnly(now);

  if (terminal) {
    final completed = DateTime.tryParse(trip.completedAt ?? '');
    if (completed != null) return DateUtils.dateOnly(completed.toLocal());
  }

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

bool isInvoiceHistoryStatus(Trip trip) {
  final status = trip.status.trim().toLowerCase();
  return status == 'completado' ||
      status == 'finalizado' ||
      status == 'entregado' ||
      status == 'entregada';
}

bool tripHasInvoice(Trip trip) {
  final description = trip.description ?? '';
  return (trip.invoiceAmountCs ?? 0) > 0 ||
      (trip.estimatedCostCs ?? 0) > 0 ||
      trip.invoiceNumber?.trim().isNotEmpty == true ||
      trip.serviceInvoiceNumber?.trim().isNotEmpty == true ||
      trip.serviceInvoiceUrl?.trim().isNotEmpty == true ||
      trip.servicePaymentStatus?.trim().isNotEmpty == true ||
      RegExp(r'factura|pago', caseSensitive: false).hasMatch(description);
}

String invoicePaymentStatusForTrip(Trip trip) {
  final description = trip.description ?? '';
  final match = RegExp(
    r'(?:Estado factura producto|Estado pago envío|Estado de pago)\s*:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(description);
  final serviceStatus = trip.servicePaymentStatus?.trim();
  final invoiceStatus = trip.invoiceStatus?.trim();
  final raw = (serviceStatus?.isNotEmpty == true
          ? serviceStatus
          : invoiceStatus?.isNotEmpty == true
              ? invoiceStatus
              : match?.group(1) ?? '')!
      .trim()
      .toLowerCase();
  return raw.contains('pagad') || raw.contains('paid') || raw == 'contado'
      ? 'Pagada'
      : 'Pendiente';
}

bool invoicePaymentMatchesFilter(Trip trip, String filter) {
  if (filter == 'Todas') return true;
  final status = invoicePaymentStatusForTrip(trip);
  return (filter == 'Pendientes' && status == 'Pendiente') ||
      (filter == 'Pagadas' && status == 'Pagada');
}

DateTime? invoiceHistoryDateForTrip(Trip trip, {DateTime? fallback}) {
  final raw = trip.completedAt?.trim().isNotEmpty == true
      ? trip.completedAt
      : (trip.scheduledDate?.trim().isNotEmpty == true
          ? trip.scheduledDate
          : trip.date);
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed != null) return DateUtils.dateOnly(parsed.toLocal());
  return isInvoiceHistoryStatus(trip) && fallback != null
      ? DateUtils.dateOnly(fallback)
      : null;
}

String invoiceHistoryVehicleLabel(Trip trip, {required bool isTrip}) {
  final text =
      '${trip.vehicleVariant ?? ''} ${trip.truckType ?? ''} ${trip.transport ?? ''}'
          .toLowerCase();
  if (text.contains('moto')) return 'MOTO';
  if (text.contains('suv')) return 'SUV';
  if (text.contains('micro')) return 'MICROBUS';
  if (text.contains('sedan') || text.contains('sedán')) return 'SEDÁN';
  if (text.contains('auto') ||
      text.contains('carro') ||
      text.contains('vehiculo') ||
      text.contains('vehículo')) {
    return 'AUTO';
  }
  if (text.contains('grande')) return 'Camión grande';
  if (text.contains('mediano')) return 'Camión mediano';
  return isTrip ? 'AUTO' : 'Camión pequeño';
}

String invoiceServiceStatusForTrip(Trip trip) {
  final status = trip.status.trim().toLowerCase();
  if (status == 'entregado' || status == 'entregada') return 'Entregado';
  return 'Finalizado';
}

double invoiceHistoryAmountForTrip(Trip trip) =>
    trip.invoiceAmountCs ?? trip.estimatedCostCs ?? 0;

class ResumenCliente extends StatefulWidget {
  const ResumenCliente({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResumenCliente> createState() => _ResumenClienteState();
}

class _ResumenClienteState extends State<ResumenCliente> {
  late Future<List<Trip>> trips;
  int tab = 0; // 0 = Envíos, 1 = Viajes, 2 = Historial de facturas

  Future<List<Trip>> _fetchTrips() {
    final user = apiClient.currentUser;
    final clientName = user?.companyName?.trim();
    final client =
        user != null && (user.role == 'corporate' || user.role == 'company')
            ? (clientName?.isNotEmpty == true
                ? clientName
                : user.displayName.trim())
            : null;
    return apiClient.getTrips(client: client);
  }

  @override
  void initState() {
    super.initState();
    trips = _fetchTrips();
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
                if (tab == 2) {
                  return _InvoiceHistoryPanel(
                    trips: items,
                    loading: loading,
                    error: snapshot.error,
                    onTabChanged: (value) => setState(() {
                      tab = value;
                      // Al entrar al historial se vuelve a consultar la API
                      // para incluir facturas generadas recientemente.
                      trips = _fetchTrips();
                    }),
                  );
                }
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
                            (2, 'Historial de facturas'),
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

class _InvoiceHistoryPanel extends StatefulWidget {
  const _InvoiceHistoryPanel({
    required this.trips,
    required this.loading,
    required this.error,
    required this.onTabChanged,
  });

  final List<Trip> trips;
  final bool loading;
  final Object? error;
  final ValueChanged<int> onTabChanged;

  @override
  State<_InvoiceHistoryPanel> createState() => _InvoiceHistoryPanelState();
}

class _InvoiceHistoryPanelState extends State<_InvoiceHistoryPanel> {
  String statusFilter = 'Todas';
  String typeFilter = 'Todos';
  DateTimeRange? dateRange;
  bool bulkSelectionMode = false;
  Set<String> selectedPendingInvoiceIds = <String>{};

  List<Trip> get _pendingInvoices => widget.trips
      .where((trip) =>
          isInvoiceHistoryStatus(trip) &&
          invoicePaymentStatusForTrip(trip) == 'Pendiente')
      .toList();

  void _toggleBulkSelection() {
    final pendingIds = _pendingInvoices.map((trip) => trip.id);
    setState(() {
      bulkSelectionMode = !bulkSelectionMode;
      if (bulkSelectionMode) {
        statusFilter = 'Pendientes';
        typeFilter = 'Todos';
        dateRange = null;
      }
      selectedPendingInvoiceIds = bulkSelectionMode
          ? selectAllPendingInvoiceIds(pendingIds)
          : <String>{};
    });
  }

  void _toggleInvoice(String id) {
    setState(() {
      selectedPendingInvoiceIds = togglePendingInvoiceSelection(
        selectedPendingInvoiceIds,
        id,
      );
    });
  }

  bool _isTrip(Trip trip) {
    final mode = trip.serviceMode?.trim();
    if (mode?.isNotEmpty == true) return isTripServiceMode(mode);
    final legacy = '${trip.id} ${trip.description ?? ''}'.toLowerCase();
    return legacy.contains('taxi') ||
        trip.id.trim().toLowerCase().startsWith(RegExp(r'#?vj'));
  }

  DateTime? _dateOf(Trip trip) {
    return invoiceHistoryDateForTrip(trip, fallback: DateTime.now());
  }

  List<Trip> get _visibleTrips {
    final source = widget.trips.where((trip) {
      // Todo servicio terminado tiene una factura de servicio, aunque la API
      // todavía no haya devuelto su importe o código en la misma respuesta.
      if (!isInvoiceHistoryStatus(trip)) return false;
      if (typeFilter == 'Viajes' && !_isTrip(trip)) return false;
      if (typeFilter == 'Envíos' && _isTrip(trip)) return false;
      if (!invoicePaymentMatchesFilter(trip, statusFilter)) return false;
      final date = _dateOf(trip);
      if (date == null || dateRange == null) return dateRange == null;
      final start = DateUtils.dateOnly(dateRange!.start);
      final end =
          DateUtils.dateOnly(dateRange!.end).add(const Duration(days: 1));
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
    source.sort((a, b) =>
        (_dateOf(b) ?? DateTime(0)).compareTo(_dateOf(a) ?? DateTime(0)));
    return source;
  }

  Map<DateTime, List<Trip>> _grouped(List<Trip> trips) {
    final groups = <DateTime, List<Trip>>{};
    for (final trip in trips) {
      final date = _dateOf(trip);
      if (date == null) continue;
      groups.putIfAbsent(date, () => <Trip>[]).add(trip);
    }
    return groups;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: dateRange,
      builder: (context, child) => Theme(
        data: appDatePickerTheme(Theme.of(context)),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => dateRange = picked);
  }

  Future<void> _pickType() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF08255E),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in ['Todos', 'Envíos', 'Viajes'])
              ListTile(
                title: Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Figtree')),
                trailing: value == typeFilter
                    ? const Icon(Icons.check, color: cyan)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => typeFilter = picked);
  }

  String _dateTitle(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final months = const [
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
    final prefix = date == today
        ? 'Hoy'
        : date == yesterday
            ? 'Ayer'
            : date == today.subtract(const Duration(days: 2))
                ? 'Anteayer'
                : '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]}';
    return '$prefix · ${date.day} de ${months[date.month - 1]}';
  }

  Widget _segment(String label, int value, int selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected == value ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree')),
        ),
      ),
    );
  }

  Widget _filterSegment(String label) {
    final selected = statusFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => statusFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree')),
        ),
      ),
    );
  }

  Widget _filterButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x552B4E94),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleTrips;
    final groups = _grouped(visible);
    final pendingCount = widget.trips
        .where((trip) =>
            isInvoiceHistoryStatus(trip) &&
            invoicePaymentStatusForTrip(trip) == 'Pendiente')
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 96),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              SizedBox(height: 2),
              Text('Todo lo que necesitas saber',
                  style: TextStyle(
                      color: Color(0xE0FFFFFF),
                      fontSize: 10,
                      fontFamily: 'Figtree')),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Row(children: [
            _segment('Viajes', 1, 2),
            _segment('Envíos', 0, 2),
            _segment('Historial de facturas', 2, 2),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Row(children: [
            _filterSegment('Pendientes'),
            _filterSegment('Todas'),
            _filterSegment('Pagadas'),
          ]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _filterButton(
              label: dateRange == null ? 'Todas las fechas' : 'Rango de fechas',
              icon: Icons.calendar_today_outlined,
              onTap: _pickDateRange,
            ),
            _filterButton(
              label: typeFilter == 'Todos' ? 'Filtros' : typeFilter,
              icon: Icons.filter_alt_outlined,
              onTap: _pickType,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendingCount > 0)
          Column(
            children: [
              GestureDetector(
                onTap: _toggleBulkSelection,
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    bulkSelectionMode
                        ? 'Cancelar selección'
                        : 'Pagar todas las facturas pendientes',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree'),
                  ),
                ),
              ),
              if (bulkSelectionMode ||
                  selectedPendingInvoiceIds.isNotEmpty) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedPendingInvoiceIds.length} de $pendingCount seleccionadas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed:
                            selectedPendingInvoiceIds.isEmpty ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          disabledBackgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Pagar',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(28),
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        else if (widget.error != null)
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No pudimos cargar el historial de facturas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Figtree')),
            ),
          )
        else if (groups.isEmpty)
          GlassCard(
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text('No hay facturas para estos filtros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Figtree')),
            ),
          )
        else
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 11, 3, 7),
              child: Text(_dateTitle(entry.key),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
            ),
            for (final trip in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _InvoiceHistoryCard(
                  trip: trip,
                  isTrip: _isTrip(trip),
                  selectionMode: bulkSelectionMode,
                  selected: selectedPendingInvoiceIds.contains(trip.id),
                  selectable: invoicePaymentStatusForTrip(trip) == 'Pendiente',
                  onToggle: () => _toggleInvoice(trip.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FacturaServicioScreen(
                        trip: trip,
                        forceTravelLayout: _isTrip(trip),
                      ),
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _InvoiceHistoryCard extends StatelessWidget {
  const _InvoiceHistoryCard({
    required this.trip,
    required this.isTrip,
    this.selectionMode = false,
    this.selected = false,
    this.selectable = false,
    this.onToggle,
    required this.onTap,
  });

  final Trip trip;
  final bool isTrip;
  final bool selectionMode;
  final bool selected;
  final bool selectable;
  final VoidCallback? onToggle;
  final VoidCallback onTap;

  String _vehicle() {
    return invoiceHistoryVehicleLabel(trip, isTrip: isTrip);
  }

  String _asset() {
    switch (_vehicle()) {
      case 'MOTO':
        return 'assets/img/HomeCliente/figma_moto.png';
      case 'SUV':
        return 'assets/img/HomeCliente/taxi_suv.png';
      case 'MICROBUS':
        return 'assets/img/HomeCliente/taxi_microbus.png';
      case 'SEDÁN':
        return 'assets/img/HomeCliente/taxi_sedan.png';
      case 'Camión grande':
        return 'assets/img/HomeCliente/carga_grande.png';
      case 'Camión mediano':
        return 'assets/img/HomeCliente/carga_mediano.png';
      case 'AUTO':
        return 'assets/img/HomeCliente/figma_auto.png';
      default:
        return isTrip
            ? 'assets/img/HomeCliente/figma_auto.png'
            : 'assets/img/HomeCliente/carga_extra_pequeno.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceStatus = invoicePaymentStatusForTrip(trip);
    final serviceStatus = invoiceServiceStatusForTrip(trip);
    final amount = invoiceHistoryAmountForTrip(trip);
    final statusColor = invoiceStatus == 'Pagada'
        ? const Color(0xFF19D27D)
        : const Color(0xFFFFC928);
    return AppGlassSurface(
      borderRadius: 14,
      fillColor: const Color(0x55112F78),
      child: InkWell(
        onTap: selectionMode && selectable ? onToggle : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (selectable) ...[
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? accentBlue : Colors.white70,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                _InvoiceTag(
                    label: isTrip ? 'Viaje' : 'Envío', color: accentBlue),
                const SizedBox(width: 4),
                _InvoiceTag(label: invoiceStatus, color: statusColor),
                const SizedBox(width: 4),
                _InvoiceTag(
                    label: serviceStatus, color: const Color(0xFF19D27D)),
                const SizedBox(width: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child:
                        _InvoiceTag(label: _vehicle(), color: Colors.white24),
                  ),
                ),
              ]),
              const SizedBox(height: 11),
              Row(children: [
                SizedBox(
                  width: 54,
                  height: 38,
                  child: Image.asset(_asset(),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Image.asset(
                            'assets/img/HomeCliente/akar-icons_location.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(trip.origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Figtree')),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(
                          '${trip.pickupTime?.trim().isNotEmpty == true ? trip.pickupTime : 'Pendiente'}  •  #${trip.id.replaceFirst('#', '')}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 25),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.destination.trim().isEmpty
                          ? 'Destino pendiente'
                          : trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.5,
                          fontFamily: 'Figtree'),
                    ),
                  ),
                  Text(formatInvoiceHistoryAmount(amount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatInvoiceHistoryAmount(double amount) =>
    'C\$ ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';

class _InvoiceTag extends StatelessWidget {
  const _InvoiceTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color.computeLuminance() > 0.55
                    ? Colors.black
                    : Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree')),
      );
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
                              alignment: i == 0
                                  ? Alignment.topLeft
                                  : i == 6
                                      ? Alignment.topRight
                                      : Alignment.topCenter,
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
