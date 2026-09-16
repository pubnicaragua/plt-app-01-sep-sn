import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/corte_banner.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import 'inicio.dart';
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

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[
      const _HomeTab(),
      const MisEnvios(embedded: true),
      const ResumenCliente(embedded: true),
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
                padding: EdgeInsets.only(bottom: 110 + safeBottom),
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
                onChanged: (index) => setState(() => tab = index),
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
    return rate.baseFeeCs + km * rate.farePerKmCs;
  }

  static const _dayOptions = ['Hoy', 'Mañana'];
  static const _hourOptions = ['09:00', '12:00', '15:00', '18:00'];

  DateTime _slot(int dayIndex, String hour) {
    final now = DateTime.now();
    final parts = hour.split(':');
    final base = DateTime(now.year, now.month, now.day)
        .add(Duration(days: dayIndex));
    return DateTime(
        base.year, base.month, base.day,
        int.parse(parts[0]), int.parse(parts[1]));
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
            style: TextStyle(fontFamily: 'Acumin Pro'),
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
            style: TextStyle(fontFamily: 'Acumin Pro'),
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

  void _autoAgenda() {
    final now = DateTime.now().add(const Duration(minutes: 30));
    final today = DateTime(now.year, now.month, now.day);
    for (final hour in _hourOptions) {
      final parts = hour.split(':');
      final candidate = DateTime(today.year, today.month, today.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (candidate.isAfter(now)) {
        setState(() {
          agendaDate = candidate;
          agendaTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        });
        return;
      }
    }
    agendaDate = today.add(const Duration(days: 1));
    agendaTime = const TimeOfDay(hour: 9, minute: 0);
  }

  String? get _agendaDateString {
    final date = agendaDate;
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? get _agendaTimeString {
    final time = agendaTime;
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    final apiName = user?.displayName.trim() ?? '';
    final displayName = apiName.isEmpty || apiName.toLowerCase() == 'logística nica sa'
        ? 'Mario Belfort'
        : apiName;
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
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const Text(
                    '¿Qué vas a enviar hoy?',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .25)),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle)),
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
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _StepBanner(),
        const SizedBox(height: 24),
        const Text(
          'Selecciona el transporte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontFamily: 'Acumin Pro',
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
          onPressed: () => Navigator.of(context).push(
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
                startDate: _agendaDateString,
                startTime: _agendaTimeString,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paso 1 de 2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const Text(
                    'Información del envío',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 10.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: .5,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: .18),
                  color: cyan,
                ),
              ),
            ],
          ),
        ),
      ),
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
                      fontFamily: 'Acumin Pro',
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
    required this.usdRate,
  });

  final double? km;
  final double? fare;
  final String transportLabel;
  final VehicleRate? rate;
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
            '${distanceValue.toStringAsFixed(1)} × C\$ '
            '${rateValue.farePerKmCs.toStringAsFixed(2)}';
    final priceLabel = priceValue == null
        ? 'C\$ —'
        : 'C\$ ${priceValue.toStringAsFixed(2)}';
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
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fareDescription,
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10.5,
                        height: 1.35,
                        fontFamily: 'Acumin Pro',
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
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    Text(
                      '≈ US\$ ${(price / usdRate).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10,
                        fontFamily: 'Acumin Pro',
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
            border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.4),
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
        canvas.drawLine(Offset(size.width / 2, y),
            Offset(size.width / 2, y + dash), paint);
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
                  const Icon(Icons.notes_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 9),
                  const Text(
                    'Referencias:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
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
                  fontFamily: 'Acumin Pro',
                ),
                decoration: const InputDecoration(
                  hintText: 'Ej. Casa verde frente al parque...',
                  hintStyle: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12.5,
                    fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
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
                        fontFamily: 'Acumin Pro',
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
                          fontFamily: 'Acumin Pro',
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
                  fontFamily: 'Acumin Pro',
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
                              fontFamily: 'Acumin Pro',
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
                      onTap: () => onPick(_dayIndex(selectedDate ?? DateTime.now()), hour),
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
                            fontFamily: 'Acumin Pro',
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
