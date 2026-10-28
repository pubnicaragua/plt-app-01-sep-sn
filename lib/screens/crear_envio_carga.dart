import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../core/truck_capacity.dart';
import '../core/vehicle_capacity.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'crear_envio2.dart';

bool shouldShowProductPaymentMethod(String status) =>
    status.trim().toLowerCase() == 'pendiente';

String productPaymentStatusForSelection(bool paid) =>
    paid ? 'Pagado' : 'Pendiente';

int? parseBundleCount(String value) {
  final parsed = int.tryParse(value.trim());
  return parsed != null && parsed > 0 ? parsed : null;
}

class CrearEnvioCarga extends StatefulWidget {
  const CrearEnvioCarga({
    super.key,
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
    required this.transport,
    this.estimatedShipping,
    this.distanceKm,
    this.vehicleRates = const {},
    this.fareRoundingCs = 5,
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
    this.truckType,
    this.truckAsset,
    this.truckCapacityKg,
    this.bodyType,
    this.equipment,
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final double? estimatedShipping;
  final double? distanceKm;
  final Map<String, VehicleRate> vehicleRates;
  final double fareRoundingCs;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;
  final String? truckType;
  final String? truckAsset;
  final double? truckCapacityKg;
  final String? bodyType;
  final String? equipment;

  @override
  State<CrearEnvioCarga> createState() => _CrearEnvioCargaState();
}

class _CrearEnvioCargaState extends State<CrearEnvioCarga> {
  final picker = ImagePicker();
  final photos = <Uint8List>[];
  String packageType = '';
  int weight = 2;
  bool fragile = false;
  late final TextEditingController packageTypeController;
  late final TextEditingController weightController;
  late final TextEditingController invoicePriceController;
  late final TextEditingController invoiceNumberController;
  late final TextEditingController bundlesController;
  String currency = 'C\$';
  String productPaymentStatus = 'Pendiente';
  String productPaymentMethod = 'Efectivo';
  bool isForSale = true;
  late String transport;
  late String? truckType;
  late String? truckAsset;
  late double? truckCapacityKg;
  String weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    packageTypeController = TextEditingController();
    weightController = TextEditingController(text: '$weight');
    invoicePriceController = TextEditingController();
    invoiceNumberController = TextEditingController();
    bundlesController = TextEditingController(text: '1');
    transport = widget.transport;
    truckType = widget.truckType;
    truckAsset = widget.truckAsset;
    truckCapacityKg = widget.truckCapacityKg ??
        truckMaxWeightKgForLabel(widget.truckType ?? '');
  }

  @override
  void dispose() {
    packageTypeController.dispose();
    weightController.dispose();
    invoicePriceController.dispose();
    invoiceNumberController.dispose();
    bundlesController.dispose();
    super.dispose();
  }

  bool get isTruck => transport == 'Camión';
  bool get isPickup => transport == 'Pickup';
  bool get isVan => transport == 'VAN';

  String get vehicleLabel => isTruck
      ? truckType ?? 'Camión'
      : transport == 'Moto'
          ? 'Moto'
          : isPickup
              ? 'Pickup'
              : isVan
                  ? 'VAN'
                  : 'Vehículo';

  String _assetForTransport(String value) {
    switch (value) {
      case 'Camión':
        return 'assets/img/HomeCliente/figma_carga.png';
      case 'Moto':
        return 'assets/img/HomeCliente/figma_moto.png';
      case 'Pickup':
        return 'assets/img/HomeCliente/figma_pickup.png';
      case 'VAN':
        return 'assets/img/HomeCliente/figma_van.png';
      default:
        return 'assets/img/HomeCliente/figma_auto.png';
    }
  }

  String get vehicleAsset => isTruck && truckType != null
      ? (truckAsset ?? truckAssetForLabel(truckType!))
      : _assetForTransport(transport);

  void _setWeightUnit(String nextUnit) {
    if (nextUnit == weightUnit) return;
    final current = double.tryParse(weightController.text.trim());
    if (current != null && current > 0) {
      final currentKg = weightToKg(current, weightUnit);
      final converted = nextUnit == 'lb' ? currentKg * 2.20462 : currentKg;
      final rounded = converted.round().clamp(1, 3307).toInt();
      weightController.value = TextEditingValue(
        text: '$rounded',
        selection: TextSelection.collapsed(offset: '$rounded'.length),
      );
      weight = rounded;
    }
    setState(() => weightUnit = nextUnit);
  }

  double? get _distanceForPricing =>
      widget.distanceKm ??
      distanceKm(widget.originPlace, widget.destinationPlace);

  Map<String, double?> _estimatedFaresFor(List<String> vehicles) {
    final distance = _distanceForPricing;
    if (distance == null) return const {};
    return {
      for (final vehicle in vehicles)
        vehicle: estimatedShippingForVehicle(
          vehicle: vehicle,
          distanceKm: distance,
          configuredRates: widget.vehicleRates,
          fareRoundingCs: widget.fareRoundingCs,
        ),
    };
  }

  Future<void> _pickPhotos() async {
    final selected =
        await picker.pickMultiImage(imageQuality: 84, maxWidth: 1400);
    if (!mounted || selected.isEmpty) return;
    final remaining = 5 - photos.length;
    final bytes = <Uint8List>[];
    for (final file in selected.take(remaining)) {
      bytes.add(await file.readAsBytes());
    }
    if (mounted) setState(() => photos.addAll(bytes));
  }

  Future<bool> _validateWeightCapacity() async {
    final value = double.tryParse(weightController.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso válido.')),
      );
      return false;
    }
    weight = value.round();
    final weightKg = weightToKg(value, weightUnit);
    final maximum = isTruck
        ? (truckCapacityKg ?? double.infinity)
        : maxWeightKgForVehicle(transport);
    if (weightKg <= maximum) return true;

    final vehicleRecommendation = recommendedVehicleForWeight(weightKg);
    final truckRecommendation = recommendedTruckForWeight(weightKg);
    final recommendation = isTruck
        ? truckRecommendation
        : vehicleRecommendation ?? truckRecommendation;
    final recommendationIsTruck = isTruck ||
        (vehicleRecommendation == null && truckRecommendation != null);
    if (!mounted) return false;
    final currentVehicleLabel = isTruck ? (truckType ?? 'Camión') : transport;
    final compatibleVehicles = recommendationIsTruck
        ? compatibleTrucksForWeight(weightKg)
        : compatibleVehiclesForWeight(weightKg);
    final estimatedFares = recommendationIsTruck
        ? const <String, double?>{}
        : _estimatedFaresFor(compatibleVehicles);
    if (recommendation == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => _WeightLimitDialog(
          vehicle: currentVehicleLabel,
          enteredWeight: value,
          weightUnit: weightUnit,
          recommendation: null,
          recommendedAsset: null,
          compatibleVehicles: compatibleVehicles,
          assetForVehicle:
              recommendationIsTruck ? truckAssetForLabel : _assetForTransport,
          estimatedFares: estimatedFares,
        ),
      );
      return false;
    }
    final selectedVehicle = await showDialog<String>(
      context: context,
      builder: (context) => _WeightLimitDialog(
        vehicle: currentVehicleLabel,
        enteredWeight: value,
        weightUnit: weightUnit,
        recommendation: recommendation,
        recommendedAsset: recommendationIsTruck
            ? truckAssetForLabel(recommendation)
            : _assetForTransport(recommendation),
        compatibleVehicles: compatibleVehicles,
        assetForVehicle:
            recommendationIsTruck ? truckAssetForLabel : _assetForTransport,
        estimatedFares: estimatedFares,
        recommendationActionLabel:
            recommendationIsTruck ? 'Programar $recommendation' : null,
      ),
    );
    if (selectedVehicle == null || !mounted) return false;
    if (recommendationIsTruck) {
      setState(() {
        transport = 'Camión';
        truckType = selectedVehicle;
        truckAsset = truckAssetForLabel(selectedVehicle);
        truckCapacityKg = truckMaxWeightKgForLabel(selectedVehicle);
      });
    } else {
      setState(() => transport = selectedVehicle);
    }
    return false;
  }

  Future<void> _continue() async {
    if (!await _validateWeightCapacity()) return;
    if (!mounted) return;
    final bundles = parseBundleCount(bundlesController.text);
    if (bundles == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad válida de bultos.'),
        ),
      );
      return;
    }
    if (packageTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el tipo de paquete para continuar.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearEnvio2(
          origin: widget.origin,
          destination: widget.destination,
          originPlace: widget.originPlace,
          destinationPlace: widget.destinationPlace,
          transport: transport,
          estimatedShipping:
              transport == widget.transport ? widget.estimatedShipping : null,
          weight: weight,
          weightUnit: weightUnit,
          bundles: bundles,
          packageType: packageTypeController.text.trim(),
          initialProductPhotos: List<Uint8List>.of(photos),
          initialFragile: fragile,
          initialInvoicePrice: invoicePriceController.text.trim(),
          initialInvoiceCurrency: currency,
          initialInvoiceNumber: invoiceNumberController.text.trim(),
          initialProductPaymentStatus: productPaymentStatus,
          initialProductPaymentMethod: productPaymentMethod,
          initialIsProductSale: isForSale,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          startScheduled: widget.startScheduled,
          startDate: widget.startDate,
          startTime: widget.startTime,
          initialTruckType: truckType,
          initialTruckBodyType: widget.bodyType,
          initialTruckEquipment: widget.equipment,
        ),
      ),
    );
  }

  void _changeBundles(int delta) {
    final current = parseBundleCount(bundlesController.text) ?? 1;
    final next = current + delta;
    setState(() {
      bundlesController.text = (next < 1 ? 1 : next).toString();
      bundlesController.selection = TextSelection.fromPosition(
        TextPosition(offset: bundlesController.text.length),
      );
    });
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    _CargaHeader(
                      title: 'Envíos',
                      onBack: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                    _ShippingVehicleCard(
                      label: vehicleLabel,
                      asset: vehicleAsset,
                    ),
                    const SizedBox(height: 16),
                    const _CargaSectionTitle(
                      icon: 'assets/img/HomeCliente/envio_package.png',
                      title: '¿Qué vamos a transportar?',
                      subtitle:
                          'Esta información nos ayudará a preparar correctamente el recojo y despacho',
                    ),
                    const SizedBox(height: 10),
                    _CargaField(
                      icon: 'assets/img/HomeCliente/envio_package.png',
                      label: 'Tipo de paquete',
                      value: '',
                      content: TextField(
                        controller: packageTypeController,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontFamily: 'Figtree'),
                        decoration: const InputDecoration(
                          hintText: 'Escribe qué vas a transportar',
                          hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Figtree'),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => packageType = value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _productDetailsBlock(),
                    const SizedBox(height: 16),
                    const _CargaSectionTitle(
                      icon: 'assets/img/HomeCliente/envio_photo.png',
                      title: 'Fotos del paquete',
                      subtitle:
                          'Ayúdanos a verificar el espacio y la manipulación',
                    ),
                    const SizedBox(height: 10),
                    _PhotoUploadBox(
                      photos: photos,
                      onTap: _pickPhotos,
                    ),
                    const SizedBox(height: 14),
                    _FragileRow(
                      value: fragile,
                      onChanged: (value) => setState(() => fragile = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassButton(
                  label: 'Siguiente',
                  filled: true,
                  height: 48,
                  fontSize: 14,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceBlock() {
    final showPaymentMethod =
        shouldShowProductPaymentMethod(productPaymentStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estado del producto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            SizedBox(
              width: 132,
              child: _InvoiceSegment(
                options: const ['Pagado', 'Pendiente'],
                value: productPaymentStatus,
                onChanged: (value) => setState(() {
                  productPaymentStatus = value;
                  if (value == 'Pagado') productPaymentMethod = '';
                  if (value == 'Pendiente' && productPaymentMethod.isEmpty) {
                    productPaymentMethod = 'Efectivo';
                  }
                }),
              ),
            ),
          ],
        ),
        if (showPaymentMethod) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Método de pago',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              SizedBox(
                width: 150,
                child: _InvoiceSegment(
                  options: const ['Efectivo', 'Transferencia'],
                  value: productPaymentMethod,
                  onChanged: (value) =>
                      setState(() => productPaymentMethod = value),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        _InvoiceInputField(
          controller: invoiceNumberController,
          hint: 'Número de factura',
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InvoiceInputField(
                controller: invoicePriceController,
                hint: 'Precio de factura',
                icon: Icons.sell_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: _InvoiceSegment(
                options: const ['C\$', 'USD'],
                value: currency,
                onChanged: (value) => setState(() => currency = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _productDetailsBlock() {
    final isPaid = productPaymentStatus == 'Pagado';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CargaChoiceCard(
          iconAsset: 'assets/img/HomeCliente/icono_venta.png',
          title: '¿Este envío corresponde a una venta?',
          subtitle:
              'Indica si este envío tiene un producto asociado a una venta',
          options: const ['Sí', 'No'],
          value: isForSale ? 'Sí' : 'No',
          onChanged: (value) => setState(() => isForSale = value == 'Sí'),
        ),
        const SizedBox(height: 9),
        if (isForSale) ...[
          _CargaChoiceCard(
            iconAsset: 'assets/img/HomeCliente/icono_dinero.png',
            title: '¿El producto ya está pagado?',
            subtitle: 'Indica el estado de pago del producto',
            options: const ['Sí', 'No'],
            value: isPaid ? 'Sí' : 'No',
            onChanged: (value) => setState(() {
              productPaymentStatus =
                  productPaymentStatusForSelection(value == 'Sí');
              productPaymentMethod = value == 'Sí' ? '' : 'Efectivo';
            }),
          ),
          const SizedBox(height: 9),
          if (!isPaid)
            _CargaChoiceCard(
              iconAsset: 'assets/img/HomeCliente/icono_dinero.png',
              title: 'Método de pago',
              subtitle: 'Selecciona cómo se pagará el producto',
              options: const ['Efectivo', 'Transferencia', 'Tarjeta'],
              value: productPaymentMethod,
              onChanged: (value) =>
                  setState(() => productPaymentMethod = value),
            ),
          const SizedBox(height: 9),
        ],
        _ProductValueCard(
          controller: invoicePriceController,
          bundlesController: bundlesController,
          title: isForSale
              ? 'Ingrese el total de factura'
              : 'Valor aproximado del producto',
          currency: currency,
          onCurrencyChanged: (value) => setState(() => currency = value),
          onDecreaseBundles: () => _changeBundles(-1),
          onIncreaseBundles: () => _changeBundles(1),
        ),
        const SizedBox(height: 9),
        _WeightInputCard(
          controller: weightController,
          unit: weightUnit,
          onUnitChanged: _setWeightUnit,
          onChanged: (value) {
            final parsed = double.tryParse(value.trim());
            if (parsed != null && parsed > 0) weight = parsed.round();
          },
        ),
      ],
    );
  }
}

class _WeightInputCard extends StatelessWidget {
  const _WeightInputCard({
    required this.controller,
    required this.unit,
    required this.onChanged,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            const Icon(Icons.scale_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peso del producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ingresa el peso aproximado en ${unit == 'lb' ? 'libras' : 'kilogramos'}',
                    style: const TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 9,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 72,
                  height: 32,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                    decoration: InputDecoration(
                      suffixText: unit,
                      suffixStyle: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10,
                        fontFamily: 'Figtree',
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: .12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: accentBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _WeightUnitToggle(unit: unit, onChanged: onUnitChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightUnitToggle extends StatelessWidget {
  const _WeightUnitToggle({required this.unit, required this.onChanged});

  final String unit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WeightUnitOption(
            label: 'kg',
            selected: unit == 'kg',
            onTap: () => onChanged('kg'),
          ),
          _WeightUnitOption(
            label: 'lb',
            selected: unit == 'lb',
            onTap: () => onChanged('lb'),
          ),
        ],
      ),
    );
  }
}

class _WeightUnitOption extends StatelessWidget {
  const _WeightUnitOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFB9D4FF),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _WeightLimitDialog extends StatelessWidget {
  const _WeightLimitDialog({
    required this.vehicle,
    required this.enteredWeight,
    required this.weightUnit,
    required this.recommendation,
    required this.recommendedAsset,
    required this.compatibleVehicles,
    required this.assetForVehicle,
    required this.estimatedFares,
    this.recommendationActionLabel,
  });

  final String vehicle;
  final double enteredWeight;
  final String weightUnit;
  final String? recommendation;
  final String? recommendedAsset;
  final List<String> compatibleVehicles;
  final String Function(String) assetForVehicle;
  final Map<String, double?> estimatedFares;
  final String? recommendationActionLabel;

  @override
  Widget build(BuildContext context) {
    final hasRecommendation = recommendation != null;
    final enteredWeightLabel =
        '${enteredWeight.toStringAsFixed(0)} ${weightUnit == 'lb' ? 'lb' : 'kg'}';
    return AlertDialog(
      backgroundColor: const Color(0xFF10285D),
      title: const Text(
        'Peso no compatible',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .58,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRecommendation && recommendedAsset != null)
                _RecommendedVehicleOption(
                  vehicle: recommendation!,
                  asset: recommendedAsset!,
                  estimatedFare: estimatedFares[recommendation],
                  onTap: () => Navigator.pop(context, recommendation),
                ),
              const SizedBox(height: 10),
              Text(
                hasRecommendation
                    ? 'El producto pesa $enteredWeightLabel y no se puede llevar en $vehicle.'
                    : 'El producto pesa $enteredWeightLabel y supera la capacidad de las opciones disponibles. Contacta con Incoex para programar una unidad que soporte esta carga.',
                style: const TextStyle(
                  color: Color(0xFFE5EDFF),
                  fontFamily: 'Figtree',
                ),
              ),
              if (compatibleVehicles.length > 1) ...[
                const SizedBox(height: 14),
                const Text(
                  'También compatibles',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 8),
                ...compatibleVehicles.skip(1).map(
                      (compatibleVehicle) => _CompatibleVehicleOption(
                        vehicle: compatibleVehicle,
                        asset: assetForVehicle(compatibleVehicle),
                        estimatedFare: estimatedFares[compatibleVehicle],
                        onTap: () => Navigator.pop(context, compatibleVehicle),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (hasRecommendation)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF727C),
            ),
            onPressed: () => Navigator.pop<String>(context),
            child: const Text('Rechazar'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            hasRecommendation ? recommendation : null,
          ),
          child: Text(hasRecommendation
              ? (recommendationActionLabel ?? 'Cambiar a $recommendation')
              : 'Entendido'),
        ),
      ],
    );
  }
}

class _RecommendedVehicleOption extends StatelessWidget {
  const _RecommendedVehicleOption({
    required this.vehicle,
    required this.asset,
    required this.estimatedFare,
    required this.onTap,
  });

  final String vehicle;
  final String asset;
  final double? estimatedFare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1D4FC5).withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4E8BFF)),
        ),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recomendado',
                style: TextStyle(
                  color: Color(0xFFB8D7FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
            SizedBox(
              height: 84,
              width: double.infinity,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      _FareText(value: estimatedFare),
                    ],
                  ),
                ),
                const Text(
                  'Elegir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatibleVehicleOption extends StatelessWidget {
  const _CompatibleVehicleOption({
    required this.vehicle,
    required this.asset,
    required this.estimatedFare,
    required this.onTap,
  });

  final String vehicle;
  final String asset;
  final double? estimatedFare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                height: 52,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    _FareText(value: estimatedFare),
                  ],
                ),
              ),
              const Text(
                'Elegir',
                style: TextStyle(
                  color: Color(0xFFB8D7FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB8D7FF),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FareText extends StatelessWidget {
  const _FareText({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value == null
          ? 'Tarifa según distancia'
          : 'Tarifa estimada: C\$ ${value!.toStringAsFixed(0)}',
      style: const TextStyle(
        color: Color(0xFFB8D7FF),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        fontFamily: 'Figtree',
      ),
    );
  }
}

class _ProductValueCard extends StatelessWidget {
  const _ProductValueCard({
    required this.controller,
    required this.bundlesController,
    required this.title,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onDecreaseBundles,
    required this.onIncreaseBundles,
  });

  final TextEditingController controller;
  final TextEditingController bundlesController;
  final String title;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onDecreaseBundles;
  final VoidCallback onIncreaseBundles;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/img/HomeCliente/icono_producto.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 5),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ingresa el valor total del producto a enviar.',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 9,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: Container(
                                    height: 29,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: glassBorder),
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      textAlignVertical:
                                          const TextAlignVertical(y: 0.35),
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Figtree',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFB9D4FF),
                                          fontSize: 10,
                                          fontFamily: 'Figtree',
                                        ),
                                        prefixText: currency == 'USD'
                                            ? 'US\$ '
                                            : 'C\$ ',
                                        prefixStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Figtree',
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 68,
                                  child: _InvoiceSegment(
                                    options: const ['C\$', 'USD'],
                                    value: currency,
                                    onChanged: onCurrencyChanged,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cantidad de bultos',
                            style: TextStyle(
                              color: Color(0xFFB9D4FF),
                              fontSize: 9,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: glassBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BundleStepButton(
                                  icon: Icons.remove,
                                  tooltip: 'Disminuir bultos',
                                  onPressed: onDecreaseBundles,
                                ),
                                SizedBox(
                                  width: 42,
                                  child: TextField(
                                    controller: bundlesController,
                                    keyboardType: TextInputType.number,
                                    textAlignVertical:
                                        const TextAlignVertical(y: 0.35),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Figtree',
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '1',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFB9D4FF),
                                        fontSize: 11,
                                        fontFamily: 'Figtree',
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                _BundleStepButton(
                                  icon: Icons.add,
                                  tooltip: 'Aumentar bultos',
                                  onPressed: onIncreaseBundles,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleStepButton extends StatelessWidget {
  const _BundleStepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accentBlue.withValues(alpha: .72),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
        ),
      );
}

class _CargaHeader extends StatelessWidget {
  const _CargaHeader({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ),
          const _StepChip(label: 'Paso 2'),
        ],
      );
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree')),
      );
}

class _ShippingVehicleCard extends StatelessWidget {
  const _ShippingVehicleCard({required this.label, required this.asset});
  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 20,
        selected: true,
        fillColor: const Color(0x30284678),
        child: SizedBox(
          height: 214,
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 16,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Seleccionado',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                top: 36,
                bottom: 4,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      );
}

class _CargaSectionTitle extends StatelessWidget {
  const _CargaSectionTitle(
      {required this.icon, required this.title, required this.subtitle});
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      );
}

class _CargaField extends StatelessWidget {
  const _CargaField(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap,
      this.trailing,
      this.content});
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? content;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Image.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      const SizedBox(height: 2),
                      content ??
                          Text(value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      );
}

class _InvoiceInputField extends StatelessWidget {
  const _InvoiceInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 18,
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Figtree',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 10.5,
                fontFamily: 'Figtree',
              ),
              prefixIcon: Icon(icon, color: Colors.white, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(right: 12),
            ),
          ),
        ),
      );
}

class _CargaChoiceCard extends StatelessWidget {
  const _CargaChoiceCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree')),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontFamily: 'Figtree')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _CargaChoiceSegment(
                options: options,
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
}

class _CargaChoiceSegment extends StatelessWidget {
  const _CargaChoiceSegment({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: options
              .map(
                (option) => Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == option ? figmaBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: value == option
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontFamily: 'Figtree')),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class _InvoiceSegment extends StatelessWidget {
  const _InvoiceSegment({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 27,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
        ),
        child: Row(
          children: options.map((option) {
            final selected = value.trim().toLowerCase() == option.toLowerCase();
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? figmaBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: Colors.white, size: 18),
      );
}

class _PhotoUploadBox extends StatelessWidget {
  const _PhotoUploadBox({required this.photos, required this.onTap});
  final List<Uint8List> photos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 18,
          child: SizedBox(
            height: 126,
            child: photos.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text('Subir fotos del paquete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      SizedBox(height: 3),
                      Text('Formatos soportados: JPG, PNG (Max 5MB)',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontFamily: 'Figtree')),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(photos[index], fit: BoxFit.cover),
                    ),
                  ),
          ),
        ),
      );
}

class _FragileRow extends StatelessWidget {
  const _FragileRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset('assets/img/HomeCliente/carga_fragil.png',
              width: 22, height: 22, fit: BoxFit.contain),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿El producto es frágil?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                SizedBox(height: 2),
                Text('Nos ayudará a manipularlo correctamente.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                _FragileChoice(
                  label: 'No',
                  selected: !value,
                  onTap: () => onChanged(false),
                ),
                _FragileChoice(
                  label: 'Sí',
                  selected: value,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ),
        ],
      );
}

class _FragileChoice extends StatelessWidget {
  const _FragileChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      );
}
