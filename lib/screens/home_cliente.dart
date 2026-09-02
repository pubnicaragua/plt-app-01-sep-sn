import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/corte_banner.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import 'crear_envio1.dart';
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
      Pedido(),
      const ResumenCliente(),
      const MiPerfilCliente(),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
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
      bottomNavigationBar: AppNavBar(
        current: tab,
        onChanged: (index) => setState(() => tab = index),
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
    requestAppPermissions();
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

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.displayName ?? 'Mario Belfort'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const Text(
                    '¿Qué vas a enviar hoy?',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .16),
                border: Border.all(color: glassBorder),
              ),
              child: Center(
                child: Text(
                  initials(user?.displayName ?? 'Incoex'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D4DCC), Color(0xFF0034A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glassBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0034A6).withValues(alpha: .45),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envía hoy en Managua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crea tu envío en 3 pasos y mira el precio\nantes de confirmar.',
                      style: TextStyle(
                        color: Color(0xFFC9DCFF),
                        fontSize: 11.5,
                        height: 1.4,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .14),
                  border: Border.all(color: glassBorder),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _StepBanner(),
        const SizedBox(height: 22),
        const Text(
          'Selecciona el transporte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFamily: 'Acumin Pro',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TransportTile(
                icon: Icons.two_wheeler,
                label: 'Moto',
                eta: '15-30 min',
                badge: 'Más rápido',
                selected: transport == 'Moto',
                onTap: () => setState(() => transport = 'Moto'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _TransportTile(
                icon: Icons.directions_car_filled,
                label: 'Vehículo',
                eta: '1-2 hrs',
                badge: 'Versátil',
                selected: transport == 'Vehículo',
                onTap: () => setState(() => transport = 'Vehículo'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _TransportTile(
                icon: Icons.local_shipping_outlined,
                label: 'Camión',
                eta: '2-4 hrs',
                badge: 'Carga grande',
                selected: transport == 'Camión',
                onTap: () => setState(() => transport = 'Camión'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _EditableRouteCard(
          origin: origin,
          destination: destination,
          onOriginSelected: (place) => setState(() => originPlace = place),
          onDestinationSelected: (place) =>
              setState(() => destinationPlace = place),
        ),
        const SizedBox(height: 10),
        _FareCard(
          km: _km,
          fare: _fareFor(transport),
          transportLabel: transport,
          rate: settings?.rateFor(transport),
          usdRate: settings?.dollarRate ?? 36.5,
        ),
        const SizedBox(height: 10),
        _ReferencesCard(
          originController: refOrigin,
          destinationController: refDestination,
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 16),
        _PriorityBar(
          programado: programado,
          onChanged: (value) => setState(() => programado = value),
        ),
        const SizedBox(height: 18),
        GlassButton(
          label: 'Solicitar nuevo envío',
          filled: true,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CrearEnvio1(
                startOrigin: origin.text.trim(),
                startDestination: destination.text.trim(),
                startOriginPlace: originPlace,
                startDestinationPlace: destinationPlace,
                startTransport: transport,
                startOriginRefs: refOrigin.text.trim(),
                startDestinationRefs: refDestination.text.trim(),
                startRecipientName: recipientName.text.trim(),
                startRecipientPhone: recipientPhone.text.trim(),
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const Text(
                'Información del envío',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 10,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: .5,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .16),
              color: cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  const _TransportTile({
    required this.icon,
    required this.label,
    required this.eta,
    required this.badge,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String eta;
  final String badge;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(11, 12, 11, 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0D4DCC).withValues(alpha: .65)
              : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? figmaBlue : glassBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: .22)
                        : const Color(0xFF0D4DCC),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected
                      ? cyan
                      : Colors.white.withValues(alpha: .55),
                  size: 15,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              eta,
              style: const TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 10,
                fontFamily: 'Acumin Pro',
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: figmaBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ),
          ],
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
    final valid = distance != null && price != null && rate != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: valid
              ? [Color(0xFF0E5B3E), Color(0xFF07472F)]
              : [Color(0xFF101F45).withValues(alpha: .9), Color(0xFF0A1330)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: cyan, size: 22),
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
                  valid
                      ? '${distance.toStringAsFixed(1)} km · base '
                          'C\$ ${rate!.baseFeeCs.toStringAsFixed(0)} + '
                          '${distance.toStringAsFixed(1)} × C\$ '
                          '${rate!.farePerKmCs.toStringAsFixed(2)}'
                      : 'Selecciona ambos lugares para cotizar tu envío',
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
                  'C\$ ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESDE',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 7),
          PlaceAutocompleteField(
            label: 'Desde',
            hint: 'Busca un lugar de Managua…',
            icon: Icons.radio_button_checked,
            controller: origin,
            onSelected: onOriginSelected,
          ),
          const SizedBox(height: 15),
          const Text(
            'HACIA',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 7),
          PlaceAutocompleteField(
            label: 'Hacia',
            hint: 'Busca un lugar de Managua…',
            icon: Icons.place_rounded,
            controller: destination,
            onSelected: onDestinationSelected,
          ),
        ],
      ),
    );
  }
}

class _ReferencesCard extends StatelessWidget {
  const _ReferencesCard({
    required this.originController,
    required this.destinationController,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          GlassField(
            label: 'Referencia de la recogida',
            hint: 'Ej: portón azul después del semáforo',
            icon: Icons.edit_location_alt_outlined,
            controller: originController,
          ),
          const SizedBox(height: 10),
          GlassField(
            label: 'Referencia de la entrega',
            hint: 'Ej: recepción del tercer nivel',
            icon: Icons.edit_location_alt_outlined,
            controller: destinationController,
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          _option('Prioritario', !programado, () => onChanged(false)),
          _option('Programado', programado, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? figmaBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
      ),
    );
  }
}
