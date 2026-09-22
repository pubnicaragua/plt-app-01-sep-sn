import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import '../widgets/wizard.dart';
import 'confirmar_pedido.dart';

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
    this.startScheduled = false,
    this.startDate,
    this.startTime,
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
  final bool startScheduled;
  final String? startDate;
  final String? startTime;

  @override
  State<CrearEnvio1> createState() => _CrearEnvio1State();
}

class _CrearEnvio1State extends State<CrearEnvio1> {
  int weight = 10;
  String weightUnit = 'kg';
  int bundles = 1;
  late String transport;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late PlaceSuggestion? originPlace;
  late PlaceSuggestion? destinationPlace;
  AppSettings? settings;
  Timer? _settingsPoll;
  final description = TextEditingController();
  final invoicePrice = TextEditingController(text: '0,00');
  final invoiceNumber = TextEditingController(text: 'FAC-1003');
  late final TextEditingController recipient;
  late final TextEditingController phone;
  bool fragile = true;
  String currency = 'C\$';
  String paymentStatus = 'Pendiente';
  String paymentMethod = 'Efectivo';
  final productPhotos = <Uint8List>[];
  Uint8List? invoicePhoto;

  @override
  void initState() {
    super.initState();
    transport = widget.startTransport;
    origin = TextEditingController(text: widget.startOrigin);
    destination = TextEditingController(text: widget.startDestination);
    recipient = TextEditingController(text: widget.startRecipientName);
    phone = TextEditingController(text: widget.startRecipientPhone);
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
    _settingsPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSettings(),
    );
  }

  Future<void> _refreshSettings() async {
    try {
      final data = await apiClient.getSettings();
      if (mounted) setState(() => settings = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _settingsPoll?.cancel();
    origin.dispose();
    destination.dispose();
    description.dispose();
    invoicePrice.dispose();
    invoiceNumber.dispose();
    recipient.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _takePhoto({required bool invoice}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (invoice) {
          invoicePhoto = bytes;
        } else if (productPhotos.length < 5) {
          productPhotos.add(bytes);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la cámara.')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery({required bool invoice}) async {
    if (!invoice && productPhotos.length >= 5) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (invoice) {
          invoicePhoto = bytes;
        } else {
          productPhotos.add(bytes);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo seleccionar la imagen.')),
        );
      }
    }
  }

  double get _invoiceAmount {
    final normalized = invoicePrice.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double get _invoiceAmountCs =>
      _invoiceAmount * (currency == 'USD' ? settings?.dollarRate ?? 36.5 : 1);

  double? get _distanceKm {
    final from = originPlace;
    final to = destinationPlace;
    if (from == null || to == null) return null;
    final fromLatitude = from.latitude;
    final fromLongitude = from.longitude;
    final toLatitude = to.latitude;
    final toLongitude = to.longitude;
    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return null;
    }
    return haversineKm(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  double get _weightKg =>
      weightUnit == 'lb' ? weight / 2.20462 : weight.toDouble();

  String get _recommended {
    if (_weightKg <= 20) return 'Moto';
    if (_weightKg <= 200) return 'Vehículo';
    return 'Camión';
  }

  double? _priceFor(String vehicle) {
    final distance = _distanceKm;
    if (distance == null) return null;
    final rate = settings?.rateFor(vehicle);
    if (rate == null) return null;
    return roundFareCs(rate.baseFeeCs + distance * rate.farePerKmCs + logisticsServiceFeeCs,
        settings?.fareRoundingCs ?? 5);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceKm;
    final price = _priceFor(transport);
    final selectedInvoicePhoto = invoicePhoto;
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
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: cyan, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Peso y dimensiones',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
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
                        '$weight $weightUnit',
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final unit in ['kg', 'lb'])
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (weightUnit == unit) return;
                            final converted = unit == 'lb'
                                ? (weight * 2.20462).round().clamp(1, 9999)
                                : (weight / 2.20462).round().clamp(1, 9999);
                            weightUnit = unit;
                            weight = converted;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: weightUnit == unit
                                ? figmaBlue
                                : Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: weightUnit == unit
                                  ? cyan
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            unit.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'Cambia la unidad según la use tu cliente u operación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 9.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
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
                const SizedBox(height: 18),
                Divider(color: Colors.white.withValues(alpha: .14), height: 1),
                const SizedBox(height: 14),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$bundles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Información del paquete',
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
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Paso 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'DESCRIPCIÓN DEL PAQUETE',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 8),
                GlassField(
                  label: 'Descripción',
                  hint: 'Ej. Electrónicos, ropa, documentos…',
                  controller: description,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GlassField(
                        label: 'Precio de factura',
                        hint: '0,00',
                        controller: invoicePrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CurrencyChoice(
                      value: currency,
                      onChanged: (value) => setState(() => currency = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassField(
                  label: 'Número de factura',
                  hint: 'FAC-1003',
                  controller: invoiceNumber,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GlassField(
                        label: 'Destinatario',
                        hint: 'Nombre completo',
                        controller: recipient,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: GlassField(
                        label: 'Teléfono',
                        hint: '+505 …',
                        controller: phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF5C63), size: 21),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Carga frágil?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                            Text(
                              'Requiere manejo especial',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 10,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fragile ? 'SÍ' : 'NO',
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      Switch.adaptive(
                        value: fragile,
                        onChanged: (value) => setState(() => fragile = value),
                        activeThumbColor: cyan,
                      ),
                    ],
                  ),
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
                  'EVIDENCIAS DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _takePhoto(invoice: false),
                  child: Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glassBorder),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            color: cyan, size: 25),
                        SizedBox(height: 5),
                        Text(
                          'Tomar foto del producto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        Text(
                          'JPG, PNG · máximo 5 MB por archivo',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 9.5,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final photo in productPhotos)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(photo,
                            width: 62, height: 62, fit: BoxFit.cover),
                      ),
                    GestureDetector(
                      onTap: productPhotos.length >= 5
                          ? null
                          : () => _pickImageFromGallery(invoice: false),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white70),
                      ),
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
                  'FACTURA DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _takePhoto(invoice: true),
                  child: Container(
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glassBorder),
                    ),
                    child: selectedInvoicePhoto == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_outlined,
                                    color: cyan, size: 26),
                                SizedBox(height: 6),
                                Text(
                                  'Toca para tomar foto de la factura',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Acumin Pro',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(selectedInvoicePhoto,
                                width: double.infinity,
                                height: 104,
                                fit: BoxFit.cover),
                          ),
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _pickImageFromGallery(invoice: true),
                    icon: const Icon(Icons.photo_library_outlined,
                        color: cyan, size: 16),
                    label: const Text(
                      'Seleccionar de galería',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
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
                  'ESTADO DEL PAGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Pendiente',
                        selected: paymentStatus == 'Pendiente',
                        onTap: () => setState(
                            () => paymentStatus = 'Pendiente'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Pagado',
                        selected: paymentStatus == 'Pagado',
                        onTap: () => setState(() => paymentStatus = 'Pagado'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'MÉTODO DE PAGO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Efectivo',
                        icon: Icons.payments_outlined,
                        selected: paymentMethod == 'Efectivo',
                        onTap: () => setState(() => paymentMethod = 'Efectivo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Transferencia',
                        icon: Icons.account_balance_outlined,
                        selected: paymentMethod == 'Transferencia',
                        onTap: () => setState(
                            () => paymentMethod = 'Transferencia'),
                      ),
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
                Row(
                  children: [
                    for (final (label, cap, icon, maxKg) in [
                      ('Moto', 'Hasta 20 kg', Icons.two_wheeler, 20),
                      ('Vehículo', 'Hasta 300 kg', Icons.directions_car_filled, 300),
                      ('Camión', 'Hasta 1,500 kg', Icons.local_shipping_outlined, 1500),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _CompactVehicleTile(
                            icon: icon,
                            label: label,
                            capacity: cap,
                            price: _priceFor(label),
                            selected: transport == label,
                            recommended: _recommended == label,
                            blocked: _weightKg > maxKg,
                            onTap: _weightKg > maxKg
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          '$label no soporta $weight $weightUnit. Cambia el peso o usa otro vehículo.',
                                          style: const TextStyle(fontFamily: 'Acumin Pro'),
                                        ),
                                      ),
                                    );
                                  }
                                : () => setState(() => transport = label),
                          ),
                        ),
                      ),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  _PriceBreakdown(
                    transport: transport,
                    price: price,
                    recommended: _recommended == transport,
                    productValue: _invoiceAmountCs,
                    currency: currency,
                    exchangeRate: settings?.dollarRate ?? 36.5,
                    fareRoundingCs: settings?.fareRoundingCs ?? 5,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Solicitar nuevo envío',
            filled: true,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Confirmarpedido(
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  weight: weight,
                  weightUnit: weightUnit,
                  bundles: bundles,
                  originPlace: originPlace,
                  destinationPlace: destinationPlace,
                  transport: transport,
                  estimatedShipping: price,
                  description: description.text.trim(),
                  fragile: fragile,
                  invoiceNumber: invoiceNumber.text.trim(),
                  invoiceAmount: _invoiceAmountCs,
                  paymentStatus: paymentStatus,
                  paymentMethod: paymentMethod,
                  productPhotos: productPhotos,
                  invoicePhoto: invoicePhoto,
                  originRefs: widget.startOriginRefs,
                  destinationRefs: widget.startDestinationRefs,
                  recipientName: recipient.text.trim(),
                  recipientPhone: phone.text.trim(),
                  serviceType: widget.startScheduled ? 'Programado' : 'Express',
                  scheduledDate: widget.startDate,
                  scheduledTime: widget.startTime,
                  isScheduled: widget.startScheduled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightChip(int value) {
    final converted = weightUnit == 'lb' ? (value * 2.20462).round() : value;
    final active = weight == converted;
    return GestureDetector(
      onTap: () => setState(() => weight = converted),
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
          '$converted $weightUnit',
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

class _CompactVehicleTile extends StatelessWidget {
  const _CompactVehicleTile({
    required this.icon,
    required this.label,
    required this.capacity,
    required this.price,
    required this.selected,
    required this.recommended,
    required this.blocked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String capacity;
  final double? price;
  final bool selected;
  final bool recommended;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = price;
    final borderColor = blocked
        ? const Color(0xFFE5484D).withValues(alpha: .45)
        : selected
            ? cyan
            : glassBorder;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 126,
        padding: const EdgeInsets.fromLTRB(9, 9, 8, 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .17)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Opacity(
          opacity: blocked ? .55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected ? figmaBlue : Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 17),
                  ),
                  Icon(
                    selected && !blocked
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected && !blocked ? cyan : Colors.white54,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                capacity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 9.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const Spacer(),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: mint.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: mint,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                )
              else
                Text(
                  amount == null ? 'C\$ —' : 'C\$${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyChoice extends StatelessWidget {
  const _CurrencyChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          _item('C\$', value == 'C\$'),
          _item('USD', value == 'USD'),
        ],
      ),
    );
  }

  Widget _item(String label, bool selected) {
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFB9D4FF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Acumin Pro',
          ),
        ),
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cyan : Colors.white.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? cyan : glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(height: 3),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ],
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
    this.blocked = false,
    this.blockedNote,
  });

  final IconData icon;
  final String label;
  final String capacity;
  final String subtitle;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;
  final double? price;
  final bool blocked;
  final String? blockedNote;

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
            color: blocked
                ? const Color(0xFFE5484D).withValues(alpha: .55)
                : selected
                    ? cyan
                    : glassBorder,
            width: blocked ? 1.4 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: blocked ? 0.55 : 1,
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
              selected && !blocked
                  ? Icons.radio_button_checked
                  : blocked
                      ? Icons.not_interested_rounded
                      : Icons.radio_button_unchecked,
              color: blocked
                  ? const Color(0xFFE5484D)
                  : selected
                      ? cyan
                      : Colors.white38,
              size: 21,
            ),
          ],
              ),
            ),
            if (blockedNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                child: Text(
                  blockedNote!,
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.transport,
    required this.price,
    required this.recommended,
    required this.productValue,
    required this.currency,
    required this.exchangeRate,
    required this.fareRoundingCs,
  });

  final String transport;
  final double price;
  final bool recommended;
  final double productValue;
  final String currency;
  final double exchangeRate;
  final double fareRoundingCs;

  String _money(double valueCs) {
    final value = currency == 'USD'
        ? valueCs / exchangeRate
        : roundFareCs(valueCs, fareRoundingCs);
    final symbol = currency == 'USD' ? 'USD' : 'C\$';
    return '$symbol ${value.toStringAsFixed(currency == 'USD' ? 2 : 0)}';
  }

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
            _money(price),
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
          Row(
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
          Row(
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
                _money(productValue),
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
                  'Envío ${_money(price * 0.20)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA0C4),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Total a pagar por el cliente\n${_money(price + productValue)}',
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
