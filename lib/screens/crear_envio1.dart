import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import '../widgets/wizard.dart';
import 'crear_envio2.dart';

class CrearEnvio1 extends StatefulWidget {
  const CrearEnvio1({
    super.key,
    this.startOrigin = '',
    this.startDestination = '',
    this.startOriginPlace,
    this.startDestinationPlace,
    this.startTransport = 'Moto',
    this.startOriginRefs = '',
    this.startDestinationRefs = '',
    this.startRecipientName = '',
    this.startRecipientPhone = '',
  });

  final String startOrigin;
  final String startDestination;
  final PlaceSuggestion? startOriginPlace;
  final PlaceSuggestion? startDestinationPlace;
  final String startTransport;
  final String startOriginRefs;
  final String startDestinationRefs;
  final String startRecipientName;
  final String startRecipientPhone;

  @override
  State<CrearEnvio1> createState() => _CrearEnvio1State();
}

class _CrearEnvio1State extends State<CrearEnvio1> {
  int weight = 10;
  int bundles = 1;
  late String transport;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late PlaceSuggestion? originPlace;
  late PlaceSuggestion? destinationPlace;
  AppSettings? settings;

  @override
  void initState() {
    super.initState();
    transport = widget.startTransport;
    origin = TextEditingController(text: widget.startOrigin);
    destination = TextEditingController(text: widget.startDestination);
    originPlace = widget.startOriginPlace;
    destinationPlace = widget.startDestinationPlace;
    if (origin.text.isEmpty && widget.startOriginPlace == null) {
      requestCurrentLocation().then((location) {
        if (location != null) {
          originPlace = PlaceSuggestion(
            placeId: 'current',
            description: '${location.label}',
            main: location.label,
            secondary: 'Managua',
            latitude: location.latitude,
            longitude: location.longitude,
          );
          if (mounted) origin.text = location.label;
        }
      });
    }
    apiClient.getSettings().then((data) {
      if (mounted) setState(() => settings = data);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    super.dispose();
  }

  double? get _distanceKm {
    final from = originPlace;
    final to = destinationPlace;
    if (from == null || to == null) return null;
    if (from.latitude == null ||
        from.longitude == null ||
        to.latitude == null ||
        to.longitude == null) {
      return null;
    }
    return haversineKm(from.latitude!, from.longitude!, to.latitude!, to.longitude!);
  }

  String get _recommended {
    if (weight <= 20) return 'Moto';
    if (weight <= 200) return 'Vehículo';
    return 'Camión';
  }

  double? _priceFor(String vehicle) {
    final distance = _distanceKm;
    if (distance == null) return null;
    final rate = settings?.rateFor(vehicle);
    if (rate == null) return null;
    return rate.baseFeeCs + distance * rate.farePerKmCs;
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceKm;
    final price = _priceFor(transport);
    return WizardScaffold(
      title: 'Detalles de carga',
      subtitle: '¿Qué tipo de carga enviarás?',
      description:
          'Indica las características de tu carga y te recomendamos el transporte adecuado.',
      step: 0,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Peso y dimensiones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Paso 1',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Calcula el peso y dimensiones que necesitas',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundStep(
                      icon: Icons.remove,
                      onTap: weight > 1
                          ? () => setState(() => weight -= 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '$weight kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                    RoundStep(
                      icon: Icons.add,
                      onTap: () => setState(() => weight += 1),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const Text(
                  'Atajo:',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 9,
                  children: [
                    for (final value in [5, 10, 40, 405])
                      _weightChip(value),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cantidad de bultos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$bundles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundStep(
                      icon: Icons.remove,
                      onTap: bundles > 1
                          ? () => setState(() => bundles -= 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '$bundles bulto${bundles == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                    RoundStep(
                      icon: Icons.add,
                      onTap: () => setState(() => bundles += 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itinerario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 11),
                PlaceAutocompleteField(
                  label: 'Desde',
                  hint: 'Busca un lugar de Managua…',
                  icon: Icons.radio_button_checked,
                  controller: origin,
                  onSelected: (place) => setState(() {
                    originPlace = place;
                    destinationPlace = destinationPlace;
                  }),
                ),
                const SizedBox(height: 11),
                PlaceAutocompleteField(
                  label: 'Hacia',
                  hint: 'Busca un lugar de Managua…',
                  icon: Icons.location_on_outlined,
                  controller: destination,
                  onSelected: (place) => setState(() => destinationPlace = place),
                ),
                if (distance != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Ruta aproximada: ${distance.toStringAsFixed(1)} km en línea recta',
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transporte recomendado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: cyan, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'RECOMENDADO: ${_recommended}',
                            style: const TextStyle(
                              color: cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el transporte según tu tipo de carga. El precio se calcula con tu origen y destino.',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                for (final (label, cap, icon) in [
                  (
                    'Moto',
                    'Hasta 20 kg',
                    Icons.two_wheeler
                  ),
                  (
                    'Vehículo',
                    'Hasta 300 kg',
                    Icons.directions_car_filled
                  ),
                  (
                    'Camión',
                    'Hasta 1,500 kg',
                    Icons.local_shipping_outlined
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _VehicleRateTile(
                      icon: icon,
                      label: label,
                      capacity: cap,
                      subtitle: label == 'Moto'
                          ? 'Para cargas pequeñas y livianas'
                          : label == 'Vehículo'
                              ? 'Para cargas medianas'
                              : 'Para cargas grandes y pesadas',
                      price: _priceFor(label),
                      selected: transport == label,
                      recommended: _recommended == label,
                      onTap: () => setState(() => transport = label),
                    ),
                  ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  _PriceBreakdown(
                    transport: transport,
                    price: price,
                    recommended: _recommended == transport,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Confirmar envío',
            filled: true,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CrearEnvio2(
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  weight: weight,
                  bundles: bundles,
                  originPlace: originPlace,
                  destinationPlace: destinationPlace,
                  transport: transport,
                  originRefs: widget.startOriginRefs,
                  destinationRefs: widget.startDestinationRefs,
                  recipientName: widget.startRecipientName,
                  recipientPhone: widget.startRecipientPhone,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightChip(int value) {
    final active = weight == value;
    return GestureDetector(
      onTap: () => setState(() => weight = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? figmaBlue
              : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? cyan : Colors.transparent,
          ),
        ),
        child: Text(
          '$value kg',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Acumin Pro',
          ),
        ),
      ),
    );
  }
}

class _VehicleRateTile extends StatelessWidget {
  const _VehicleRateTile({
    required this.icon,
    required this.label,
    required this.capacity,
    required this.subtitle,
    required this.selected,
    required this.recommended,
    required this.onTap,
    this.price,
  });

  final IconData icon;
  final String label;
  final String capacity;
  final String subtitle;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;
  final double? price;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .14)
              : Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? cyan : glassBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? figmaBlue
                    : Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: mint.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'RECOMENDADO',
                            style: TextStyle(
                              color: mint,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 10,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  Text(
                    'Capacidad: $capacity',
                    style: const TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 10,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ENVÍO DESDE',
                  style: TextStyle(
                    color: Color(0xFF8FA0C4),
                    fontSize: 8,
                    letterSpacing: .6,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price == null
                      ? 'C\$ —'
                      : 'C\$${price!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 9),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? cyan : Colors.white38,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.transport,
    required this.price,
    required this.recommended,
  });

  final String transport;
  final double price;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL A COBRAR AL DESTINATARIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transport,
                  style: const TextStyle(
                    color: mint,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'C\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 6),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: mint, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Tarifa calculada al instante',
                    style: TextStyle(
                      color: mint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                'Tarifa calculada con el transporte seleccionado',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 10.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: glassBorder, height: 1),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Tarifa base de envío',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Text(
                'Incluida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Costo por kilómetro de la ruta',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Text(
                'Incluido',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          const Row(
            children: [
              Expanded(
                child: Text(
                  '+ Paquete del cliente (valor)',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Text(
                'C\$ 450',
                style: TextStyle(
                  color: mint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: glassBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Envío C\$${(price * 0.20).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA0C4),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Total a pagar por el cliente\nC\$${(price + 450).toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}