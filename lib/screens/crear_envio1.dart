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
  const CrearEnvio1({super.key});

  @override
  State<CrearEnvio1> createState() => _CrearEnvio1State();
}

class _CrearEnvio1State extends State<CrearEnvio1> {
  int weight = 10;
  int bundles = 1;
  String transport = 'Vehículo';
  final origin = TextEditingController();
  final destination = TextEditingController();
  PlaceSuggestion? originPlace;
  PlaceSuggestion? destinationPlace;
  AppSettings? settings;

  @override
  void initState() {
    super.initState();
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
                const Text(
                  'Transporte sugerido',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (final (label, sub) in [
                      ('Moto', '15–30 min · ligera'),
                      ('Vehículo', '1–2 horas'),
                      ('Camión', '2–4 horas'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TransportPriceLine(
                          label: label,
                          sub: sub,
                          selected: transport == label,
                          price: _priceFor(label),
                          onTap: () => setState(() => transport = label),
                        ),
                      ),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          figmaBlue.withValues(alpha: .45),
                          figmaBlue.withValues(alpha: .20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: cyan.withValues(alpha: .5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: cyan, size: 22),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Precio estimado',
                                style: TextStyle(
                                  color: Color(0xFFB9D4FF),
                                  fontSize: 10.5,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                              Text(
                                '${transport} · ${distance!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'C\$${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Continuar',
            filled: true,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CrearEnvio2(
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  weight: weight,
                  bundles: bundles,
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

class _TransportPriceLine extends StatelessWidget {
  const _TransportPriceLine({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.price,
  });

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  final double? price;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? figmaBlue.withValues(alpha: .40)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? cyan : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              label == 'Moto'
                  ? Icons.two_wheeler
                  : label == 'Camión'
                      ? Icons.local_shipping_outlined
                      : Icons.directions_car_filled,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 10.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            if (price != null)
              Text(
                'C\$${price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: mint,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? cyan : Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}