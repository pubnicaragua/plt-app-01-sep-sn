import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/trip_routing.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'resumen_cliente.dart';
import 'envio_asignado.dart';
import 'seguimiento_pedido.dart';

String _vehicleData(Trip trip) =>
    '${trip.vehicleVariant ?? ''} ${trip.truckType ?? ''} '
            '${trip.transport ?? ''} ${trip.description ?? ''}'
        .toLowerCase();

bool _looksLikeTaxi(Trip trip, String value) =>
    value.contains(RegExp(r'viaje|taxi|vehículo|vehiculo')) ||
    trip.id.trim().toLowerCase().startsWith(RegExp(r'#?vj'));

String vehicleLabelForTrip(Trip trip) {
  final value = _vehicleData(trip);
  if (value.contains('microbus') || value.contains('microbús')) {
    return 'MICROBUS';
  }
  if (value.contains('suv')) return 'SUV';
  if (value.contains('sedán') || value.contains('sedan')) return 'SEDÁN';
  if (value.contains('moto')) return 'MOTO';
  if (value.contains('grande')) return 'Camión grande';
  if (value.contains('mediano')) return 'Camión mediano';
  if (value.contains('pequeño') || value.contains('pequeno')) {
    return 'Camión pequeño';
  }
  return _looksLikeTaxi(trip, value) ? 'AUTO' : 'CAMIÓN PEQUEÑO';
}

String vehicleAssetForTrip(Trip trip) {
  final value = _vehicleData(trip);
  final label = vehicleLabelForTrip(trip);
  switch (label) {
    case 'MICROBUS':
      return 'assets/img/HomeCliente/taxi_microbus.png';
    case 'SUV':
      return 'assets/img/HomeCliente/taxi_suv.png';
    case 'SEDÁN':
      return 'assets/img/HomeCliente/taxi_sedan.png';
    case 'MOTO':
      return 'assets/img/HomeCliente/figma_moto.png';
    case 'Camión grande':
      return 'assets/img/HomeCliente/carga_grande.png';
    case 'Camión mediano':
      return 'assets/img/HomeCliente/carga_mediano.png';
    case 'Camión pequeño':
      return 'assets/img/HomeCliente/carga_extra_pequeno.png';
    case 'AUTO':
      return 'assets/img/HomeCliente/figma_auto.png';
    default:
      return value.contains('camión') || value.contains('camion') ||
              value.contains('carga')
          ? 'assets/img/HomeCliente/figma_carga.png'
          : 'assets/img/HomeCliente/figma_auto.png';
  }
}

const tripLocationIconAsset =
    'assets/img/HomeCliente/akar-icons_location.png';
const tripScheduleIconAsset =
    'assets/img/HomeCliente/akar-icons_schedule.png';

bool shouldShowTripSchedule(Trip trip) {
  return trip.isScheduled ||
      trip.serviceType == 'Programado' ||
      !trip.isActive;
}

String tripIdLabel(Trip trip) {
  final id = trip.id.trim();
  return id.startsWith('#') ? id : '#$id';
}

String tripScheduleReference(Trip trip) {
  final time = trip.scheduledTime?.trim().isNotEmpty == true
      ? trip.scheduledTime!.trim()
      : trip.pickupTime?.trim().isNotEmpty == true
          ? trip.pickupTime!.trim()
          : 'Pendiente';
  return '$time  •  ${tripIdLabel(trip)}';
}

class MisEnvios extends StatefulWidget {
  const MisEnvios({super.key, this.onRefresh, this.embedded = false});

  final VoidCallback? onRefresh;
  final bool embedded;

  @override
  State<MisEnvios> createState() => _MisEnviosState();
}

class _MisEnviosState extends State<MisEnvios> {
  late Future<List<Trip>> trips;
  String tab = 'Activos';
  String typeFilter = 'Todos';
  String vehicleFilter = 'Todos';
  String historyStatus = 'Todos';
  String dateFilter = 'Todas las fechas';
  DateTime? activeDate;
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    trips = _loadTrips();
  }

  Future<List<Trip>> _loadTrips() {
    final user = apiClient.currentUser;
    final company = user?.companyName?.trim();
    final client =
        user != null && (user.role == 'corporate' || user.role == 'company')
            ? (company?.isNotEmpty == true ? company : user.displayName.trim())
            : null;
    return apiClient.getTrips(client: client);
  }

  void _reload() {
    setState(() => trips = _loadTrips());
    widget.onRefresh?.call();
  }

  bool _isScheduled(Trip trip) =>
      trip.isScheduled || trip.serviceType == 'Programado';

  bool _isTrip(Trip trip) {
    final mode = trip.serviceMode?.trim();
    if (mode?.isNotEmpty == true) return isTripServiceMode(mode);
    final legacyText = '${trip.id} ${trip.description ?? ''}'.toLowerCase();
    return legacyText.contains('taxi') ||
        trip.id.trim().toLowerCase().startsWith(RegExp(r'#?vj'));
  }

  bool _matchesHistoryStatus(Trip trip) {
    if (historyStatus == 'Todos') return true;
    final status = trip.status.toLowerCase();
    return switch (historyStatus) {
      'Finalizados' => status == 'completado' || status == 'finalizado',
      'Entregados' => status == 'entregado' || status == 'entregada',
      'Cancelados' => status == 'cancelado' || status == 'anulado',
      _ => true,
    };
  }

  String _vehicle(Trip trip) => vehicleLabelForTrip(trip);

  DateTime? _dateOf(Trip trip) {
    // Los servicios activos sin programación representan actividad de hoy en
    // la app, aunque la API conserve una fecha de creación diferente.
    if (trip.isActive && !_isScheduled(trip)) {
      return DateUtils.dateOnly(DateTime.now());
    }
    final raw = _isScheduled(trip) ? trip.scheduledDate : trip.date;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    return parsed == null ? null : DateUtils.dateOnly(parsed.toLocal());
  }

  bool _matchesDate(Trip trip) {
    if (activeDate != null) {
      final date = _dateOf(trip);
      if (date == null) return false;
      final selected = DateUtils.dateOnly(activeDate!);
      return DateUtils.dateOnly(date) == selected;
    }
    if (dateFilter == 'Todas las fechas') return true;
    final date = _dateOf(trip);
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (dateFilter == 'Hoy') return day == today;
    if (dateFilter == 'Esta semana') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return !day.isBefore(start) &&
          day.isBefore(start.add(const Duration(days: 7)));
    }
    if (dateFilter == 'Este mes') {
      return day.year == today.year && day.month == today.month;
    }
    if (dateFilter == 'Mes pasado') {
      final previous = DateTime(today.year, today.month - 1);
      return day.year == previous.year && day.month == previous.month;
    }
    final range = customRange;
    return range == null ||
        (!day.isBefore(DateUtils.dateOnly(range.start)) &&
            !day.isAfter(DateUtils.dateOnly(range.end)));
  }

  List<Trip> _visible(List<Trip> source) {
    return source.where((trip) {
      final inTab = switch (tab) {
        'Activos' => trip.isActive && !_isScheduled(trip),
        'Programados' => trip.isActive && _isScheduled(trip),
        'Historial' => !trip.isActive,
        _ => true,
      };
      final typeOk = typeFilter == 'Todos' ||
          (typeFilter == 'Viajes' ? _isTrip(trip) : !_isTrip(trip));
      final vehicleOk =
          vehicleFilter == 'Todos' || _vehicle(trip) == vehicleFilter;
      final statusOk = tab != 'Historial' || _matchesHistoryStatus(trip);
      final dateOk = _matchesDate(trip);
      return inTab && typeOk && vehicleOk && statusOk && dateOk;
    }).toList();
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: accentBlue),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        customRange = range;
        dateFilter = 'Rango de fecha';
      });
    }
  }

  void _openTrip(Trip trip) {
    if (!trip.isActive) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF08255E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Detalle del ${_isTrip(trip) ? 'viaje' : 'envío'}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              const SizedBox(height: 12),
              Text('${trip.statusLabel} · ${trip.origin} → ${trip.destination}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Figtree')),
            ]),
          ),
        ),
      );
      return;
    }
    if (_isScheduled(trip) &&
        isScheduledBeforeStart(trip, DateTime.now())) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EnvioAsignadoScreen(trip: trip),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SeguimientoPedido(trip: trip),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: FutureBuilder<List<Trip>>(
        future: trips,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <Trip>[];
          final visible = _visible(items);
          final tabCounts = <String, int>{
            'Activos': items
                .where((trip) => trip.isActive && !_isScheduled(trip))
                .length,
            'Programados': items
                .where((trip) => trip.isActive && _isScheduled(trip))
                .length,
            'Historial': items.where((trip) => !trip.isActive).length,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            children: [
              const Text('Envíos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              const SizedBox(height: 3),
              const Text('Consulta y administra todos tus viajes y envíos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'Figtree')),
              const SizedBox(height: 14),
              _SegmentedRow(
                  values: const ['Activos', 'Programados', 'Historial'],
                  selected: tab,
                  counts: tabCounts,
                  onChanged: (value) => setState(() {
                        tab = value;
                        dateFilter = 'Todas las fechas';
                        activeDate = null;
                        historyStatus = 'Todos';
                        customRange = null;
                      })),
              const SizedBox(height: 8),
              _SegmentedRow(
                  values: const ['Todos', 'Envíos', 'Viajes'],
                  selected: typeFilter,
                  compact: true,
                  onChanged: (value) => setState(() => typeFilter = value)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final width = ((MediaQuery.sizeOf(context).width - 36) * .40)
                    .clamp(120.0, 145.0)
                    .toDouble();
                return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SizedBox(
                    width: width,
                    child: _FilterButton(
                        label: tab == 'Activos'
                            ? (activeDate == null
                                ? 'Hoy'
                                : _formatDate(activeDate!))
                            : dateFilter,
                        icon: Icons.calendar_today_outlined,
                        compact: true,
                        onTap: tab == 'Activos'
                            ? _pickActiveDate
                            : () => _showDateMenu())),
                const SizedBox(width: 8),
                SizedBox(
                    width: width,
                    child: _FilterButton(
                        label: tab == 'Historial' && historyStatus != 'Todos'
                            ? historyStatus
                            : vehicleFilter == 'Todos'
                                ? 'Filtros'
                                : vehicleFilter,
                        icon: Icons.filter_alt_outlined,
                        compact: true,
                        onTap: _showVehicleMenu)),
                ]);
              }),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(color: Colors.white)))
              else if (snapshot.hasError)
                GlassCard(
                    child: Column(children: [
                  const Icon(Icons.cloud_off_outlined, color: Colors.white70),
                  const SizedBox(height: 8),
                  Text(
                      'No pudimos cargar tus envíos:\n${t(snapshot.error.toString())}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Figtree')),
                  TextButton(
                      onPressed: _reload, child: const Text('Reintentar'))
                ]))
              else if (visible.isEmpty)
                GlassCard(
                    child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                            items.isEmpty
                                ? 'Aún no tienes envíos.'
                                : activeDate != null
                                    ? 'No hay envíos activos para el ${_formatDate(activeDate!)}.'
                                    : tab == 'Programados' && dateFilter != 'Todas las fechas'
                                        ? 'No hay envíos programados para esta fecha.'
                                        : 'No hay resultados para estos filtros.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Figtree'))))
              else
                if (tab == 'Programados')
                  _ScheduledGroups(
                      trips: visible,
                      vehicle: _vehicle,
                      isTrip: _isTrip,
                      dateOf: _dateOf,
                      onTap: _openTrip)
                else
                  ...visible.map((trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FigmaTripCard(
                          trip: trip,
                          vehicle: _vehicle(trip),
                          isTrip: _isTrip(trip),
                          onTap: () => _openTrip(trip)))),
              const SizedBox(height: 6),
              GlassButton(
                  label: 'Ver resumen del periodo',
                  height: 48,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ResumenCliente()))),
            ],
          );
        },
      ),
    );
    return widget.embedded ? content : AppBackground(child: content);
  }

  Future<void> _showDateMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF08255E),
      builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final value in [
          'Todas las fechas',
          'Esta semana',
          'Este mes',
          'Mes pasado'
        ])
          ListTile(
              title: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Figtree')),
              onTap: () => Navigator.pop(context, value)),
        ListTile(
            title: const Text('Rango de fecha',
                style: TextStyle(color: Colors.white, fontFamily: 'Figtree')),
            onTap: () => Navigator.pop(context, 'Rango de fecha')),
      ])),
    );
    if (selected == 'Rango de fecha') return _pickRange();
    if (selected != null) setState(() => dateFilter = selected);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  Future<void> _pickActiveDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: activeDate ?? DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: accentBlue),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        activeDate = selected;
        dateFilter = 'Todas las fechas';
      });
    }
  }

  Future<void> _showVehicleMenu() async {
    final selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF08255E),
        builder: (_) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (tab != 'Historial') ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Text('Filtrar por vehículo',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree')),
                    ),
                    for (final value in [
                      'Todos',
                      'SUV',
                      'SEDÁN',
                      'MOTO',
                      'AUTO',
                      'Camión pequeño',
                      'Camión mediano',
                      'Camión grande'
                    ])
                      ListTile(
                          title: Text(value,
                              style: const TextStyle(
                                  color: Colors.white, fontFamily: 'Figtree')),
                          onTap: () =>
                              Navigator.pop(context, 'vehicle:$value')),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text('Filtrar estado',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree')),
                    ),
                    for (final value in [
                      'Todos',
                      'Finalizados',
                      'Entregados',
                      'Cancelados'
                    ])
                      ListTile(
                          title: Text(value,
                              style: const TextStyle(
                                  color: Colors.white, fontFamily: 'Figtree')),
                          onTap: () => Navigator.pop(context, 'status:$value')),
                  ],
                ],
              ),
            ));
    if (selected == null) return;
    if (selected.startsWith('vehicle:')) {
      setState(() => vehicleFilter = selected.substring(8));
    } else if (selected.startsWith('status:')) {
      setState(() => historyStatus = selected.substring(7));
    }
  }
}

class _ScheduledGroups extends StatelessWidget {
  const _ScheduledGroups({
    required this.trips,
    required this.vehicle,
    required this.isTrip,
    required this.dateOf,
    required this.onTap,
  });

  final List<Trip> trips;
  final String Function(Trip) vehicle;
  final bool Function(Trip) isTrip;
  final DateTime? Function(Trip) dateOf;
  final void Function(Trip) onTap;

  String _label(DateTime? date) {
    if (date == null) return 'Fecha pendiente';
    final day = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final prefix = day == tomorrow
        ? 'Mañana'
        : day == today
            ? 'Hoy'
            : weekdays[day.weekday - 1];
    return '$prefix · ${day.day} de ${months[day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Trip>>{};
    final dates = <String, DateTime?>{};
    for (final trip in trips) {
      final date = dateOf(trip);
      final key = date == null
          ? 'pending'
          : DateUtils.dateOnly(date).toIso8601String();
      grouped.putIfAbsent(key, () => []).add(trip);
      dates[key] = date;
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final left = dates[a];
        final right = dates[b];
        if (left == null) return 1;
        if (right == null) return -1;
        return left.compareTo(right);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
            child: Text(
              _label(dates[key]),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          for (final trip in grouped[key]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FigmaTripCard(
                trip: trip,
                vehicle: vehicle(trip),
                isTrip: isTrip(trip),
                onTap: () => onTap(trip),
              ),
            ),
        ],
      ],
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.values,
    required this.selected,
    required this.onChanged,
    this.counts = const {},
    this.compact = false,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, int> counts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final value in values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: compact && value != values.last ? 6 : 0),
              child: _SegmentedItem(
                label: value,
                count: counts[value],
                selected: value == selected,
                compact: compact,
                onTap: () => onChanged(value),
              ),
            ),
          ),
      ],
    );
    if (compact) return SizedBox(height: 27, child: row);
    return Container(
      height: 38,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: row,
    );
  }
}

class _SegmentedItem extends StatelessWidget {
  const _SegmentedItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 16 : 19),
            border: compact
                ? Border.all(color: Colors.white.withValues(alpha: .18))
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(color: Color(0x552B8CFF), blurRadius: 8),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                AppGlassSurface(
                  borderRadius: 9,
                  child: SizedBox(
                    width: 17,
                    height: 17,
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow(
      {required this.values, required this.selected, required this.onChanged});
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
              child: Padding(
                  padding:
                      EdgeInsets.only(right: i == values.length - 1 ? 0 : 6),
                  child: _FilterButton(
                      label: values[i],
                      selected: values[i] == selected,
                      onTap: () => onChanged(values[i]))))
      ]);
}

class _FilterButton extends StatelessWidget {
  const _FilterButton(
      {required this.label,
      required this.onTap,
      this.selected = false,
      this.icon,
      this.compact = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;
  final bool compact;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10, vertical: compact ? 6 : 9),
              decoration: BoxDecoration(
                  color: selected
                      ? accentBlue
                      : Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(compact ? 16 : 18),
                  border: Border.all(
                      color: selected
                          ? cyan.withValues(alpha: .6)
                          : Colors.white.withValues(alpha: .22))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: compact ? 12 : 13),
                  SizedBox(width: compact ? 4 : 5)
                ],
                Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree')))
              ]))));
}

class _FigmaTripCard extends StatelessWidget {
  const _FigmaTripCard(
      {required this.trip,
      required this.vehicle,
      required this.isTrip,
      required this.onTap});
  final Trip trip;
  final String vehicle;
  final bool isTrip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheduled = trip.isScheduled || trip.serviceType == 'Programado';
    final showSchedule = shouldShowTripSchedule(trip);
    final statusColor = trip.isActive
        ? const Color(0xFF19D27D)
        : trip.status == 'Cancelado'
            ? const Color(0xFFE84D68)
            : const Color(0xFF19D27D);
    final kind = isTrip ? 'Viaje' : 'Envío';
    return AppGlassSurface(
        borderRadius: 18,
        fillColor: const Color(0x55112F78),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: isTrip
                                    ? const Color(0xFFFFC928)
                                    : accentBlue,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(kind,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree'))),
                        if (scheduled) ...[
                          const SizedBox(width: 5),
                          _Tag(
                              label: 'Programado',
                              color: const Color(0xFF9657E8))
                        ],
                        const SizedBox(width: 5),
                        _Tag(
                            label: vehicle,
                            color: Colors.white.withValues(alpha: .14),
                            glass: true)
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        SizedBox(
                            width: 58,
                            height: 42,
                            child: Image.asset(vehicleAssetForTrip(trip),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.local_shipping_outlined,
                                    color: Colors.white))),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Image.asset(tripLocationIconAsset,
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white,
                                        size: 18)),
                                const SizedBox(width: 4),
                                Expanded(
                                    child: Text(
                                        trip.origin.trim().isEmpty
                                            ? 'Origen pendiente'
                                            : trip.origin,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Figtree')))
                              ]),
                              if (showSchedule) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Image.asset(tripScheduleIconAsset,
                                      width: 18,
                                      height: 18,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.schedule_outlined,
                                          color: Colors.white70,
                                          size: 18)),
                                  const SizedBox(width: 4),
                                  Text(tripScheduleReference(trip),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontFamily: 'Figtree'))
                                ])
                              ] else
                                Text(tripIdLabel(trip),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontFamily: 'Figtree'))
                            ])),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 27)
                      ]),
                      const SizedBox(height: 8),
                      if (!scheduled)
                        Row(children: [
                          Icon(Icons.radio_button_checked,
                              color: statusColor, size: 11),
                          const SizedBox(width: 5),
                          Text(trip.statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Figtree')),
                          const Spacer(),
                          Text(
                              trip.destination.trim().isEmpty
                                  ? 'Destino pendiente'
                                  : trip.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontFamily: 'Figtree'))
                        ]),
                      if (trip.isActive && !scheduled) ...[
                        const SizedBox(height: 7),
                        _TripProgress(trip: trip),
                      ]
                    ]))));
  }
}

class _TripProgress extends StatelessWidget {
  const _TripProgress({required this.trip});

  final Trip trip;
  static const steps = ['En camino', 'Recogió', 'En viaje', 'Finalizado'];

  int get done {
    switch (trip.status.toLowerCase()) {
      case 'en camino':
        return 1;
      case 'recogió':
      case 'recogio':
      case 'en entrega':
      case 'entregando':
        return 2;
      case 'en viaje':
        return 3;
      case 'finalizado':
      case 'completado':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index < done
                      ? const Color(0xFF168DFF)
                      : Colors.white.withValues(alpha: .35),
                  shape: BoxShape.circle,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index + 1 < done
                        ? const Color(0xFF168DFF)
                        : Colors.white.withValues(alpha: .25),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < steps.length; index++)
              Text(
                steps[index],
                style: TextStyle(
                  color: index < done ? Colors.white : Colors.white60,
                  fontSize: 7.5,
                  fontFamily: 'Figtree',
                  fontWeight:
                      index + 1 == done ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.glass = false});
  final String label;
  final Color color;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree')),
    );
    if (glass) {
      return AppGlassSurface(
        borderRadius: 9,
        fillColor: color,
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree')),
    );
  }
}
