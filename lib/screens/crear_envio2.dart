import 'dart:typed_data';
import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'confirmar_pedido.dart';
import 'crear_envio3.dart';
import 'establecer_destinos.dart';

class CrearEnvio2 extends StatefulWidget {
  const CrearEnvio2({
    super.key,
    required this.origin,
    required this.destination,
    this.weight = 10,
    this.weightUnit = 'kg',
    this.bundles = 1,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Moto',
    this.maxPassengers = 4,
    this.serviceMode = 'Envíos',
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
  final int weight;
  final String weightUnit;
  final int bundles;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final int maxPassengers;
  final String serviceMode;
  final double? estimatedShipping;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;

  @override
  State<CrearEnvio2> createState() => _CrearEnvio2State();
}

class _CrearEnvio2State extends State<CrearEnvio2> {
  late String _routeOrigin;
  late String _routeDestination;
  PlaceSuggestion? _routeOriginPlace;
  PlaceSuggestion? _routeDestinationPlace;
  late int weight;
  late String weightUnit;
  late int bundles;
  int passengerCount = 1;
  late String truckType;
  late final TextEditingController description;
  late final TextEditingController invoicePrice;
  late final TextEditingController invoiceNumber;
  late final TextEditingController recipient;
  late final TextEditingController phone;
  late final TextEditingController references;
  late final TextEditingController additionalNotes;
  String currency = 'C\$';
  bool fragile = false;
  bool needsAdditional = false;
  String additionalOption = '';
  final additionalStops = <TripStop>[];
  String paymentStatus = 'Pendiente';
  String paymentMethod = 'Efectivo';
  final productPhotos = <Uint8List>[];
  Uint8List? invoicePhoto;
  String invoiceFileName = 'factura.jpg';
  AppSettings? settings;
  Timer? _settingsPoll;

  @override
  void initState() {
    super.initState();
    _routeOrigin = widget.origin;
    _routeDestination = widget.destination;
    _routeOriginPlace = widget.originPlace;
    _routeDestinationPlace = widget.destinationPlace;
    weight = widget.weight.clamp(1, 1500).toInt();
    weightUnit = widget.weightUnit == 'lb' ? 'lb' : 'kg';
    bundles = widget.bundles.clamp(1, 99).toInt();
    truckType = _truckTypes.first.label;
    fragile = widget.transport == 'Vehículo' || widget.transport == 'Camión';
    description = TextEditingController();
    invoicePrice = TextEditingController();
    invoiceNumber = TextEditingController();
    recipient = TextEditingController(text: widget.recipientName);
    phone = TextEditingController(text: widget.recipientPhone);
    references = TextEditingController(text: widget.destinationRefs);
    additionalNotes = TextEditingController();
    apiClient.getSettings().then((value) {
      if (mounted) {
        setState(() {
          settings = value;
          final truckOptions = _truckCatalog;
          if (truckOptions.isNotEmpty &&
              !truckOptions.any((item) => item.title == truckType)) {
            truckType = truckOptions.first.title;
          }
        });
      }
    }).catchError((_) {});
    _settingsPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSettings(),
    );
  }

  Future<void> _refreshSettings() async {
    try {
      final value = await apiClient.getSettings();
      if (mounted) {
        setState(() {
          settings = value;
          final truckOptions = _truckCatalog;
          if (truckOptions.isNotEmpty &&
              !truckOptions.any((item) => item.title == truckType)) {
            truckType = truckOptions.first.title;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _settingsPoll?.cancel();
    description.dispose();
    invoicePrice.dispose();
    invoiceNumber.dispose();
    recipient.dispose();
    phone.dispose();
    references.dispose();
    additionalNotes.dispose();
    super.dispose();
  }

  double get invoiceAmount {
    final normalized = invoicePrice.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double get invoiceAmountCs => currency == 'USD'
      ? invoiceAmount * (settings?.dollarRate ?? 36.5)
      : invoiceAmount;

  void _setUnit(String nextUnit) {
    if (nextUnit == weightUnit) return;
    setState(() {
      weight = nextUnit == 'lb'
          ? (weight * 2.20462).round().clamp(1, 3307).toInt()
          : (weight / 2.20462).round().clamp(1, 1500).toInt();
      weightUnit = nextUnit;
    });
  }

  Future<void> _pickImage({
    required bool invoice,
    required ImageSource source,
  }) async {
    if (!invoice && productPhotos.length >= 5) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 84,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (invoice) {
          invoicePhoto = bytes;
          invoiceFileName = image.name;
        } else {
          productPhotos.add(bytes);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la imagen.')),
      );
    }
  }

  Future<void> _pickInvoiceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null || !mounted) return;
      setState(() {
        invoicePhoto = file.bytes;
        invoiceFileName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la factura.')),
      );
    }
  }

  Future<void> _chooseProductSource() =>
      _pickImage(invoice: false, source: ImageSource.gallery);

  Future<void> _chooseInvoiceSource() =>
      _pickImage(invoice: true, source: ImageSource.gallery);

  void _continue() {
    if (recipient.text.trim().isEmpty || phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Completa el nombre del destinatario y el teléfono.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    final extraDescription = [
      if (widget.transport == 'Camión') 'Tipo de camión: $truckType',
      if (needsAdditional)
        'Servicio adicional: ${_selectedOption?.title ?? additionalOption}',
      if (additionalNotes.text.trim().isNotEmpty)
        'Indicaciones: ${additionalNotes.text.trim()}',
    ].join(' · ');
    if (widget.serviceMode == 'Taxi Privado') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CrearEnvio3(
            origin: _routeOrigin,
            destination: _routeDestination,
            weight: weight,
            weightUnit: weightUnit,
            bundles: bundles,
            originPlace: _routeOriginPlace,
            destinationPlace: _routeDestinationPlace,
            transport: widget.transport,
            description: [
              if (description.text.trim().isNotEmpty) description.text.trim(),
              if (extraDescription.isNotEmpty) extraDescription,
            ].join(' · '),
            fragile: false,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            serviceMode: widget.serviceMode,
            passengerCount: passengerCount,
            returnTrip: _isReturnTrip,
            stops: List<TripStop>.of(additionalStops),
            options: _selectedOption == null
                ? const []
                : [
                    TripOptionSelection(
                      code: _selectedOption!.code,
                      title: _selectedOption!.title,
                      description: _selectedOption!.description,
                      priceCs: _selectedOption!.priceCs,
                      currency: _selectedOption!.currency,
                    ),
                  ],
            originRefs: widget.originRefs,
            destinationRefs: references.text.trim(),
            recipientName: recipient.text.trim(),
            recipientPhone: phone.text.trim(),
            serviceType: widget.startScheduled ? 'Programado' : 'Express',
            scheduledDate: widget.startDate,
            scheduledTime: widget.startTime,
            isScheduled: widget.startScheduled,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Confirmarpedido(
          origin: _routeOrigin,
          destination: _routeDestination,
          weight: weight,
          weightUnit: weightUnit,
          bundles: bundles,
          originPlace: _routeOriginPlace,
          destinationPlace: _routeDestinationPlace,
          transport: widget.transport,
          estimatedShipping: widget.estimatedShipping,
          description: [
            if (description.text.trim().isNotEmpty) description.text.trim(),
            if (extraDescription.isNotEmpty) extraDescription,
          ].join(' · '),
          fragile: fragile,
          invoiceNumber: invoiceNumber.text.trim(),
          invoiceAmount: invoiceAmountCs,
          paymentStatus: paymentStatus,
          paymentMethod: paymentMethod,
          serviceMode: widget.serviceMode,
          vehicleVariant:
              widget.transport == 'Camión' ? _selectedTruckCode : null,
          truckType: widget.transport == 'Camión' ? truckType : null,
          passengerCount:
              widget.serviceMode == 'Taxi Privado' ? passengerCount : null,
          returnTrip: _isReturnTrip,
          stops: List<TripStop>.of(additionalStops),
          options: _selectedOption == null
              ? const []
              : [
                  TripOptionSelection(
                    code: _selectedOption!.code,
                    title: _selectedOption!.title,
                    description: _selectedOption!.description,
                    priceCs: _selectedOption!.priceCs,
                    currency: _selectedOption!.currency,
                  ),
                ],
          productPhotos: List<Uint8List>.of(productPhotos),
          invoicePhoto: invoicePhoto,
          invoiceFileName: invoiceFileName,
          originRefs: widget.originRefs,
          destinationRefs: references.text.trim(),
          recipientName: recipient.text.trim(),
          recipientPhone: phone.text.trim(),
          serviceType: widget.startScheduled ? 'Programado' : 'Express',
          scheduledDate: widget.startDate,
          scheduledTime: widget.startTime,
          isScheduled: widget.startScheduled,
        ),
      ),
    );
  }

  ServiceCatalogItem? _findOption(String code, {String? fallbackTitle}) {
    final items = settings?.serviceCatalog ?? const <ServiceCatalogItem>[];
    for (final item in items) {
      if (item.code == code && item.enabled) return item;
    }
    for (final item in items) {
      if (fallbackTitle != null && item.title == fallbackTitle && item.enabled)
        return item;
    }
    return null;
  }

  String _serviceCode(String code) =>
      widget.serviceMode == 'Taxi Privado' && code.startsWith('delivery-')
          ? code.replaceFirst('delivery-', 'taxi-')
          : code;

  ServiceCatalogItem? _serviceOption(String code, {String? fallbackTitle}) =>
      _findOption(_serviceCode(code), fallbackTitle: fallbackTitle);

  ServiceCatalogItem? get _selectedOption {
    if (additionalOption.isEmpty) return null;
    final item = _findOption(additionalOption);
    if (item != null) return item;
    if (additionalOption == 'cargo-refrigerated') {
      return const ServiceCatalogItem(
        id: 'local-cargo-refrigerated',
        code: 'cargo-refrigerated',
        kind: 'option',
        service: 'cargo',
        transport: 'Camión',
        title: 'Refrigerado',
        description: 'Para productos fríos',
        priceCs: 40,
        currency: 'USD',
        pricingMode: 'flat',
        enabled: true,
        sortOrder: 70,
      );
    }
    if (additionalOption == 'taxi-more-vehicles') {
      return const ServiceCatalogItem(
        id: 'local-taxi-more-vehicles',
        code: 'taxi-more-vehicles',
        kind: 'option',
        service: 'taxi',
        transport: 'Vehículo',
        title: 'Más vehículos',
        description: 'A una misma ruta',
        priceCs: 40,
        currency: 'USD',
        pricingMode: 'flat',
        enabled: true,
        sortOrder: 40,
      );
    }
    return null;
  }

  bool get _isReturnTrip => additionalOption.contains('round-trip');

  List<ServiceCatalogItem> get _truckCatalog =>
      (settings?.serviceCatalog ?? const <ServiceCatalogItem>[])
          .where((item) =>
              item.kind == 'vehicle' &&
              item.service == 'cargo' &&
              item.transport == 'Camión' &&
              item.enabled)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<_TruckTypeData> get _truckTypesForUi {
    if (_truckCatalog.isEmpty) return _truckTypes;
    return _truckCatalog
        .map((item) => _TruckTypeData(
              code: item.code,
              label: item.title,
              asset: _truckAsset(item.code),
              description: item.description,
              price: _priceLabel(item, 'C\$40 USD'),
            ))
        .toList();
  }

  String _truckAsset(String code) {
    if (code.contains('extra-small'))
      return 'assets/img/HomeCliente/carga_extra_pequeno.png';
    if (code.contains('pickup'))
      return 'assets/img/HomeCliente/carga_minivan.png';
    if (code.contains('medium'))
      return 'assets/img/HomeCliente/carga_mediano.png';
    return 'assets/img/HomeCliente/carga_grande.png';
  }

  String? get _selectedTruckCode {
    for (final item in _truckCatalog) {
      if (item.title == truckType) return item.code;
    }
    return null;
  }

  String _priceLabel(ServiceCatalogItem? item, String fallback) {
    if (item == null) return fallback;
    final prefix = item.currency == 'USD' ? 'US\$' : 'C\$';
    return '$prefix${item.priceCs.toStringAsFixed(item.priceCs.truncateToDouble() == item.priceCs ? 0 : 2)}';
  }

  Future<void> _selectAdditional(String code, String fallbackTitle) async {
    final resolvedCode = _serviceCode(code);
    final item = _findOption(resolvedCode, fallbackTitle: fallbackTitle);
    setState(() {
      needsAdditional = true;
      additionalOption = item?.code ?? resolvedCode;
    });
    if (code.contains('multiple-stops')) {
      final result = await Navigator.of(context).push<RouteDestinationsResult>(
        MaterialPageRoute(
          builder: (_) => EstablecerDestinos(
            origin: _routeOrigin,
            destination: _routeDestination,
            originPlace: _routeOriginPlace,
            destinationPlace: _routeDestinationPlace,
            initialStops: additionalStops,
            collectRecipientDetails: widget.serviceMode != 'Taxi Privado',
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _routeOrigin = result.origin;
        _routeDestination = result.destination;
        _routeOriginPlace = result.originPlace;
        _routeDestinationPlace = result.destinationPlace;
        additionalStops
          ..clear()
          ..addAll(result.stops);
      });
    }
  }

  Future<void> _addStop() async {
    final controller = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar destino adicional',
            style: TextStyle(fontFamily: 'Figtree')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Dirección o referencia'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    controller.dispose();
    if (address == null || address.isEmpty || !mounted) return;
    setState(() => additionalStops.add(TripStop(
        label: 'Parada ${additionalStops.length + 1}',
        address: address,
        order: additionalStops.length + 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        darken: .04,
        backgroundLogoOpacity: .62,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 18),
                  children: [
                    _PageHeader(
                      title: widget.serviceMode == 'Taxi Privado'
                          ? 'Taxi Privado'
                          : widget.transport == 'Moto'
                              ? 'Motos'
                              : widget.transport == 'Vehículo'
                                  ? 'Autos'
                                  : 'Carga',
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    if (widget.transport == 'Camión') ...[
                      const SizedBox(height: 12),
                      _TruckTypeSelector(
                        selected: truckType,
                        types: _truckTypesForUi,
                        onChanged: (value) => setState(() => truckType = value),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 14),
                    _FormSectionTitle(
                      icon: widget.serviceMode == 'Taxi Privado'
                          ? Icons.local_taxi_outlined
                          : Icons.inventory_2_outlined,
                      title: widget.serviceMode == 'Taxi Privado'
                          ? 'Detalles del viaje'
                          : 'Detalles de envío',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InputPill(
                            controller: recipient,
                            label: widget.serviceMode == 'Taxi Privado'
                                ? 'Pasajero principal'
                                : 'Destinatario(s)',
                            iconAsset: widget.serviceMode == 'Taxi Privado'
                                ? 'assets/img/HomeCliente/carga_ayudante.png'
                                : 'assets/img/HomeCliente/detalle_destinatario.png',
                            textInputAction: TextInputAction.next,
                            large: widget.transport != 'Camión',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InputPill(
                            controller: phone,
                            label: widget.serviceMode == 'Taxi Privado'
                                ? 'Teléfono'
                                : 'Teléfono(s)',
                            iconAsset:
                                'assets/img/HomeCliente/detalle_telefono.png',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            large: widget.transport != 'Camión',
                          ),
                        ),
                      ],
                    ),
                    if (widget.serviceMode != 'Taxi Privado') ...[
                      const SizedBox(height: 8),
                      _InputPill(
                        controller: references,
                        label: 'Referencias',
                        iconAsset: 'assets/img/HomeCliente/detalle_lista.png',
                        textInputAction: TextInputAction.done,
                        large: widget.transport != 'Camión',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _InputPill(
                      controller: additionalNotes,
                      label: 'Indicaciones adicionales (Opcional)',
                      iconAsset: 'assets/img/HomeCliente/detalle_lista.png',
                      enabled: true,
                      maxLines: 1,
                      compact: true,
                      large: widget.transport != 'Camión',
                    ),
                    if (widget.serviceMode == 'Taxi Privado') ...[
                      const SizedBox(height: 12),
                      const _FormSectionTitle(
                        icon: Icons.people_alt_outlined,
                        title: 'Cantidad de pasajeros',
                      ),
                      const SizedBox(height: 8),
                      _PassengerCounterField(
                        value: passengerCount,
                        onMinus: passengerCount > 1
                            ? () => setState(() => passengerCount--)
                            : null,
                        onPlus: passengerCount < widget.maxPassengers
                            ? () => setState(() => passengerCount++)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _TaxiGlassPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/img/HomeCliente/taxi_passenger_info.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    height: 1.3,
                                    fontFamily: 'Figtree',
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Recuerda que según el vehículo varía la cantidad máxima de pasajeros:\n',
                                    ),
                                    TextSpan(
                                      text:
                                          'Máximo ${widget.maxPassengers} pasajeros',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _additionalBlock(),
                    if (widget.serviceMode != 'Taxi Privado' &&
                        (widget.transport == 'Vehículo' ||
                            widget.transport == 'Camión')) ...[
                      const SizedBox(height: 14),
                      _fragileBlock(),
                    ],
                    if (widget.serviceMode == 'Taxi Privado') ...[
                      const SizedBox(height: 14),
                      _paymentBlock(includeInvoice: false),
                    ] else ...[
                      const SizedBox(height: 12),
                      _productPhotosBlock(),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: GlassButton(
                  label: 'Siguiente',
                  filled: true,
                  height: 42,
                  fontSize: 14,
                  textColor: Colors.white,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _additionalBlock() {
    if (widget.transport == 'Camión') {
      return _cargoAdditionalBlock();
    }

    return _standardAdditionalBlock();
  }

  Widget _standardAdditionalBlock() {
    if (widget.serviceMode == 'Taxi Privado') {
      return _taxiAdditionalBlock();
    }

    final multiple = _serviceOption('delivery-multiple-stops',
        fallbackTitle: 'Varios destinos');
    final roundTrip =
        _serviceOption('delivery-round-trip', fallbackTitle: 'Ida y vuelta');
    final insurance =
        _serviceOption('delivery-insurance', fallbackTitle: 'Seguro');
    final waiting =
        _serviceOption('delivery-waiting', fallbackTitle: 'Espera en destino');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FormSectionTitle(
                icon: Icons.settings_outlined,
                title: '¿Necesitas algo adicional?',
              ),
            ),
            const Text(
              '(Opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_destinos.png',
                title: multiple?.title ?? 'Varios destinos',
                price: _priceLabel(multiple, 'C\$40 USD'),
                subtitle: multiple?.description ?? 'Múltiples destinos',
                selected: needsAdditional &&
                    additionalOption ==
                        (multiple?.code ??
                            _serviceCode('delivery-multiple-stops')),
                enabled: true,
                large: true,
                onTap: () => _selectAdditional(
                    'delivery-multiple-stops', 'Varios destinos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_regreso.png',
                title: roundTrip?.title ?? 'Ida y vuelta',
                subtitle: roundTrip?.description ?? 'Regreso al origen',
                price: _priceLabel(roundTrip, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (roundTrip?.code ??
                            _serviceCode('delivery-round-trip')),
                enabled: true,
                large: true,
                onTap: () =>
                    _selectAdditional('delivery-round-trip', 'Ida y vuelta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_seguro.png',
                title: insurance?.title ?? 'Seguro',
                subtitle: insurance?.description ?? 'Asegura tu producto',
                price: _priceLabel(insurance, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (insurance?.code ?? _serviceCode('delivery-insurance')),
                enabled: true,
                large: true,
                onTap: () => _selectAdditional('delivery-insurance', 'Seguro'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_espera.png',
                title: waiting?.title ?? 'Espera en destino',
                subtitle: waiting?.description ?? '6 horas espera',
                price: _priceLabel(waiting, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (waiting?.code ?? _serviceCode('delivery-waiting')),
                enabled: true,
                large: true,
                onTap: () =>
                    _selectAdditional('delivery-waiting', 'Espera en destino'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _taxiAdditionalBlock() {
    final multiple = _serviceOption('delivery-multiple-stops',
        fallbackTitle: 'Varios destinos');
    final roundTrip =
        _serviceOption('delivery-round-trip', fallbackTitle: 'Ida y vuelta');
    final insurance =
        _serviceOption('delivery-insurance', fallbackTitle: 'Seguro');
    final moreVehicles =
        _serviceOption('delivery-more-vehicles', fallbackTitle: 'Más vehículos');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FormSectionTitle(
                icon: Icons.settings_outlined,
                title: 'Servicios adicionales',
              ),
            ),
            TextButton(
              onPressed: _showTaxiServicesSheet,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: accentBlue,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                minimumSize: const Size(102, 34),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver todos'),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 27, top: 2, bottom: 9),
          child: Text('Añade servicios extra si los necesitas',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'Figtree')),
        ),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_destinos.png',
                title: multiple?.title ?? 'Varios destinos',
                subtitle: multiple?.description ?? 'Múltiples destinos',
                price: _priceLabel(multiple, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (multiple?.code ?? _serviceCode('delivery-multiple-stops')),
                enabled: true,
                onTap: () => _selectAdditional(
                    'delivery-multiple-stops', 'Varios destinos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_seguro.png',
                title: insurance?.title ?? 'Seguro',
                subtitle: insurance?.description ?? 'Asegura a los pasajeros',
                price: _priceLabel(insurance, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (insurance?.code ?? _serviceCode('delivery-insurance')),
                enabled: true,
                onTap: () => _selectAdditional('delivery-insurance', 'Seguro'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_regreso.png',
                title: roundTrip?.title ?? 'Ida y vuelta',
                subtitle: roundTrip?.description ?? 'Regreso al origen',
                price: _priceLabel(roundTrip, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (roundTrip?.code ??
                            _serviceCode('delivery-round-trip')),
                enabled: true,
                onTap: () =>
                    _selectAdditional('delivery-round-trip', 'Ida y vuelta'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/taxi_more_vehicles.png',
                title: moreVehicles?.title ?? 'Más vehículos',
                subtitle: moreVehicles?.description ?? 'A una misma ruta',
                price: _priceLabel(moreVehicles, 'US\$40'),
                selected: needsAdditional &&
                    additionalOption ==
                        (moreVehicles?.code ??
                            _serviceCode('delivery-more-vehicles')),
                enabled: true,
                onTap: () => _selectAdditional(
                    'delivery-more-vehicles', 'Más vehículos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTaxiServicesSheet() {
    var dismissing = false;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                  child: Container(color: const Color(0x55030B24)),
                ),
              ),
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if (notification.extent <= .045 && !dismissing) {
                  dismissing = true;
                  Navigator.of(dialogContext).pop();
                }
                return false;
              },
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  initialChildSize: .53,
                  minChildSize: .035,
                  maxChildSize: .82,
                  expand: false,
                  builder: (context, scrollController) {
          final multiple = _serviceOption('delivery-multiple-stops',
              fallbackTitle: 'Varios destinos');
          final roundTrip = _serviceOption('delivery-round-trip',
              fallbackTitle: 'Ida y vuelta');
          final insurance =
              _serviceOption('delivery-insurance', fallbackTitle: 'Seguro');
          final moreVehicles = _serviceOption('delivery-more-vehicles',
              fallbackTitle: 'Más vehículos');
          final options = [
            (
              icon: 'assets/img/HomeCliente/adicional_destinos.png',
              title: multiple?.title ?? 'Varios destinos',
              subtitle: multiple?.description ?? 'Múltiples destinos',
              price: _priceLabel(multiple, 'C\$40 USD'),
              code: multiple?.code ?? _serviceCode('delivery-multiple-stops'),
              fallback: 'Varios destinos',
            ),
            (
              icon: 'assets/img/HomeCliente/adicional_regreso.png',
              title: roundTrip?.title ?? 'Ida y vuelta',
              subtitle: roundTrip?.description ?? 'Regreso al origen',
              price: _priceLabel(roundTrip, 'C\$40 USD'),
              code: roundTrip?.code ?? _serviceCode('delivery-round-trip'),
              fallback: 'Ida y vuelta',
            ),
            (
              icon: 'assets/img/HomeCliente/adicional_seguro.png',
              title: insurance?.title ?? 'Seguro',
              subtitle: insurance?.description ?? 'Asegura a los pasajeros',
              price: _priceLabel(insurance, 'C\$40 USD'),
              code: insurance?.code ?? _serviceCode('delivery-insurance'),
              fallback: 'Seguro',
            ),
            (
              icon: 'assets/img/HomeCliente/taxi_more_vehicles.png',
              title: moreVehicles?.title ?? 'Más vehículos',
              subtitle: moreVehicles?.description ?? 'A una misma ruta',
              price: _priceLabel(moreVehicles, 'US\$40'),
              code: moreVehicles?.code ??
                  _serviceCode('delivery-more-vehicles'),
              fallback: 'Más vehículos',
            ),
          ];

          return ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AppGlassSurface(
                borderRadius: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 25, 20, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 21),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Servicios adicionales',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree',
                                  )),
                              Text('Añade servicios extra si los necesitas',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'Figtree',
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return _AdditionalOptionCard(
                            iconAsset: option.icon,
                            title: option.title,
                            subtitle: option.subtitle,
                            price: option.price,
                            selected: needsAdditional &&
                                additionalOption == option.code,
                            enabled: true,
                            large: true,
                            cardRadius: 13,
                            onTap: () =>
                                _selectAdditional(option.code, option.fallback),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cargoAdditionalBlock() {
    final helper = _findOption('cargo-helper', fallbackTitle: 'Ayudante');
    final multiple =
        _findOption('cargo-multiple-stops', fallbackTitle: 'Varios destinos');
    final roundTrip =
        _findOption('cargo-round-trip', fallbackTitle: 'Ida y vuelta');
    final waiting =
        _findOption('cargo-waiting', fallbackTitle: 'Espera en destino');
    final insurance = _findOption('cargo-insurance', fallbackTitle: 'Seguro');
    final refrigerated =
        _findOption('cargo-refrigerated', fallbackTitle: 'Refrigerado');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FormSectionTitle(
                icon: Icons.settings_outlined,
                title: '¿Necesitas algo adicional?',
              ),
            ),
            const Text(
              '(Opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/carga_ayudante.png',
                title: helper?.title ?? 'Ayudante',
                subtitle: helper?.description ?? 'Para carga y descarga',
                price: _priceLabel(helper, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption == (helper?.code ?? 'cargo-helper'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-helper', 'Ayudante'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_destinos.png',
                title: multiple?.title ?? 'Varios destinos',
                subtitle: multiple?.description ?? 'Múltiples destinos',
                price: _priceLabel(multiple, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (multiple?.code ?? 'cargo-multiple-stops'),
                enabled: true,
                onTap: () => _selectAdditional(
                    'cargo-multiple-stops', 'Varios destinos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_regreso.png',
                title: roundTrip?.title ?? 'Ida y vuelta',
                subtitle: roundTrip?.description ?? 'Regreso al origen',
                price: _priceLabel(roundTrip, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption == (roundTrip?.code ?? 'cargo-round-trip'),
                enabled: true,
                onTap: () =>
                    _selectAdditional('cargo-round-trip', 'Ida y vuelta'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_espera.png',
                title: waiting?.title ?? 'Espera en destino',
                subtitle: waiting?.description ?? '6 horas espera',
                price: _priceLabel(waiting, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption == (waiting?.code ?? 'cargo-waiting'),
                enabled: true,
                onTap: () =>
                    _selectAdditional('cargo-waiting', 'Espera en destino'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_seguro.png',
                title: insurance?.title ?? 'Seguro',
                subtitle: insurance?.description ?? 'Asegura tu producto',
                price: _priceLabel(insurance, 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption == (insurance?.code ?? 'cargo-insurance'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-insurance', 'Seguro'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/carga_mas_camiones.png',
                title:
                    _findOption('cargo-more-trucks')?.title ?? '¿Más camiones?',
                subtitle: _findOption('cargo-more-trucks')?.description ??
                    'Escoge tu producto',
                price:
                    _priceLabel(_findOption('cargo-more-trucks'), 'C\$40 USD'),
                selected: needsAdditional &&
                    additionalOption ==
                        (_findOption('cargo-more-trucks')?.code ??
                            'cargo-more-trucks'),
                enabled: true,
                onTap: () =>
                    _selectAdditional('cargo-more-trucks', '¿Más camiones?'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/refrigerado.png',
                title: refrigerated?.title ?? 'Refrigerado',
                subtitle: refrigerated?.description ?? 'Para productos fríos',
                price: _priceLabel(refrigerated, 'US\$40'),
                selected: needsAdditional &&
                    additionalOption ==
                        (refrigerated?.code ?? 'cargo-refrigerated'),
                enabled: true,
                onTap: () =>
                    _selectAdditional('cargo-refrigerated', 'Refrigerado'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                title: 'Próximamente...',
                subtitle: '',
                price: '',
                selected: false,
                enabled: false,
                showLeadingIcon: false,
                showSelectionControl: false,
                hideMeta: true,
                centerTitle: true,
                disabledOpacity: .72,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dimensionBlock() {
    final weightShortcuts =
        weightUnit == 'lb' ? const [5, 15, 45, 200] : const [5, 15, 45, 405];
    final maxWeight = weightUnit == 'lb' ? '3,307 lb' : '1,500 kg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelRow('Peso aproximado de la carga', 'Límite hasta $maxWeight'),
        const SizedBox(height: 9),
        _CounterField(
          value: '$weight ${weightUnit == 'lb' ? 'lbs' : 'kg'}',
          onMinus:
              weight > 1 ? () => setState(() => weight = weight - 1) : null,
          onPlus: weight < (weightUnit == 'lb' ? 3307 : 1500)
              ? () => setState(() => weight = weight + 1)
              : null,
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Text(
              'Unidad:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(width: 10),
            _UnitToggle(value: weightUnit, onChanged: _setUnit),
          ],
        ),
        const SizedBox(height: 13),
        _shortcutRow(
          'Atajos:',
          weightShortcuts,
          suffix: weightUnit == 'lb' ? 'lbs' : 'kg',
          selected: weight,
          onSelected: (value) => setState(() => weight = value),
        ),
        const SizedBox(height: 27),
        const Text(
          'Cantidad de bultos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 8),
        _labelRow(
          'Peso aproximado de la carga',
          weightUnit == 'lb'
              ? 'Límite hasta 1,000 lbs'
              : 'Límite hasta 1,000 kg',
        ),
        const SizedBox(height: 9),
        _CounterField(
          value: '$bundles Bulto${bundles == 1 ? '' : 's'}',
          onMinus:
              bundles > 1 ? () => setState(() => bundles = bundles - 1) : null,
          onPlus:
              bundles < 99 ? () => setState(() => bundles = bundles + 1) : null,
        ),
        const SizedBox(height: 9),
        _shortcutRow(
          'Atajos:',
          const [1, 3, 5, 10, 15, 20, 30, 40],
          selected: bundles,
          onSelected: (value) => setState(() => bundles = value),
        ),
      ],
    );
  }

  Widget _detailsBlock() {
    return Column(
      children: [
        GlassField(
          label: 'Descripción del paquete',
          hint: 'Descripción del paquete',
          icon: Icons.person,
          controller: description,
          showFloatingLabel: false,
        ),
        const SizedBox(height: 13),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassField(
                label: 'Precio de factura',
                hint: 'Precio de factura',
                icon: Icons.person,
                controller: invoicePrice,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                showFloatingLabel: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            _CurrencyToggle(
              value: currency,
              onChanged: (value) => setState(() => currency = value),
            ),
          ],
        ),
        const SizedBox(height: 13),
        GlassField(
          label: 'Número de factura',
          hint: 'Número de factura',
          icon: Icons.person,
          controller: invoiceNumber,
          showFloatingLabel: false,
        ),
      ],
    );
  }

  Widget _fragileBlock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/img/HomeCliente/carga_fragil.png',
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Text(
              '¿El producto es frágil?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
        _AdditionalSwitch(
          value: fragile,
          onChanged: (value) => setState(() => fragile = value),
        ),
      ],
    );
  }

  Widget _productPhotosBlock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap:
                      productPhotos.length >= 5 ? null : _chooseProductSource,
                  child: CustomPaint(
                    foregroundPainter: _DashedBorderPainter(
                      color: cyan.withValues(alpha: .78),
                      radius: 20,
                    ),
                    child: Container(
                      height: 105,
                      decoration: BoxDecoration(
                        color: figmaBlue.withValues(alpha: .48),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/img/HomeCliente/subir_fotos.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Subir fotos del paquete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Formatos soportados: JPG, PNG (Max 5MB)',
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 9,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (productPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final photo in productPhotos)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(photo,
                              width: 66, height: 66, fit: BoxFit.cover),
                        ),
                      if (productPhotos.length < 5)
                        _AddPhotoButton(onTap: _chooseProductSource),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paymentBlock({bool includeInvoice = true}) {
    if (!includeInvoice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset('assets/img/HomeCliente/taxi_payment_title.png',
                  width: 20, height: 20, fit: BoxFit.contain),
              const SizedBox(width: 9),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Método de pago',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      )),
                  Text('Selecciona cómo deseas pagar el viaje.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'Figtree',
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TaxiPaymentOption(
                  label: 'Efectivo',
                  iconAsset: 'assets/img/HomeCliente/taxi_payment_cash.png',
                  selected: paymentMethod == 'Efectivo',
                  onTap: () => setState(() => paymentMethod = 'Efectivo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TaxiPaymentOption(
                  label: 'Transferencia',
                  iconAsset:
                      'assets/img/HomeCliente/taxi_payment_transfer.png',
                  selected: paymentMethod == 'Transferencia',
                  onTap: () => setState(() => paymentMethod = 'Transferencia'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeInvoice) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estado del pago',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              _StatusToggle(
                value: paymentStatus,
                options: const ['Pagado', 'Pendiente'],
                onChanged: (value) => setState(() => paymentStatus = value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _invoiceUploadCard(),
          const SizedBox(height: 19),
        ],
        const Text(
          'Método de pago',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                selected: paymentMethod == 'Efectivo',
                onTap: () => setState(() => paymentMethod = 'Efectivo'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _PaymentMethodCard(
                label: 'Transferencia',
                icon: Icons.account_balance_outlined,
                selected: paymentMethod == 'Transferencia',
                onTap: () => setState(() => paymentMethod = 'Transferencia'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _invoiceUploadCard() {
    final hasFile = invoicePhoto != null;
    final imageFile = RegExp(r'\.(jpe?g|png)$', caseSensitive: false)
        .hasMatch(invoiceFileName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionUploadCard(
          icon: hasFile && !imageFile
              ? Icons.description_outlined
              : Icons.attach_file_rounded,
          title: hasFile ? invoiceFileName : 'Adjuntar factura del producto',
          subtitle:
              hasFile ? 'Factura lista para enviar' : 'Todos los formatos',
          onTap: () => _pickImage(invoice: true, source: ImageSource.camera),
        ),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: _pickInvoiceFile,
            icon: const Icon(Icons.folder_open_outlined,
                color: Colors.white, size: 18),
            label: const Text(
              'Elegir archivo',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
        ),
        if (hasFile && imageFile) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                invoicePhoto!,
                width: 92,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _labelRow(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            right,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      ],
    );
  }

  Widget _shortcutRow(
    String label,
    List<int> values, {
    String? suffix,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in values) ...[
                  _Shortcut(
                    label: '$value${suffix == null ? '' : ' $suffix'}',
                    selected: selected == value,
                    onTap: () => onSelected(value),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TruckTypeData {
  const _TruckTypeData({
    this.code = '',
    required this.label,
    required this.asset,
    required this.description,
    this.price = 'C\$40 USD',
  });

  final String code;
  final String label;
  final String asset;
  final String description;
  final String price;
}

const _truckTypes = [
  _TruckTypeData(
    label: 'Camión extra pequeño',
    asset: 'assets/img/HomeCliente/carga_extra_pequeno.png',
    description: 'Ideal para cuando transportas múltiples cajas. Máx. 300 kg',
  ),
  _TruckTypeData(
    label: 'Minivan/pickup',
    asset: 'assets/img/HomeCliente/carga_minivan.png',
    description: 'Para muebles pequeños y cargas medianas.',
  ),
  _TruckTypeData(
    label: 'Camión mediano',
    asset: 'assets/img/HomeCliente/carga_mediano.png',
    description: 'Más espacio para electrodomésticos y mobiliario.',
  ),
  _TruckTypeData(
    label: 'Camión grande',
    asset: 'assets/img/HomeCliente/carga_grande.png',
    description: 'Para cargas voluminosas y pesadas.',
  ),
];

class _TruckTypeSelector extends StatelessWidget {
  const _TruckTypeSelector(
      {required this.selected, required this.types, required this.onChanged});

  final String selected;
  final List<_TruckTypeData> types;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedType = types.firstWhere(
      (type) => type.label == selected,
      orElse: () => types.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/img/HomeCliente/carga_tipo_camion.png',
              width: 21,
              height: 21,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Tipo de camiones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppGlassSurface(
          borderRadius: 14,
          child: Container(
            height: 286,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    selectedType.asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Text(
                  selectedType.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.15,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final type in types) ...[
          GestureDetector(
            onTap: () => onChanged(type.label),
            child: AppGlassSurface(
              borderRadius: 12,
              selected: type.label == selected,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    Text(
                      type.price,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      type.label == selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (type != types.last) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      ],
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({
    required this.controller,
    required this.label,
    this.icon,
    this.iconAsset,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.compact = false,
    this.large = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? iconAsset;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : .48,
      child: AppGlassSurface(
        borderRadius: 22,
        child: Container(
          constraints: BoxConstraints(
            minHeight: large
                ? (compact ? 46 : (maxLines > 1 ? 58 : 52))
                : (compact ? 38 : (maxLines > 1 ? 52 : 45)),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 2 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconAsset != null)
                Image.asset(
                  iconAsset!,
                  width: large ? 23 : 21,
                  height: large ? 23 : 21,
                  fit: BoxFit.contain,
                )
              else
                Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  textAlignVertical: TextAlignVertical.center,
                  strutStyle: const StrutStyle(
                    height: 1,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: large
                        ? (compact ? 11.5 : 12.5)
                        : (compact ? 10.5 : 11.5),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: large ? 11 : 10,
                      fontFamily: 'Figtree',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdditionalSwitch extends StatelessWidget {
  const _AdditionalSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _switchChoice('Sí', value),
            _switchChoice('No', !value),
          ],
        ),
      ),
    );
  }

  Widget _switchChoice(String label, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

class _AdditionalOptionCard extends StatelessWidget {
  const _AdditionalOptionCard({
    this.icon,
    this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.showLeadingIcon = true,
    this.showSelectionControl = true,
    this.hideMeta = false,
    this.disabledOpacity = .42,
    this.cardRadius = 11,
    this.backgroundColor,
    this.titleStyle,
    this.centerTitle = false,
    this.large = false,
  });

  final IconData? icon;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool showLeadingIcon;
  final bool showSelectionControl;
  final bool hideMeta;
  final double disabledOpacity;
  final double cardRadius;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : disabledOpacity,
        child: AppGlassSurface(
          borderRadius: cardRadius,
          selected: selected,
          fillColor: backgroundColor,
          child: Container(
            height: large ? 70 : 58,
            padding: EdgeInsets.fromLTRB(large ? 11 : 9, 7, 7, 7),
            child: Row(
              children: [
                if (showLeadingIcon && iconAsset != null)
                  Image.asset(
                    iconAsset!,
                    width: large ? 25 : 23,
                    height: large ? 25 : 23,
                    fit: BoxFit.contain,
                  )
                else if (showLeadingIcon)
                  Icon(icon, color: Colors.white, size: large ? 22 : 20),
                if (showLeadingIcon) SizedBox(width: large ? 9 : 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: centerTitle
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign:
                            centerTitle ? TextAlign.center : TextAlign.start,
                        style: titleStyle ??
                            TextStyle(
                              color: Colors.white,
                              fontSize: large ? 10.5 : 9.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                      ),
                      if (!hideMeta)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xD9FFFFFF),
                            fontSize: large ? 8.1 : 7.2,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      if (!hideMeta)
                        Text(
                          price,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: large ? 8.2 : 7.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                    ],
                  ),
                ),
                if (showSelectionControl)
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: Colors.white.withValues(alpha: enabled ? .95 : .25),
                    size: large ? 17 : 15,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 23),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ),
        const _StepPill(text: 'Paso 1'),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

class _PageSectionTitle extends StatelessWidget {
  const _PageSectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
            fontFamily: 'Figtree',
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.2,
              fontFamily: 'Figtree',
            ),
          ),
        ],
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel(
      {required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .30)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CounterButton(icon: Icons.remove_rounded, onTap: onMinus),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          _CounterButton(icon: Icons.add_rounded, onTap: onPlus, filled: true),
        ],
      ),
    );
  }
}

class _PassengerCounterField extends StatelessWidget {
  const _PassengerCounterField({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => _TaxiGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CounterButton(icon: Icons.remove_rounded, onTap: onMinus, size: 48),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value == 1 ? 'Pasajero' : 'Pasajeros',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
            _CounterButton(
                icon: Icons.add_rounded, onTap: onPlus, filled: true, size: 48),
          ],
        ),
      );
}

class _TaxiGlassPanel extends StatelessWidget {
  const _TaxiGlassPanel({
    required this.child,
    required this.padding,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool selected;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        // Match the exact edge and fill treatment used by vehicle choices.
        borderRadius: 13,
        selected: selected,
        child: Padding(padding: padding, child: child),
      );
}

class _TaxiPaymentOption extends StatelessWidget {
  const _TaxiPaymentOption({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: _TaxiGlassPanel(
          selected: selected,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Image.asset(iconAsset,
                  width: 22, height: 22, fit: BoxFit.contain),
              const SizedBox(width: 9),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    )),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      );
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? accentBlue : Colors.white.withValues(alpha: .14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon,
              color: onTap == null ? Colors.white38 : Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? cyan : Colors.white.withValues(alpha: .14)),
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
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option('kg'),
          _option('lb'),
        ],
      ),
    );
  }

  Widget _option(String option) {
    final selected = value == option;
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          option.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          _option('C\$', value == 'C\$'),
          _option('USD', value == 'USD'),
        ],
      ),
    );
  }

  Widget _option(String label, bool selected) {
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _BinaryToggle extends StatelessWidget {
  const _BinaryToggle({
    required this.value,
    required this.first,
    required this.second,
    required this.onChanged,
  });

  final bool value;
  final String first;
  final String second;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(first, value, () => onChanged(true)),
          _segment(second, !value, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _ActionUploadCard extends StatelessWidget {
  const _ActionUploadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: trailing == null ? 160 : 178,
            decoration: BoxDecoration(
              color: figmaBlue.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cyan.withValues(alpha: .48)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .38)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Figtree',
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: value == option ? accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 112,
        decoration: BoxDecoration(
          color: selected ? accentBlue : Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? cyan : Colors.white.withValues(alpha: .28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 38),
            const SizedBox(height: 7),
            Text(
              label,
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
    );
  }
}
