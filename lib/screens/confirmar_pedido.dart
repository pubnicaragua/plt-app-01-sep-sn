import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'crear_envio3.dart';

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
    this.paymentStatus = 'Pendiente',
    this.paymentMethod = 'Efectivo',
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
  final String paymentStatus;
  final String paymentMethod;
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

  @override
  State<Confirmarpedido> createState() => _ConfirmarpedidoState();
}

class _ConfirmarpedidoState extends State<Confirmarpedido> {
  late String selectedTransport;
  AppSettings? settings;
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
    apiClient.getSettings().then((value) {
      if (mounted) setState(() => settings = value);
    }).catchError((_) {});
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
    final rate = _rateFor(vehicle);
    final distance = _distance;
    if (rate != null && distance != null) {
      final surcharge = widget.serviceType == 'Express'
          ? settings?.prioritySurchargePct ?? 25
          : widget.serviceType == 'Programado'
              ? settings?.scheduledSurchargePct ?? 0
              : 0;
      return (rate.baseFeeCs + distance * rate.farePerKmCs +
              logisticsServiceFeeCs) *
          (1 + surcharge / 100);
    }
    if (vehicle == widget.transport && widget.estimatedShipping != null) {
      return widget.estimatedShipping!;
    }
    return _vehicle(vehicle).$6;
  }

  bool get _invoiceAlreadyPaid =>
      widget.paymentStatus.trim().toLowerCase() == 'pagado';

  double get _invoiceToCollect =>
      _invoiceAlreadyPaid ? 0 : widget.invoiceAmount;

  double _baseFor(String vehicle) =>
      _rateFor(vehicle)?.baseFeeCs ?? _vehicle(vehicle).$6 - logisticsServiceFeeCs;

  (String, String, String, IconData, int, double) _vehicle(String value) =>
      _vehicles.firstWhere((item) => item.$1 == value,
          orElse: () => _vehicles.first);

  String _money(double value) => 'C\$ ${value.toStringAsFixed(2)}';

  Future<void> _submit() async {
    if (submitting) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    if (!mounted) return;
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
          invoiceNumber: widget.invoiceNumber,
          invoiceAmount: widget.invoiceAmount,
          paymentStatus: widget.paymentStatus,
          paymentMethod: widget.paymentMethod,
          productPhotos: widget.productPhotos,
          invoicePhoto: widget.invoicePhoto,
          invoiceFileName: widget.invoiceFileName,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          serviceType: widget.serviceType,
          scheduledDate: widget.scheduledDate,
          scheduledTime: widget.scheduledTime,
          isScheduled: widget.isScheduled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipping = _shippingFor(selectedTransport);
    final base = _baseFor(selectedTransport);
    final service = logisticsServiceFeeCs;
    final additional =
        (shipping - base - service).clamp(0, double.infinity).toDouble();
    final total = shipping + _invoiceToCollect;
    return WizardScaffold(
      title: 'Detalles de carga',
      subtitle: 'Transporte recomendado',
      description:
          'Revisa el transporte, el valor a recaudar y confirma tu envío.',
      step: 2,
      totalSteps: 3,
      onClose: () => Navigator.of(context).pop(),
      showNotification: false,
      showProgress: false,
      showDescription: false,
      showStepBadge: true,
      backgroundLogoOpacity: .86,
      backgroundLogoOffsetY: -58,
      backgroundLogoScale: 1.08,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _vehicles.length; index++) ...[
            _transportCard(_vehicles[index]),
            if (index != _vehicles.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: .22),
            child: _totalCard(
              shipping: shipping,
              base: base,
              additional: additional,
              service: service,
              total: total,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 13),
            Text(errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFFC3C3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro')),
          ],
          const SizedBox(height: 24),
          GlassButton(
            label: submitting ? 'Creando envío…' : 'Confirmar envío',
            filled: true,
            height: 44,
            textColor: Colors.white,
            onPressed: submitting ? () {} : _submit,
          ),
        ],
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
          color: selected
              ? figmaBlue
              : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? figmaBlue : glassBorder, width: 1),
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
                                    fontFamily: 'Acumin Pro'))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(vehicle.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontFamily: 'Acumin Pro')),
                    Text(vehicle.$3,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro')),
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
                          fontFamily: 'Acumin Pro')),
                  Text(_money(price),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro')),
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
                        fontFamily: 'Acumin Pro'))),
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
                    fontFamily: 'Acumin Pro')),
            _summaryPill('Tarifa calculada al instante'),
          ],
        ),
        const SizedBox(height: 13),
        const Divider(color: Color(0x55FFFFFF), height: 1),
        const SizedBox(height: 8),
        _priceLine('Tarifa base de envío', base),
        _priceLine('Servicio y gestión logística', service),
        _priceLine('Carga adicional (${widget.weight} ${widget.weightUnit})',
            additional),
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withValues(alpha: .30))),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal del envío',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro')),
                Text(_money(shipping),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro')),
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
                              fontFamily: 'Acumin Pro')),
                      Text(
                          _invoiceAlreadyPaid
                              ? '(Producto pagado por transferencia)'
                              : '(Valor a recaudar para la empresa)',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontFamily: 'Acumin Pro')),
                    ])),
                Text(
                    _invoiceAlreadyPaid
                        ? 'Pagado'
                        : '+ ${_money(_invoiceToCollect)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro')),
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
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total a pagar por el cliente',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro')),
                  Text(
                      _invoiceAlreadyPaid
                          ? 'Envío · producto pagado'
                          : 'Envío + Producto',
                      style: TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 9.5,
                          fontFamily: 'Acumin Pro')),
                ]),
            Text(_money(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro')),
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
          fontFamily: 'Acumin Pro',
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
                    fontFamily: 'Acumin Pro')),
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
                    fontFamily: 'Acumin Pro')),
          ),
        ],
      ),
    );
  }
}
