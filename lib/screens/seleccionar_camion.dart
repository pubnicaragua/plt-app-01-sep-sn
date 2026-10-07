import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'crear_envio_carga.dart';

class SeleccionarCamionScreen extends StatefulWidget {
  const SeleccionarCamionScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
    required this.transport,
    this.estimatedShipping,
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final double? estimatedShipping;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;

  @override
  State<SeleccionarCamionScreen> createState() =>
      _SeleccionarCamionScreenState();
}

class _SeleccionarCamionScreenState extends State<SeleccionarCamionScreen> {
  static const truckTypes = [
    _TruckOption(
      label: 'Camión pequeño',
      badge: 'Ideal para mudanzas',
      asset: 'assets/img/HomeCliente/carga_extra_pequeno.png',
      capacity: 'Hasta 2000 kg',
      volume: '18 m³ de capacidad',
      description: 'Ideal para mudanzas y cargas pequeñas.',
    ),
    _TruckOption(
      label: 'Camión mediano',
      badge: 'Ideal para productos grandes',
      asset: 'assets/img/HomeCliente/carga_mediano.png',
      capacity: 'Hasta 5500 kg',
      volume: '18 m³ de capacidad',
      description: 'Para muebles, electrodomésticos y cargas medianas.',
    ),
    _TruckOption(
      label: 'Camión grande',
      badge: 'Ideal para transportar mercancía',
      asset: 'assets/img/HomeCliente/carga_grande.png',
      capacity: 'Hasta 7500 kg',
      volume: '18 m³ de capacidad',
      description: 'Para mercancía voluminosa y cargas pesadas.',
    ),
  ];

  static const bodyTypes = [
    _TruckFeature(
      label: 'Cerrado',
      asset: 'assets/img/HomeCliente/carga_carroceria_cerrado.png',
    ),
    _TruckFeature(
      label: 'Plataforma',
      asset: 'assets/img/HomeCliente/carga_carroceria_plataforma.png',
    ),
    _TruckFeature(
      label: 'Baranda',
      asset: 'assets/img/HomeCliente/carga_carroceria_baranda.png',
    ),
    _TruckFeature(
      label: 'Refrigerado',
      asset: 'assets/img/HomeCliente/carga_carroceria_refrigerado.png',
    ),
  ];

  static const equipmentTypes = [
    _TruckFeature(
      label: 'Rampa',
      asset: 'assets/img/HomeCliente/carga_equipo_rampa.png',
    ),
    _TruckFeature(
      label: 'Elevador',
      asset: 'assets/img/HomeCliente/carga_equipo_elevador.png',
    ),
  ];

  int selectedTruck = 0;
  String selectedBody = 'Cerrado';
  String selectedEquipment = 'Rampa';

  _TruckOption get currentTruck => truckTypes[selectedTruck];

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearEnvioCarga(
          origin: widget.origin,
          destination: widget.destination,
          originPlace: widget.originPlace,
          destinationPlace: widget.destinationPlace,
          transport: widget.transport,
          estimatedShipping: widget.estimatedShipping,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          startScheduled: widget.startScheduled,
          startDate: widget.startDate,
          startTime: widget.startTime,
          truckType: currentTruck.label,
          truckAsset: currentTruck.asset,
          bodyType: selectedBody,
          equipment: selectedEquipment,
        ),
      ),
    );
  }

  void _showTruckDetails(_TruckOption truck) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102A68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(truck.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              const SizedBox(height: 6),
              Text(truck.description,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Figtree')),
              const SizedBox(height: 12),
              Text('${truck.capacity} · ${truck.volume}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                  children: [
                    _TruckHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 12),
                    const _TruckSectionTitle(
                      icon:
                          'assets/img/HomeCliente/carga_carroceria_cerrado.png',
                      title: 'Selecciona tu camión',
                      subtitle: 'Según las características de tu carga.',
                    ),
                    const SizedBox(height: 10),
                    _SelectedTruckCard(
                      truck: currentTruck,
                      onDetails: () => _showTruckDetails(currentTruck),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < truckTypes.length;
                              index++) ...[
                            Expanded(
                              child: _TruckMiniCard(
                                truck: truckTypes[index],
                                selected: index == selectedTruck,
                                onTap: () =>
                                    setState(() => selectedTruck = index),
                              ),
                            ),
                            if (index != truckTypes.length - 1)
                              const SizedBox(width: 7),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _TruckSectionTitle(
                      icon:
                          'assets/img/HomeCliente/carga_carroceria_cerrado.png',
                      title: 'Tipo de carrocería',
                      subtitle:
                          'Selecciona el tipo de camión que mejor se adapte a tu carga.',
                    ),
                    const SizedBox(height: 8),
                    _TruckFeatureRow(
                      options: bodyTypes,
                      selected: selectedBody,
                      onChanged: (value) =>
                          setState(() => selectedBody = value),
                    ),
                    const SizedBox(height: 14),
                    const _TruckSectionTitle(
                      icon: 'assets/img/HomeCliente/carga_equipo_rampa.png',
                      title: 'Equipamiento especial (opcional)',
                      subtitle: '¿Necesitas algún equipamiento adicional?',
                    ),
                    const SizedBox(height: 8),
                    _TruckFeatureRow(
                      options: equipmentTypes,
                      selected: selectedEquipment,
                      onChanged: (value) =>
                          setState(() => selectedEquipment = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: GlassButton(
                  label: 'Siguiente',
                  filled: true,
                  height: 48,
                  fontSize: 13,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruckOption {
  const _TruckOption({
    required this.label,
    required this.badge,
    required this.asset,
    required this.capacity,
    required this.volume,
    required this.description,
  });

  final String label;
  final String badge;
  final String asset;
  final String capacity;
  final String volume;
  final String description;
}

class _TruckFeature {
  const _TruckFeature({required this.label, required this.asset});

  final String label;
  final String asset;
}

class _TruckHeader extends StatelessWidget {
  const _TruckHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 5),
          const Expanded(
            child: Text('Camiones',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: const Text('Paso 1',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ),
        ],
      );
}

class _TruckSectionTitle extends StatelessWidget {
  const _TruckSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(icon, width: 21, height: 21, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      );
}

class _SelectedTruckCard extends StatelessWidget {
  const _SelectedTruckCard({required this.truck, required this.onDetails});

  final _TruckOption truck;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 18,
        selected: true,
        fillColor: const Color(0x3A0A2C73),
        child: SizedBox(
          height: 318,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(truck.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ),
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(truck.badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontFamily: 'Figtree')),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Image.asset(
                  truck.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white54,
                    size: 86,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 7),
                child: AppGlassSurface(
                  borderRadius: 17,
                  fillColor: const Color(0x3A0A2C73),
                  child: SizedBox(
                    height: 96,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 9, 9, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _Metric(
                                      text: truck.capacity,
                                      fontSize: 10,
                                      iconSize: 16,
                                      asset:
                                          'assets/img/HomeCliente/envio_weight.png')),
                              Expanded(
                                  child: _Metric(
                                      text: truck.volume,
                                      fontSize: 10,
                                      iconSize: 16,
                                      asset:
                                          'assets/img/HomeCliente/envio_package.png')),
                            ],
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white.withValues(alpha: .18),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Image.asset(
                                    'assets/img/HomeCliente/carga_precio_cotizacion.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(
                                          Icons.attach_money_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        )),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Precio por cotización',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Figtree')),
                                      SizedBox(height: 1),
                                      Text(
                                          'El precio se confirmará según tu ruta, tipo de carga y disponibilidad.',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 7.5,
                                              fontFamily: 'Figtree')),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: onDetails,
                                  style: TextButton.styleFrom(
                                    backgroundColor: accentBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    minimumSize: const Size(0, 28),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const StadiumBorder(),
                                  ),
                                  icon: const SizedBox.shrink(),
                                  label: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Ver detalles',
                                          style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Figtree')),
                                      SizedBox(width: 3),
                                      Icon(Icons.chevron_right_rounded,
                                          size: 13),
                                    ],
                                  ),
                                ),
                              ],
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
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.text,
    this.asset,
    this.fontSize = 8,
    this.iconSize = 14,
  });

  final String text;
  final String? asset;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (asset != null)
            Image.asset(asset!,
                width: iconSize, height: iconSize, fit: BoxFit.contain)
          else
            Icon(Icons.inventory_2_outlined,
                color: Colors.white, size: iconSize),
          SizedBox(width: iconSize == 14 ? 5 : 6),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: fontSize,
                    fontFamily: 'Figtree')),
          ),
        ],
      );
}

class _TruckMiniCard extends StatelessWidget {
  const _TruckMiniCard({
    required this.truck,
    required this.selected,
    required this.onTap,
  });

  final _TruckOption truck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 11,
          selected: selected,
          child: SizedBox(
            height: 180,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            truck.asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white54,
                              size: 34,
                            ),
                          ),
                        ),
                        Text(truck.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Figtree')),
                        const SizedBox(height: 2),
                        Text(truck.badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 6.5,
                                fontFamily: 'Figtree')),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AppGlassSurface(
                    borderRadius: 10,
                    selected: selected,
                    fillColor: const Color(0x3A0A2C73),
                    child: SizedBox(
                      height: 54,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                        child: Column(
                          children: [
                            Expanded(
                              child: _Metric(
                                  text: truck.capacity,
                                  fontSize: 6.5,
                                  iconSize: 11,
                                  asset:
                                      'assets/img/HomeCliente/envio_weight.png'),
                            ),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: .14),
                            ),
                            Expanded(
                              child: _Metric(
                                  text: truck.volume,
                                  fontSize: 6.5,
                                  iconSize: 11,
                                  asset:
                                      'assets/img/HomeCliente/envio_package.png'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: FractionallySizedBox(
                    widthFactor: .78,
                    child: SizedBox(
                      height: 21,
                      child: TextButton.icon(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                        ),
                        icon: const SizedBox.shrink(),
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ver detalles',
                                style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree')),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TruckFeatureRow extends StatelessWidget {
  const _TruckFeatureRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<_TruckFeature> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 62,
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(options[index].label),
                  child: AppGlassSurface(
                    borderRadius: 10,
                    selected: options[index].label == selected,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: options[index].label == selected ? 1 : .68,
                          child: Image.asset(options[index].asset,
                              width: 23, height: 23, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 4),
                        Text(options[index].label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Figtree')),
                      ],
                    ),
                  ),
                ),
              ),
              if (index != options.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      );
}
