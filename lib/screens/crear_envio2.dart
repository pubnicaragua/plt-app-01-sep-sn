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
          if (truckOptions.isNotEmpty && !truckOptions.any((item) => item.title == truckType)) {
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
          if (truckOptions.isNotEmpty && !truckOptions.any((item) => item.title == truckType)) {
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
      if (needsAdditional) 'Servicio adicional: ${_selectedOption?.title ?? additionalOption}',
      if (additionalNotes.text.trim().isNotEmpty)
        'Indicaciones: ${additionalNotes.text.trim()}',
    ].join(' · ');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Confirmarpedido(
          origin: widget.origin,
          destination: widget.destination,
          weight: weight,
          weightUnit: weightUnit,
          bundles: bundles,
          originPlace: widget.originPlace,
          destinationPlace: widget.destinationPlace,
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
          vehicleVariant: widget.transport == 'Camión' ? _selectedTruckCode : null,
          truckType: widget.transport == 'Camión' ? truckType : null,
          passengerCount: widget.serviceMode == 'Taxi Privado' ? passengerCount : null,
          returnTrip: _isReturnTrip,
          stops: List<TripStop>.of(additionalStops),
          options: _selectedOption == null ? const [] : [
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
      if (fallbackTitle != null && item.title == fallbackTitle && item.enabled) return item;
    }
    return null;
  }

  String _serviceCode(String code) => widget.serviceMode == 'Taxi Privado' && code.startsWith('delivery-')
      ? code.replaceFirst('delivery-', 'taxi-')
      : code;

  ServiceCatalogItem? _serviceOption(String code, {String? fallbackTitle}) => _findOption(_serviceCode(code), fallbackTitle: fallbackTitle);

  ServiceCatalogItem? get _selectedOption => additionalOption.isEmpty ? null : _findOption(additionalOption);

  bool get _isReturnTrip => additionalOption.contains('round-trip');

  List<ServiceCatalogItem> get _truckCatalog => (settings?.serviceCatalog ?? const <ServiceCatalogItem>[])
      .where((item) => item.kind == 'vehicle' && item.service == 'cargo' && item.transport == 'Camión' && item.enabled)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<_TruckTypeData> get _truckTypesForUi {
    if (_truckCatalog.isEmpty) return _truckTypes;
    return _truckCatalog.map((item) => _TruckTypeData(
      code: item.code,
      label: item.title,
      asset: _truckAsset(item.code),
      description: item.description,
      price: _priceLabel(item, 'C\$40 USD'),
    )).toList();
  }

  String _truckAsset(String code) {
    if (code.contains('extra-small')) return 'assets/img/HomeCliente/carga_extra_pequeno.png';
    if (code.contains('pickup')) return 'assets/img/HomeCliente/carga_minivan.png';
    if (code.contains('medium')) return 'assets/img/HomeCliente/carga_mediano.png';
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
    final prefix = item.currency == 'USD' ? 'US$' : 'C$';
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
      await _addStop();
    }
  }

  Future<void> _addStop() async {
    final controller = TextEditingController();
    final address = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar destino adicional', style: TextStyle(fontFamily: 'Figtree')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Dirección o referencia'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Agregar')),
        ],
      ),
    );
    controller.dispose();
    if (address == null || address.isEmpty || !mounted) return;
    setState(() => additionalStops.add(TripStop(label: 'Parada ${additionalStops.length + 1}', address: address, order: additionalStops.length + 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        darken: .04,
        backgroundLogoOpacity: .62,
        backgroundLogoOffsetY: -30,
        backgroundLogoScale: 1.02,
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
                      title: widget.transport == 'Moto'
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
                    const _FormSectionTitle(
                      icon: Icons.inventory_2_outlined,
                      title: 'Detalles de envío',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InputPill(
                            controller: recipient,
                            label: 'Destinatario(s)',
                            iconAsset:
                                'assets/img/HomeCliente/detalle_destinatario.png',
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InputPill(
                            controller: phone,
                            label: 'Teléfono(s)',
                            iconAsset:
                                'assets/img/HomeCliente/detalle_telefono.png',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InputPill(
                      controller: references,
                      label: 'Referencias',
                      iconAsset: 'assets/img/HomeCliente/detalle_lista.png',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    _InputPill(
                      controller: additionalNotes,
                      label: 'Indicaciones adicionales (Opcional)',
                      iconAsset: 'assets/img/HomeCliente/detalle_lista.png',
                      enabled: true,
                      maxLines: 1,
                      compact: true,
                    ),
                    if (widget.serviceMode == 'Taxi Privado') ...[
                      const SizedBox(height: 12),
                      const _FormSectionTitle(
                        icon: Icons.people_alt_outlined,
                        title: 'Cantidad de pasajeros',
                      ),
                      const SizedBox(height: 8),
                      _CounterField(
                        value: '$passengerCount pasajero${passengerCount == 1 ? '' : 's'}',
                        onMinus: passengerCount > 1
                            ? () => setState(() => passengerCount--)
                            : null,
                        onPlus: passengerCount < 6
                            ? () => setState(() => passengerCount++)
                            : null,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _additionalBlock(),
                    if (widget.transport == 'Vehículo' ||
                        widget.transport == 'Camión') ...[
                      const SizedBox(height: 14),
                      _fragileBlock(),
                    ],
                    const SizedBox(height: 12),
                    _productPhotosBlock(),
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
    final multiple = _serviceOption('delivery-multiple-stops', fallbackTitle: 'Varios destinos');
    final roundTrip = _serviceOption('delivery-round-trip', fallbackTitle: 'Ida y vuelta');
    final insurance = _serviceOption('delivery-insurance', fallbackTitle: 'Seguro');
    final waiting = _serviceOption('delivery-waiting', fallbackTitle: 'Espera en destino');
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
                selected: needsAdditional && additionalOption == (multiple?.code ?? _serviceCode('delivery-multiple-stops')),
                enabled: true,
                onTap: () => _selectAdditional('delivery-multiple-stops', 'Varios destinos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_regreso.png',
                title: roundTrip?.title ?? 'Ida y vuelta',
                subtitle: roundTrip?.description ?? 'Regreso al origen',
                price: _priceLabel(roundTrip, 'C\$40 USD'),
                selected: needsAdditional && additionalOption == (roundTrip?.code ?? _serviceCode('delivery-round-trip')),
                enabled: true,
                onTap: () => _selectAdditional('delivery-round-trip', 'Ida y vuelta'),
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
                selected: needsAdditional && additionalOption == (insurance?.code ?? _serviceCode('delivery-insurance')),
                enabled: true,
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
                selected: needsAdditional && additionalOption == (waiting?.code ?? _serviceCode('delivery-waiting')),
                enabled: true,
                onTap: () => _selectAdditional('delivery-waiting', 'Espera en destino'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cargoAdditionalBlock() {
    final helper = _findOption('cargo-helper', fallbackTitle: 'Ayudante');
    final multiple = _findOption('cargo-multiple-stops', fallbackTitle: 'Varios destinos');
    final roundTrip = _findOption('cargo-round-trip', fallbackTitle: 'Ida y vuelta');
    final waiting = _findOption('cargo-waiting', fallbackTitle: 'Espera en destino');
    final insurance = _findOption('cargo-insurance', fallbackTitle: 'Seguro');
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
                selected: needsAdditional && additionalOption == (helper?.code ?? 'cargo-helper'),
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
                selected: needsAdditional && additionalOption == (multiple?.code ?? 'cargo-multiple-stops'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-multiple-stops', 'Varios destinos'),
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
                selected: needsAdditional && additionalOption == (roundTrip?.code ?? 'cargo-round-trip'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-round-trip', 'Ida y vuelta'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/adicional_espera.png',
                title: waiting?.title ?? 'Espera en destino',
                subtitle: waiting?.description ?? '6 horas espera',
                price: _priceLabel(waiting, 'C\$40 USD'),
                selected: needsAdditional && additionalOption == (waiting?.code ?? 'cargo-waiting'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-waiting', 'Espera en destino'),
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
                selected: needsAdditional && additionalOption == (insurance?.code ?? 'cargo-insurance'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-insurance', 'Seguro'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdditionalOptionCard(
                iconAsset: 'assets/img/HomeCliente/carga_mas_camiones.png',
                title: _findOption('cargo-more-trucks')?.title ?? '¿Más camiones?',
                subtitle: _findOption('cargo-more-trucks')?.description ?? 'Escoge tu producto',
                price: _priceLabel(_findOption('cargo-more-trucks'), 'C\$40 USD'),
                selected: needsAdditional && additionalOption == (_findOption('cargo-more-trucks')?.code ?? 'cargo-more-trucks'),
                enabled: true,
                onTap: () => _selectAdditional('cargo-more-trucks', '¿Más camiones?'),
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

  Widget _paymentBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
  const _TruckTypeSelector({required this.selected, required this.types, required this.onChanged});

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
        CustomPaint(
          foregroundPainter: const _FormGlassEdgePainter(radius: 14),
          child: Container(
            height: 286,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
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
            child: CustomPaint(
              foregroundPainter: _FormGlassEdgePainter(
                radius: 12,
                selected: type.label == selected,
              ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: type.label == selected
                      ? accentBlue.withValues(alpha: .78)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
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

class _FormGlassEdgePainter extends CustomPainter {
  const _FormGlassEdgePainter({required this.radius, this.selected = false});

  final double radius;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: selected
            ? [
                cyan.withValues(alpha: .95),
                Colors.white.withValues(alpha: .42),
                cyan.withValues(alpha: .75)
              ]
            : [
                Colors.white.withValues(alpha: .48),
                Colors.white.withValues(alpha: .10),
                const Color(0x667EA5D8)
              ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.6), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FormGlassEdgePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.selected != selected;
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

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : .48,
      child: CustomPaint(
        foregroundPainter: const _FormGlassEdgePainter(radius: 22),
        child: Container(
          constraints: BoxConstraints(
              minHeight: compact ? 38 : (maxLines > 1 ? 52 : 45)),
          padding:
              EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 2 : 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconAsset != null)
                Image.asset(
                  iconAsset!,
                  width: 21,
                  height: 21,
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
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 10,
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
  });

  final IconData? icon;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : .42,
        child: CustomPaint(
          foregroundPainter: _FormGlassEdgePainter(
            radius: 11,
            selected: selected,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 58,
            padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
            decoration: BoxDecoration(
              color: selected
                  ? accentBlue.withValues(alpha: .78)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                if (iconAsset != null)
                  Image.asset(
                    iconAsset!,
                    width: 23,
                    height: 23,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 7.2,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: Colors.white.withValues(alpha: enabled ? .95 : .25),
                  size: 15,
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

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? accentBlue : Colors.white.withValues(alpha: .14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
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
