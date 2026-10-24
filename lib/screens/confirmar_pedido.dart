import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/invoice_breakdown.dart';
import '../core/insurance_flow.dart';
import '../core/shipment_payment_logic.dart';
import '../core/theme.dart';
import '../core/trip_routing.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'crear_envio3.dart';
import 'seguro_envio.dart';

class Confirmarpedido extends StatefulWidget {
  const Confirmarpedido({
    super.key,
    required this.origin,
    required this.destination,
    required this.weight,
    required this.weightUnit,
    required this.bundles,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Moto',
    this.estimatedShipping,
    this.description = '',
    this.fragile = false,
    this.invoiceNumber = '',
    this.invoiceAmount = 0,
    this.productPaymentStatus = 'Pendiente',
    this.productPaymentMethod = 'Efectivo',
    this.productIsSale = true,
    this.shipmentPaymentStatus = shipmentCashStatus,
    this.shipmentPaymentMethod = 'Efectivo',
    this.productPhotos = const [],
    this.invoicePhoto,
    this.invoiceFileName = 'factura.jpg',
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.serviceType = 'Express',
    this.scheduledDate,
    this.scheduledTime,
    this.isScheduled = false,
    this.serviceMode = 'Envíos',
    this.vehicleVariant,
    this.truckType,
    this.passengerCount,
    this.returnTrip = false,
    this.stops = const [],
    this.options = const [],
    this.insuranceReviewed = false,
  });

  final String origin;
  final String destination;
  final int weight;
  final String weightUnit;
  final int bundles;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final double? estimatedShipping;
  final String description;
  final bool fragile;
  final String invoiceNumber;
  // The step 2 screen normalizes this value to córdobas for the total.
  final double invoiceAmount;
  final String productPaymentStatus;
  final String productPaymentMethod;
  final bool productIsSale;
  final String shipmentPaymentStatus;
  final String shipmentPaymentMethod;
  final List<Uint8List> productPhotos;
  final Uint8List? invoicePhoto;
  final String invoiceFileName;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;
  final String serviceType;
  final String? scheduledDate;
  final String? scheduledTime;
  final bool isScheduled;
  final String serviceMode;
  final String? vehicleVariant;
  final String? truckType;
  final int? passengerCount;
  final bool returnTrip;
  final List<TripStop> stops;
  final List<TripOptionSelection> options;
  final bool insuranceReviewed;

  @override
  State<Confirmarpedido> createState() => _ConfirmarpedidoState();
}

class _ConfirmarpedidoState extends State<Confirmarpedido> {
  late String selectedTransport;
  late final TextEditingController invoiceNumber;
  late final TextEditingController invoicePrice;
  String currency = 'C\$';
  late String productPaymentStatus;
  late String productPaymentMethod;
  late String shipmentPaymentStatus;
  late String shipmentPaymentMethod;
  String shipmentPayer = 'Remitente / Comercio';
  Uint8List? invoicePhoto;
  String invoiceFileName = 'factura.jpg';
  AppSettings? settings;
  Timer? _settingsPoll;
  bool submitting = false;
  String? errorMessage;

  static const _vehicles = [
    (
      'Moto',
      'Para cargas pequeñas y livianas',
      'Hasta 20 kg',
      Icons.two_wheeler_rounded,
      20,
      85.0
    ),
    (
      'Vehículo',
      'Para cargas medianas',
      'Hasta 300 kg',
      Icons.directions_car_filled_rounded,
      300,
      210.0
    ),
    (
      'Camión',
      'Para cargas grandes o pesadas',
      'Hasta 1,500 kg',
      Icons.local_shipping_rounded,
      1500,
      530.0
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedTransport =
        _validTransport(widget.transport) ? widget.transport : 'Moto';
    invoiceNumber = TextEditingController(text: widget.invoiceNumber);
    invoicePrice = TextEditingController(
      text: widget.invoiceAmount > 0
          ? widget.invoiceAmount.toStringAsFixed(2)
          : '',
    );
    productPaymentStatus = widget.productIsSale
        ? widget.productPaymentStatus
        : 'Pendiente';
    productPaymentMethod = widget.productPaymentMethod;
    shipmentPaymentStatus = widget.shipmentPaymentStatus;
    shipmentPaymentMethod = widget.shipmentPaymentMethod;
    final availableMethods = _shipmentMethodsFor(shipmentPaymentStatus);
    if (availableMethods.isNotEmpty &&
        !availableMethods.contains(shipmentPaymentMethod)) {
      shipmentPaymentMethod = availableMethods.first;
    }
    invoicePhoto = widget.invoicePhoto;
    invoiceFileName = widget.invoiceFileName;
    apiClient.getSettings().then((value) {
      if (mounted) setState(() => settings = value);
    }).catchError((_) {});
    _settingsPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSettings(),
    );
  }

  Future<void> _refreshSettings() async {
    try {
      final value = await apiClient.getSettings();
      if (mounted) setState(() => settings = value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _settingsPoll?.cancel();
    invoiceNumber.dispose();
    invoicePrice.dispose();
    super.dispose();
  }

  double get _invoiceAmount {
    final normalized = invoicePrice.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double get _invoiceAmountCs => currency == 'USD'
      ? _invoiceAmount * (settings?.dollarRate ?? 36.5)
      : _invoiceAmount;

  Future<void> _pickInvoiceImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 84,
        maxWidth: 1400,
      );
      if (image == null || !mounted) return;
      setState(() {
        invoicePhoto = null;
        invoiceFileName = image.name;
      });
      invoicePhoto = await image.readAsBytes();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la factura.')),
        );
      }
    }
  }

  Future<void> _pickInvoiceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null || !mounted) return;
      setState(() {
        invoicePhoto = file.bytes;
        invoiceFileName = file.name;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo seleccionar la factura.')),
        );
      }
    }
  }

  bool _validTransport(String value) =>
      _vehicles.any((item) => item.$1 == value);

  double get _weightKg => widget.weightUnit == 'lb'
      ? widget.weight / 2.20462
      : widget.weight.toDouble();

  double? get _distance =>
      distanceKm(widget.originPlace, widget.destinationPlace);

  VehicleRate? _rateFor(String vehicle) => settings?.rateFor(vehicle);

  double _shippingFor(String vehicle) {
    if (vehicle == widget.transport && widget.estimatedShipping != null) {
      // Las cotizaciones ya no incluyen el cargo de gestión logística.
      return widget.estimatedShipping!.clamp(0, double.infinity).toDouble();
    }
    final rate = _rateFor(vehicle);
    final distance = _distance;
    if (rate != null && distance != null) {
      final surcharge = widget.serviceType == 'Express'
          ? settings?.prioritySurchargePct ?? 25
          : widget.serviceType == 'Programado'
              ? settings?.scheduledSurchargePct ?? 0
              : 0;
      final chargeableKm =
          (distance - rate.includedKm).clamp(0, double.infinity).toDouble();
      return roundFareCs(
          (rate.baseFeeCs +
                  chargeableKm * rate.farePerKmCs) *
              (1 + surcharge / 100),
          settings?.fareRoundingCs ?? 5);
    }
    return (_vehicle(vehicle).$6 - logisticsServiceFeeCs)
        .clamp(0, double.infinity)
        .toDouble();
  }

  bool get _invoiceAlreadyPaid =>
      productPaymentStatus.trim().toLowerCase() == 'pagado';

  bool get _isTripService {
    return isTripServiceMode(widget.serviceMode);
  }

  bool get _isShipmentRecipient {
    return !_isTripService && shipmentPayer == 'Destinatario';
  }

  double get _invoiceToCollect =>
      !widget.productIsSale || _invoiceAlreadyPaid ? 0 : _invoiceAmountCs;

  double _baseFor(String vehicle) =>
      _rateFor(vehicle)?.baseFeeCs ??
      _vehicle(vehicle).$6 - logisticsServiceFeeCs;

  (String, String, String, IconData, int, double) _vehicle(String value) =>
      _vehicles.firstWhere((item) => item.$1 == value,
          orElse: () => _vehicles.first);

  String _money(double value) =>
      formatFareCs(value, settings?.fareRoundingCs ?? 5);

  void _setShipmentPaymentStatus(String value) {
    final methods = _shipmentMethodsFor(value);
    setState(() {
      shipmentPaymentStatus = value;
      if (methods.isNotEmpty && !methods.contains(shipmentPaymentMethod)) {
        shipmentPaymentMethod = methods.first;
      }
    });
  }

  List<String> _shipmentMethodsFor(String status) {
    if (_isTripService) {
      return status.trim().toLowerCase() == shipmentCashStatus.toLowerCase()
          ? const ['Efectivo', 'Tarjeta']
          : const [];
    }
    if (_isShipmentRecipient) {
      return status.trim().toLowerCase() == shipmentCashStatus.toLowerCase()
          ? const ['Efectivo']
          : const [];
    }
    return status.trim().toLowerCase() == shipmentCashStatus.toLowerCase()
        ? const ['Tarjeta']
        : const [];
  }

  InvoiceBreakdown get _invoiceBreakdown {
    return _invoiceBreakdownFor(widget.options);
  }

  InvoiceBreakdown _invoiceBreakdownFor(List<TripOptionSelection> options) {
    final shipping = _shippingFor(selectedTransport);
    final base = _baseFor(selectedTransport);
    final additional =
        (shipping - base).clamp(0, double.infinity).toDouble();
    return buildInvoiceBreakdown(
      serviceMode: widget.serviceMode,
      transport: selectedTransport,
      shippingCs: shipping,
      baseCs: base,
      serviceCs: 0,
      additionalCs: additional,
      weight: widget.weight,
      weightUnit: widget.weightUnit,
      invoiceAmountCs: widget.productIsSale ? _invoiceAmountCs : 0,
      invoiceAlreadyPaid: !widget.productIsSale || _invoiceAlreadyPaid,
      options: options,
      dollarRate: settings?.dollarRate ?? 36.5,
    );
  }

  double get _insurancePriceCs {
    final preferredCode = widget.transport == 'Camión'
        ? 'cargo-insurance'
        : 'delivery-insurance';
    final catalog = settings?.serviceCatalog ?? const <ServiceCatalogItem>[];
    for (final item in catalog) {
      if (item.enabled && item.code == preferredCode) return item.priceCs;
    }
    return 15;
  }

  Future<void> _next() async {
    if (_isTripService ||
        widget.insuranceReviewed ||
        hasShipmentInsurance(widget.options)) {
      await _submit();
      return;
    }
    final baseTotal = _invoiceBreakdown.totalCs;
    final result = await Navigator.of(context).push<InsuranceSelectionResult>(
      MaterialPageRoute(
        builder: (_) => SeguroEnvioScreen(
          baseTotal: baseTotal,
          insurancePrice: _insurancePriceCs,
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _submit(insurance: result.option);
  }

  Future<void> _submit({TripOptionSelection? insurance}) async {
    if (submitting) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    if (!mounted) return;
    final submittedOptions = [
      ...widget.options,
      if (insurance != null) insurance,
    ];
    final submittedBreakdown = _invoiceBreakdownFor(submittedOptions);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CrearEnvio3(
          origin: widget.origin,
          destination: widget.destination,
          weight: widget.weight,
          weightUnit: widget.weightUnit,
          bundles: widget.bundles,
          originPlace: widget.originPlace,
          destinationPlace: widget.destinationPlace,
          transport: selectedTransport,
          description: widget.description,
          fragile: widget.fragile,
          invoiceNumber: _isTripService ? '' : invoiceNumber.text.trim(),
          invoiceAmount: _isTripService || !widget.productIsSale
              ? 0
              : _invoiceAmountCs,
          productPaymentStatus:
              _isTripService || !widget.productIsSale ? '' : productPaymentStatus,
          productPaymentMethod: _isTripService ? '' : productPaymentMethod,
          paymentStatus: shipmentPaymentStatus,
          paymentMethod: !_isTripService &&
                  shipmentPaymentStatus == shipmentCreditStatus
              ? ''
              : shipmentPaymentMethod,
          shipmentPayer: shipmentPayer,
          productIsSale: widget.productIsSale,
          productPhotos: _isTripService ? const [] : widget.productPhotos,
          invoicePhoto: _isTripService ? null : invoicePhoto,
          invoiceFileName: _isTripService ? '' : invoiceFileName,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          serviceType: widget.serviceType,
          scheduledDate: widget.scheduledDate,
          scheduledTime: widget.scheduledTime,
          isScheduled: widget.isScheduled,
          serviceMode: widget.serviceMode,
          vehicleVariant: widget.vehicleVariant,
          truckType: widget.truckType,
          passengerCount: widget.passengerCount,
          returnTrip: widget.returnTrip,
          stops: widget.stops,
          options: submittedOptions,
          quotedBaseCs: submittedBreakdown.lines
              .firstWhere((line) => line.label == submittedBreakdown.baseLabel)
              .amountCs,
          quotedAdditionalCs: submittedBreakdown.lines
              .where((line) => line.label == 'Distancia adicional')
              .fold<double>(0, (sum, line) => sum + line.amountCs),
          quotedServiceTotalCs: submittedBreakdown.shippingSubtotalCs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _invoiceBreakdown;
    return WizardScaffold(
      title: 'Detalles',
      subtitle: 'Detalles de facturación',
      description: '',
      step: 1,
      totalSteps: 3,
      onClose: () => Navigator.of(context).pop(),
      showNotification: false,
      showProgress: false,
      showDescription: false,
      showStepBadge: true,
      subtitleOffset: -30,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(0, -46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isTripService) ...[
                  _payerCard(),
                  if (!_isShipmentRecipient) ...[
                    const SizedBox(height: 10),
                    _paymentStatusCard(),
                  ],
                  const SizedBox(height: 10),
                  _paymentCard(),
                ] else ...[
                  _paymentStatusCard(),
                  if (shipmentPaymentStatus == shipmentCashStatus) ...[
                    const SizedBox(height: 10),
                    _paymentCard(),
                  ],
                ],
                const SizedBox(height: 10),
                _orderSummaryCard(breakdown),
                if (!_isTripService) ...[
                  const SizedBox(height: 10),
                  _invoiceUploadCard(),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 13),
                  Text(errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFFFC3C3),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree')),
                ],
              ],
            ),
          ),
          SizedBox(height: _isTripService ? 42 : 22),
          GlassButton(
            label: submitting ? 'Creando envío…' : 'Siguiente',
            filled: true,
            height: 44,
            textColor: Colors.white,
            onPressed: submitting ? () {} : _next,
          ),
        ],
      ),
    );
  }

  Widget _paymentStatusCard() {
    return _billingCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Estado del pago',
      subtitle: _isTripService
          ? 'Selecciona cómo se realizará el pago del viaje'
          : 'Selecciona cómo se realizará el pago del envío',
      options: _isShipmentRecipient
          ? const [shipmentCashStatus]
          : const [shipmentCashStatus, shipmentCreditStatus],
      value: shipmentPaymentStatus,
      onChanged: _setShipmentPaymentStatus,
    );
  }

  Widget _payerCard() {
    return _billingCard(
      icon: Icons.local_shipping_outlined,
      title: '¿Quién paga el envío?',
      subtitle: 'Selecciona quién cubrirá la tarifa del transporte.',
      options: const ['Remitente / Comercio', 'Destinatario'],
      value: shipmentPayer,
      onChanged: (value) => setState(() {
        shipmentPayer = value;
        if (value == 'Destinatario') {
          shipmentPaymentStatus = shipmentCashStatus;
          shipmentPaymentMethod = 'Efectivo';
        } else if (shipmentPaymentStatus == shipmentCashStatus) {
          shipmentPaymentMethod = 'Tarjeta';
        }
      }),
    );
  }

  Widget _paymentCard() {
    final methods = _shipmentMethodsFor(shipmentPaymentStatus);
    if (methods.isEmpty) return const SizedBox.shrink();
    return AppGlassSurface(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Método de pago',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
            const SizedBox(height: 5),
            _billingSegment(
              options: methods,
              value: shipmentPaymentMethod,
              onChanged: (value) =>
                  setState(() => shipmentPaymentMethod = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppGlassSurface(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 17),
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
                              fontSize: 8,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _billingSegment(
              options: options,
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderSummaryCard(InvoiceBreakdown breakdown) {
    final insurance = breakdown.lines
        .where((line) => line.label.toLowerCase().contains('seguro'))
        .fold<double>(0, (sum, line) => sum + line.amountCs);
    final shipping = _shippingFor(selectedTransport);
    final additionalLines = breakdown.lines.where((line) {
      final label = line.label.toLowerCase();
      return line.label != breakdown.baseLabel &&
          !label.contains('factura') &&
          !label.contains('seguro') &&
          !label.contains('distancia adicional') &&
          !label.contains('carga adicional') &&
          line.amountCs > 0;
    });
    return AppGlassSurface(
      borderRadius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isTripService ? 'Resumen del viaje' : 'Resumen del pedido',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
            const SizedBox(height: 8),
            if (!_isTripService)
              _summaryLine(
                icon: Icons.inventory_2_outlined,
                label: widget.productIsSale
                    ? 'Valor del producto'
                    : 'Valor aproximado del producto',
                amount: _invoiceAmountCs,
                status: widget.productIsSale
                    ? (_invoiceAlreadyPaid ? 'Pagado' : 'Paga destinatario')
                    : null,
                statusPositive: _invoiceAlreadyPaid,
              ),
            _summaryLine(
              icon: Icons.local_shipping_outlined,
              label: _isTripService ? 'Tarifa del viaje' : 'Tarifa de envío',
              amount: shipping,
            ),
            _summaryLine(
              icon: Icons.security_outlined,
              label: 'Seguro',
              amount: insurance,
            ),
            for (final line in additionalLines)
              _summaryLine(
                icon: Icons.add_circle_outline,
                label: line.label,
                amount: line.amountCs,
              ),
            const Divider(color: Colors.white38, height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(_isTripService
                      ? 'Subtotal del viaje'
                      : 'Subtotal del envío',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree')),
                ),
                if (!_isTripService) ...[
                  _orderPill(_payerSummaryLabel(shipmentPayer)),
                  const SizedBox(width: 6),
                ],
                Text(_money(breakdown.shippingSubtotalCs),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
              ],
            ),
            const Divider(color: Colors.white38, height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a gestionar:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                Text(_money(breakdown.totalCs),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine({
    required IconData icon,
    required String label,
    required double amount,
    String? status,
    bool statusPositive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    fontFamily: 'Figtree')),
          ),
          if (status != null) _orderPill(status, positive: statusPositive),
          const SizedBox(width: 5),
          Text(_money(amount),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree')),
        ],
      ),
    );
  }

  Widget _orderPill(String label, {bool positive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFF1CDB83) : figmaBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: positive ? Colors.black : Colors.white,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree')),
    );
  }

  String _payerSummaryLabel(String payer) =>
      payer == '—'
          ? '—'
          : payer == 'Destinatario'
              ? 'Paga destinatario'
              : 'Paga remitente';

  Widget _billingSegment({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        children: options.map((option) {
          final selected = value.trim().toLowerCase() == option.toLowerCase();
          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onChanged(option) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? figmaBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _billingCurrencySegment({bool enabled = true}) {
    return SizedBox(
      width: 82,
      child: _billingSegment(
        options: const ['C\$', 'USD'],
        value: currency,
        enabled: enabled,
        onChanged: (value) => setState(() => currency = value),
      ),
    );
  }

  Widget _billingInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return AppGlassSurface(
      borderRadius: 22,
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          readOnly: readOnly,
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

  Widget _billingTotalCard(InvoiceBreakdown breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total a cobrar al destinatario',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.white.withValues(alpha: .38)),
        const SizedBox(height: 6),
        for (final line in breakdown.lines)
          _billingPriceLine(
            line.label,
            line.amountCs,
            suffix: line.suffix,
          ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .26)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal del envío',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              Text(
                _money(breakdown.shippingSubtotalCs),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.white.withValues(alpha: .24)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total a pagar por el cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                Text(
                  'Envío + Producto',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
            Text(
              _money(breakdown.totalCs),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _billingPriceLine(String label, double value, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 10,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: Text(
              suffix ?? _money(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceUploadCard() {
    return GestureDetector(
      onTap: _showInvoicePicker,
      child: CustomPaint(
        painter: _BillingDashedBorderPainter(
          color: cyan,
          radius: 16,
          dashLength: 6,
          gapLength: 4,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xAA082C70),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (invoicePhoto != null &&
                  RegExp(r'\.(jpg|jpeg|png)$')
                      .hasMatch(invoiceFileName.toLowerCase()))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    invoicePhoto!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.image_outlined, color: Colors.white, size: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoicePhoto == null
                          ? 'Adjuntar factura del producto'
                          : invoiceFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Todos los formatos',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 9.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInvoicePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102A68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: Colors.white),
              title: const Text('Tomar foto',
                  style: TextStyle(color: Colors.white, fontFamily: 'Figtree')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickInvoiceImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Elegir imagen',
                  style: TextStyle(color: Colors.white, fontFamily: 'Figtree')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickInvoiceImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_file_rounded, color: Colors.white),
              title: const Text('Seleccionar archivo',
                  style: TextStyle(color: Colors.white, fontFamily: 'Figtree')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickInvoiceFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _transportCard(
      (String, String, String, IconData, int, double) vehicle) {
    final name = vehicle.$1;
    final blocked = _weightKg > vehicle.$5;
    final selected = selectedTransport == name;
    final price = _shippingFor(name);
    return GestureDetector(
      onTap: blocked ? null : () => setState(() => selectedTransport = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? figmaBlue : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: selected ? figmaBlue : glassBorder, width: 1),
        ),
        child: Opacity(
          opacity: blocked ? .45 : 1,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .30))),
                child: Icon(vehicle.$4, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: Text(name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree'))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(vehicle.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontFamily: 'Figtree')),
                    Text(vehicle.$3,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree')),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('ENVÍO DESDE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree')),
                  Text(_money(price),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalCard(
      {required double shipping,
      required double base,
      required double additional,
      required double service,
      required double total}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
                child: Text('Total a cobrar al destinatario',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree'))),
            _summaryPill(
                '$selectedTransport (${widget.weight} ${widget.weightUnit})'),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(_money(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    fontFamily: 'Figtree')),
            _summaryPill('Tarifa calculada al instante'),
          ],
        ),
        const SizedBox(height: 13),
        const Divider(color: Color(0x55FFFFFF), height: 1),
        const SizedBox(height: 8),
        _priceLine('Tarifa base de envío', base),
        _priceLine('Carga adicional (${widget.weight} ${widget.weightUnit})',
            additional),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withValues(alpha: .30))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal del envío',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
            Text(_money(shipping),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ]),
        ),
        if (widget.invoiceAmount > 0) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
                color: figmaBlue,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: figmaBlue)),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          widget.description.trim().isEmpty
                              ? 'Producto de la factura'
                              : widget.description.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      Text(
                          _invoiceAlreadyPaid
                              ? '(Producto pagado por transferencia)'
                              : '(Valor a recaudar para la empresa)',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontFamily: 'Figtree')),
                    ])),
                Text(
                    _invoiceAlreadyPaid
                        ? 'Pagado'
                        : '+ ${_money(_invoiceToCollect)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(color: Color(0x28FFFFFF), height: 1),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total a pagar por el cliente',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
              Text(
                  _invoiceAlreadyPaid
                      ? 'Envío · producto pagado'
                      : 'Envío + Producto',
                  style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 9.5,
                      fontFamily: 'Figtree')),
            ]),
            Text(_money(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ],
        ),
      ],
    );
  }

  Widget _summaryPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: .28)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }

  Widget _priceLine(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
            ),
            child: Text(_money(value),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree')),
          ),
        ],
      ),
    );
  }
}

class _BillingDashedBorderPainter extends CustomPainter {
  const _BillingDashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
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
        final end = (distance + dashLength).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BillingDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
