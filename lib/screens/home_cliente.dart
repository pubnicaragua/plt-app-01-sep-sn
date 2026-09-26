import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/corte_banner.dart';
import '../widgets/glass.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/place_field.dart';
import 'inicio.dart';
import 'crear_envio1.dart';
import 'seleccionar_puntos_envio.dart';
import 'pedido.dart';
import 'mi_perfil_cliente.dart';
import 'resumen_cliente.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  int tab = 0;
  int _tripRefreshVersion = 0;

  void _openShipments() {
    setState(() {
      tab = 1;
      _tripRefreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[
      _FigmaHomeTab(onOpenShipments: _openShipments),
      MisEnvios(
        key: ValueKey('mis-envios-$_tripRefreshVersion'),
        embedded: true,
      ),
      ResumenCliente(
        key: ValueKey('resumen-$_tripRefreshVersion'),
        embedded: true,
      ),
      const MiPerfilCliente(embedded: true),
    ];
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: AppBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24 + safeBottom),
                child: Column(
                  children: [
                    const CorteBanner(),
                    Expanded(
                      child: IndexedStack(
                        index: tab,
                        children: views,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: safeBottom + 8,
              child: AppNavBar(
                current: tab,
                onChanged: (index) => setState(() {
                  tab = index;
                  if (index == 1 || index == 2) _tripRefreshVersion++;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.close_rounded, color: cyan, size: 26),
      ),
    );
  }
}

class _FigmaHomeTab extends StatefulWidget {
  const _FigmaHomeTab({this.onOpenShipments});

  final VoidCallback? onOpenShipments;

  @override
  State<_FigmaHomeTab> createState() => _FigmaHomeTabState();
}

class _FigmaHomeTabState extends State<_FigmaHomeTab> {
  String? selectedVehicle;
  List<Trip> activeTrips = const <Trip>[];
  Timer? activeTripsTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
    activeTripsTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadActiveTrips(),
    );
  }

  @override
  void dispose() {
    activeTripsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveTrips() async {
    try {
      final user = apiClient.currentUser;
      final companyName = user?.companyName?.trim();
      final client =
          user != null && (user.role == 'corporate' || user.role == 'company')
              ? (companyName?.isNotEmpty == true
                  ? companyName
                  : user.displayName.trim())
              : null;
      final trips = await apiClient.getTrips(client: client);
      if (!mounted) return;
      setState(() {
        activeTrips = trips.where((trip) => trip.isActive).toList();
      });
    } catch (_) {}
  }

  void _openCreateFlow(String vehicle) {
    final transport = vehicle == 'Auto'
        ? 'Vehículo'
        : vehicle == 'Carga'
            ? 'Camión'
            : 'Moto';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeleccionarPuntosEnvio(
          startTransport: transport,
          onOpenMap: (result) async {
            return Navigator.of(context).push<RouteSelectionResult>(
              MaterialPageRoute(
                builder: (_) => CrearEnvio1(
                  startOrigin: result.origin,
                  startDestination: result.destination,
                  startOriginPlace: result.originPlace,
                  startDestinationPlace: result.destinationPlace,
                  startTransport: transport,
                  returnToPointSelection: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : 'Logística Nica SA';
    final horizontal = MediaQuery.sizeOf(context).width < 380 ? 16.0 : 20.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 22),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '¿Qué vas a enviar hoy?',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
            _HeaderCircle(
              icon: Icons.notifications_none_rounded,
              onTap: () => showAppNotifications(context),
            ),
            const SizedBox(width: 9),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                shape: BoxShape.circle,
                border: Border.all(color: glassBorder),
              ),
              alignment: Alignment.center,
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
          ],
        ),
        const SizedBox(height: 14),
        if (activeTrips.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Envíos activos:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpenShipments,
                  borderRadius: BorderRadius.circular(18),
                  hoverColor: Colors.white.withValues(alpha: .12),
                  splashColor: Colors.white.withValues(alpha: .22),
                  highlightColor: Colors.white.withValues(alpha: .10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentBlue,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Ver todos envíos activos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final trip in activeTrips.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: _ActiveShipmentCard(trip: trip),
              ),
            ),
          const SizedBox(height: 5),
        ],
        const Text(
          'Envíos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _VehicleShowcaseCard(
                label: 'Moto',
                subtitle: 'Envíos pequeños',
                asset: 'assets/img/HomeCliente/figma_moto.png',
                selected: selectedVehicle == 'Moto',
                onTap: () {
                  setState(() => selectedVehicle = 'Moto');
                  _openCreateFlow('Moto');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VehicleShowcaseCard(
                label: 'Auto',
                subtitle: 'Espacios medianos',
                asset: 'assets/img/HomeCliente/figma_auto.png',
                selected: selectedVehicle == 'Auto',
                onTap: () {
                  setState(() => selectedVehicle = 'Auto');
                  _openCreateFlow('Auto');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VehicleShowcaseCard(
          label: 'Carga',
          subtitle: 'Mayor espacio para todo tipo de envíos',
          asset: 'assets/img/HomeCliente/figma_carga.png',
          selected: selectedVehicle == 'Carga',
          large: true,
          onTap: () {
            setState(() => selectedVehicle = 'Carga');
            _openCreateFlow('Carga');
          },
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: double.infinity,
          child: _NeedLocationButton(),
        ),
        const SizedBox(height: 10),
        const _LogisticsBanner(),
      ],
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            shape: BoxShape.circle,
            border: Border.all(color: glassBorder),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

class _LogisticsBanner extends StatelessWidget {
  const _LogisticsBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: AspectRatio(
        aspectRatio: 398 / 163,
        child: Image.asset(
          'assets/img/HomeCliente/banner_seguro.png',
          fit: BoxFit.cover,
          semanticLabel: 'Seguro para tus envíos',
        ),
      ),
    );
  }
}

class _NeedLocationButton extends StatelessWidget {
  const _NeedLocationButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1555D1), Color(0xFF0D3DA7)],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: cyan.withValues(alpha: .24)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Image.asset(
                  'assets/img/HomeCliente/necesitas_ir.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_walk_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '¿Necesitas ir a algún lugar?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x664D8FFF),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: accentBlue,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleShowcaseCard extends StatelessWidget {
  const _VehicleShowcaseCard({
    required this.label,
    required this.subtitle,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final String subtitle;
  final String asset;
  final bool selected;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        hoverColor: Colors.white.withValues(alpha: .08),
        splashColor: cyan.withValues(alpha: .22),
        highlightColor: Colors.white.withValues(alpha: .06),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: CustomPaint(
            foregroundPainter: _GlassEdgePainter(selected: selected),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: large ? 160 : 166,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                color: selected
                    ? const Color(0x4D1E5FD4)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(1, 5),
                      blurRadius: 4.7,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                  Positioned.fill(
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 11,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 5,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .10),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .20)),
                      ),
                      child: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(19);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: selected
            ? [cyan.withValues(alpha: .95), Colors.white.withValues(alpha: .42), cyan.withValues(alpha: .75)]
            : [Colors.white.withValues(alpha: .48), Colors.white.withValues(alpha: .10), const Color(0x667EA5D8)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(.6), radius), paint);
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) =>
      oldDelegate.selected != selected;
}

class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 59,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1555D1), Color(0xFF0D3DA7)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x99FFFFFF),
                    blurRadius: 13,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Color(0x663B8BFF),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/img/HomeCliente/figma_box.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.statusLabel,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree'),
                  ),
                  Text(
                    '#${trip.id}',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 10,
                        fontFamily: 'Figtree'),
                  ),
                  Text(
                    trip.destination.isEmpty ? trip.origin : trip.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 9,
                        fontFamily: 'Figtree'),
                  ),
                ],
              ),
            ),
            Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x99FFFFFF),
                    blurRadius: 13,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Color(0x663B8BFF),
                    blurRadius: 12,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.chevron_right, color: accentBlue, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool programado = true;
  String transport = 'Moto';
  AppSettings? settings;
  DateTime? agendaDate;
  TimeOfDay? agendaTime;
  final origin = TextEditingController();
  final destination = TextEditingController();
  final refOrigin = TextEditingController();
  final refDestination = TextEditingController();
  final recipientName = TextEditingController();
  final recipientPhone = TextEditingController();
  PlaceSuggestion? originPlace;
  PlaceSuggestion? destinationPlace;
  Timer? _incidentPoll;
  final Set<String> _seenIncidentIds = {};
  int _incidentUnread = 0;
  String? _incidentError;

  @override
  void initState() {
    super.initState();
    apiClient.getSettings().then((data) {
      if (mounted) setState(() => settings = data);
    }).catchError((_) {});
    requestAppPermissions().then((location) {
      if (!mounted || location == null || origin.text.isNotEmpty) return;
      final place = PlaceSuggestion(
        placeId: 'current',
        description: location.label,
        main: location.label,
        secondary: 'Managua',
        latitude: location.latitude,
        longitude: location.longitude,
      );
      setState(() {
        originPlace = place;
        origin.text = location.label;
      });
    });
    _checkRemoteSession();
    _pollIncidentNotifications();
    _incidentPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _pollIncidentNotifications();
        _refreshSettings();
      },
    );
  }

  Future<void> _refreshSettings() async {
    try {
      final data = await apiClient.getSettings();
      if (mounted) setState(() => settings = data);
    } catch (_) {}
  }

  Future<void> _pollIncidentNotifications() async {
    try {
      final incidents = await apiClient.getIncidentNotifications();
      if (!mounted) return;
      final fresh = incidents
          .where((incident) =>
              incident.id.isNotEmpty && !_seenIncidentIds.contains(incident.id))
          .toList(growable: false);
      if (fresh.isEmpty) return;
      for (final incident in fresh) {
        _seenIncidentIds.add(incident.id);
      }
      setState(() => _incidentUnread += fresh.length);
      final latest = fresh.first;
      final title = latest.isGeneral
          ? 'Aviso operativo: ${latest.type}'
          : 'Incidencia en viaje ${latest.trip}';
      final body = latest.description.trim().isEmpty
          ? 'Prioridad ${latest.priority}'
          : latest.description.trim();
      pushNotification(title: title, body: body, id: latest.id.hashCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1D4D),
          behavior: SnackBarBehavior.floating,
          content: Text(
            '$title · $body',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      if (message.isNotEmpty && message != _incidentError) {
        setState(() => _incidentError = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron consultar incidencias: $message'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _checkRemoteSession() async {
    final ok = await apiClient.checkSession();
    if (!mounted || ok) return;
    await apiClient.clearSession();
    if (!mounted) return;
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Inicio()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _incidentPoll?.cancel();
    origin.dispose();
    destination.dispose();
    refOrigin.dispose();
    refDestination.dispose();
    recipientName.dispose();
    recipientPhone.dispose();
    super.dispose();
  }

  double? get _km => distanceKm(originPlace, destinationPlace);

  double? _fareFor(String vehicle) {
    final km = _km;
    if (km == null) return null;
    final rate = settings?.rateFor(vehicle);
    if (rate == null) return null;
    final chargeableKm =
        (km - rate.includedKm).clamp(0, double.infinity).toDouble();
    return roundFareCs(
        rate.baseFeeCs +
            chargeableKm * rate.farePerKmCs +
            logisticsServiceFeeCs,
        settings?.fareRoundingCs ?? 5);
  }

  static const _dayOptions = ['Hoy', 'Mañana'];
  static const _hourOptions = ['09:00', '12:00', '15:00', '18:00'];

  DateTime _slot(int dayIndex, String hour) {
    final now = DateTime.now();
    final parts = hour.split(':');
    final base =
        DateTime(now.year, now.month, now.day).add(Duration(days: dayIndex));
    return DateTime(base.year, base.month, base.day, int.parse(parts[0]),
        int.parse(parts[1]));
  }

  void _pickSlot(int dayIndex, String hour) {
    final now = DateTime.now();
    final candidate = _slot(dayIndex, hour);
    if (candidate.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Esa hora ya pasó. Elige otra hora o elige Mañana.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    if (candidate.isAfter(now.add(const Duration(hours: 24)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Solo se puede programar dentro de las próximas 24 horas.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    final parts = hour.split(':');
    setState(() {
      agendaDate = candidate;
      agendaTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    });
  }

  (DateTime, TimeOfDay) _defaultAgendaSlot() {
    final now = DateTime.now().add(const Duration(minutes: 30));
    final today = DateTime(now.year, now.month, now.day);
    for (final hour in _hourOptions) {
      final parts = hour.split(':');
      final candidate = DateTime(today.year, today.month, today.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (candidate.isAfter(now)) {
        return (
          candidate,
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
        );
      }
    }
    return (
      today.add(const Duration(days: 1)),
      const TimeOfDay(hour: 9, minute: 0),
    );
  }

  void _autoAgenda() {
    final slot = _defaultAgendaSlot();
    setState(() {
      agendaDate = slot.$1;
      agendaTime = slot.$2;
    });
  }

  String _formatAgendaDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatAgendaTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String? get _agendaDateString {
    final date = agendaDate;
    if (date == null) return null;
    return _formatAgendaDate(date);
  }

  String? get _agendaTimeString {
    final time = agendaTime;
    if (time == null) return null;
    return _formatAgendaTime(time);
  }

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    final apiName = user?.displayName.trim() ?? '';
    final displayName = apiName.isEmpty ? 'Usuario INCOEX' : apiName;
    final horizontal = MediaQuery.sizeOf(context).width < 380 ? 16.0 : 20.0;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 22),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $displayName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  const Text(
                    '¿Qué vas a enviar hoy?',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12.5,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _incidentUnread = 0);
                  showAppNotifications(context);
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .25)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/img/HomeCliente/notificaciones.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        semanticLabel: 'Notificaciones',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (_incidentUnread > 0)
                        Positioned(
                          top: 3,
                          right: 2,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: 16,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A5A),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              _incidentUnread > 9 ? '9+' : '$_incidentUnread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: cyan, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .16),
                border: Border.all(color: glassBorder),
              ),
              child: Center(
                child: Text(
                  initials(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Selecciona el transporte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _TransportTile(
                iconAsset: 'assets/img/HomeCliente/moto.png',
                label: 'Moto',
                selected: transport == 'Moto',
                onTap: () => setState(() => transport = 'Moto'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _TransportTile(
                iconAsset: 'assets/img/HomeCliente/vehiculo.png',
                label: 'Carro',
                selected: transport == 'Vehículo',
                onTap: () => setState(() => transport = 'Vehículo'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _TransportTile(
                iconAsset: 'assets/img/HomeCliente/camion.png',
                label: 'Camión',
                selected: transport == 'Camión',
                onTap: () => setState(() => transport = 'Camión'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EditableRouteCard(
          origin: origin,
          destination: destination,
          onOriginSelected: (place) => setState(() => originPlace = place),
          onDestinationSelected: (place) =>
              setState(() => destinationPlace = place),
        ),
        const SizedBox(height: 12),
        _FareCard(
          km: _km,
          fare: _fareFor(transport),
          transportLabel: transport,
          rate: settings?.rateFor(transport),
          fareRoundingCs: settings?.fareRoundingCs ?? 5,
          usdRate: settings?.dollarRate ?? 36.5,
        ),
        const SizedBox(height: 12),
        _ReferencesCard(
          originController: refOrigin,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassField(
                label: 'Destinatario',
                hint: 'Nombre completo',
                icon: Icons.person_outline_rounded,
                controller: recipientName,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassField(
                label: 'Teléfono',
                hint: '+505 …',
                icon: Icons.call_outlined,
                controller: recipientPhone,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PriorityBar(
          programado: programado,
          onChanged: (value) {
            setState(() => programado = value);
            if (value && agendaDate == null) _autoAgenda();
          },
        ),
        if (programado) ...[
          const SizedBox(height: 12),
          _ScheduleCard(
            selectedDate: agendaDate,
            selectedTime: agendaTime,
            onPick: _pickSlot,
          ),
        ],
        const SizedBox(height: 18),
        GlassButton(
          label: 'Solicitar nuevo envío',
          filled: true,
          textColor: Colors.white,
          onPressed: () {
            var selectedDate = agendaDate;
            var selectedTime = agendaTime;
            if (programado && (selectedDate == null || selectedTime == null)) {
              final slot = _defaultAgendaSlot();
              selectedDate = slot.$1;
              selectedTime = slot.$2;
              setState(() {
                agendaDate = selectedDate;
                agendaTime = selectedTime;
              });
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Pedido(
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  originPlace: originPlace,
                  destinationPlace: destinationPlace,
                  transport: transport,
                  estimatedShipping: _fareFor(transport),
                  originRefs: refOrigin.text.trim(),
                  destinationRefs: refDestination.text.trim(),
                  recipientName: recipientName.text.trim(),
                  recipientPhone: recipientPhone.text.trim(),
                  startScheduled: programado,
                  startDate: selectedDate == null
                      ? null
                      : _formatAgendaDate(selectedDate),
                  startTime: selectedTime == null
                      ? null
                      : _formatAgendaTime(selectedTime),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TransportTile extends StatelessWidget {
  const _TransportTile({
    required this.iconAsset,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: SizedBox(
            height: 94,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xB5054CD1)
                    : const Color(0x351B3677),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? cyan.withValues(alpha: .75) : glassBorder,
                  width: selected ? 1.2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        iconAsset,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        semanticLabel: label,
                        errorBuilder: (_, __, ___) => Icon(
                          label == 'Moto'
                              ? Icons.two_wheeler
                              : label == 'Carro'
                                  ? Icons.directions_car_filled
                                  : Icons.local_shipping_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cyan : Colors.white.withValues(alpha: .45),
          width: 1.6,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? cyan : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({
    required this.km,
    required this.fare,
    required this.transportLabel,
    required this.rate,
    required this.fareRoundingCs,
    required this.usdRate,
  });

  final double? km;
  final double? fare;
  final String transportLabel;
  final VehicleRate? rate;
  final double fareRoundingCs;
  final double usdRate;

  @override
  Widget build(BuildContext context) {
    final distance = km;
    final price = fare;
    final rateValue = rate;
    final valid = distance != null && price != null && rateValue != null;
    final distanceValue = distance;
    final priceValue = price;
    final fareDescription = rateValue == null || distanceValue == null
        ? 'Selecciona ambos lugares para cotizar tu envío'
        : '${distanceValue.toStringAsFixed(1)} km · base '
            'C\$ ${rateValue.baseFeeCs.toStringAsFixed(0)} + '
            '${(distanceValue - rateValue.includedKm).clamp(0, double.infinity).toStringAsFixed(1)} adicionales × C\$ '
            '${rateValue.farePerKmCs.toStringAsFixed(2)} + '
            'C\$ ${logisticsServiceFeeCs.toStringAsFixed(0)} gestión';
    final priceLabel =
        priceValue == null ? 'C\$ —' : formatFareCs(priceValue, fareRoundingCs);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifa estimada · $transportLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fareDescription,
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10.5,
                        height: 1.35,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              if (valid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    Text(
                      '≈ US\$ ${(price / usdRate).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableRouteCard extends StatelessWidget {
  const _EditableRouteCard({
    required this.origin,
    required this.destination,
    required this.onOriginSelected,
    required this.onDestinationSelected,
  });

  final TextEditingController origin;
  final TextEditingController destination;
  final ValueChanged<PlaceSuggestion> onOriginSelected;
  final ValueChanged<PlaceSuggestion> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 15, 16, 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const _RouteMark(icon: Icons.radio_button_checked, size: 24),
                  SizedBox(
                    height: 34,
                    width: 2,
                    child: CustomPaint(
                      painter: _DottedLinePainter(
                          color: Colors.white.withValues(alpha: .40)),
                    ),
                  ),
                  const _RouteMark(icon: Icons.place_rounded, size: 24),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlaceAutocompleteField(
                      bare: true,
                      label: 'Desde',
                      hint: 'Mi ubicación actual',
                      controller: origin,
                      onSelected: onOriginSelected,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: CustomPaint(
                        painter: _DottedLinePainter(
                            color: Colors.white.withValues(alpha: .28),
                            horizontal: true),
                      ),
                    ),
                    PlaceAutocompleteField(
                      bare: true,
                      label: 'Hacia',
                      hint: 'Oficinas Incoex, Edificio Pellas',
                      controller: destination,
                      onSelected: onDestinationSelected,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteMark extends StatelessWidget {
  const _RouteMark({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: accentBlue,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: .55), width: 1.4),
          ),
          child: Icon(icon, color: Colors.white, size: size * .52),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color, this.horizontal = false});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    if (horizontal) {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, size.height / 2),
            Offset(x + dash, size.height / 2), paint);
        x += dash + gap;
      }
    } else {
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(
            Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
        y += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ReferencesCard extends StatelessWidget {
  const _ReferencesCard({
    required this.originController,
  });

  final TextEditingController originController;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 9),
                  const Text(
                    'Referencias:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: originController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontFamily: 'Figtree',
                ),
                decoration: const InputDecoration(
                  hintText: 'Ej. Casa verde frente al parque...',
                  hintStyle: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12.5,
                    fontFamily: 'Figtree',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  const _PriorityBar({required this.programado, required this.onChanged});

  final bool programado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              _option('Prioritario', !programado, () => onChanged(false)),
              _option('Programado', programado, () => onChanged(true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12.5),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentBlue.withValues(alpha: .38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.selectedDate,
    required this.selectedTime,
    required this.onPick,
  });

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final void Function(int dayIndex, String hour) onPick;

  String _fmt(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  int _dayIndex(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.isAfter(today) ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    final time = selectedTime;
    final hourLabel = time == null
        ? null
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final selectedDay = date == null ? null : _dayIndex(date);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: cyan, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Agenda tu envío',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                  if (date != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fmt(date)} · $hourLabel',
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Solo se permite programar dentro de las próximas 24 horas. Fechas pasadas quedan bloqueadas.',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 10.5,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (i, day) in _HomeTabState._dayOptions.indexed)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onPick(i, hourLabel ?? '09:00'),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedDay == i
                                ? accentBlue
                                : Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hour in _HomeTabState._hourOptions)
                    GestureDetector(
                      onTap: () => onPick(
                          _dayIndex(selectedDate ?? DateTime.now()), hour),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: hourLabel == hour
                              ? accentBlue
                              : Colors.white.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hourLabel == hour
                                ? cyan.withValues(alpha: .5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          hour,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
