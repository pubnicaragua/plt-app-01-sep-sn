import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'seguimiento_pedido.dart';

class CrearEnvio3 extends StatefulWidget {
  const CrearEnvio3({
    super.key,
    required this.origin,
    required this.destination,
    required this.weight,
    this.weightUnit = 'kg',
    required this.bundles,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Vehículo',
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
  final String description;
  final bool fragile;
  final String invoiceNumber;
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
  State<CrearEnvio3> createState() => _CrearEnvio3State();
}

class _CrearEnvio3State extends State<CrearEnvio3>
    with SingleTickerProviderStateMixin {
  bool failed = false;
  String? failureMessage;
  late final AnimationController characterAnimation;

  @override
  void initState() {
    super.initState();
    characterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _begin();
  }

  @override
  void dispose() {
    characterAnimation.dispose();
    super.dispose();
  }

  void _begin() {
    setState(() {
      failed = false;
      failureMessage = null;
    });
    _create();
  }

  Future<List<String>> _uploadShipmentEvidence() async {
    final stored = <String>[];
    for (var index = 0; index < widget.productPhotos.length; index++) {
      final result = await apiClient.uploadEvidence(
        widget.productPhotos[index],
        'paquete-${index + 1}.jpg',
      );
      stored.add(
        result['evidence']?.toString() ?? result['url']?.toString() ?? '',
      );
    }
    final invoice = widget.invoicePhoto;
    if (invoice != null) {
      final result =
          await apiClient.uploadEvidence(invoice, widget.invoiceFileName);
      stored.add(
        result['evidence']?.toString() ?? result['url']?.toString() ?? '',
      );
    }
    return stored.where((item) => item.isNotEmpty).toList();
  }

  Future<void> _create() async {
    try {
      final evidence = await _uploadShipmentEvidence();
      final originPlace = widget.originPlace;
      final destinationPlace = widget.destinationPlace;
      final currentUser = apiClient.currentUser;
      final companyName = currentUser?.companyName?.trim();
      final created = await apiClient.createTrip(
        client: companyName?.isNotEmpty == true
            ? companyName!
            : currentUser?.displayName ?? 'Empresa INCOEX',
        origin: widget.origin,
        destination: widget.destination,
        packages: widget.bundles,
        description: [
          if (widget.description.trim().isNotEmpty) widget.description.trim(),
          'Peso ${widget.weight}${widget.weightUnit}, ${widget.bundles} bulto(s)',
          if (widget.invoiceAmount > 0)
            'Valor de factura C\$${widget.invoiceAmount.toStringAsFixed(2)}',
          if (widget.invoiceNumber.trim().isNotEmpty)
            'Factura ${widget.invoiceNumber.trim()}',
          if (evidence.isNotEmpty) 'Evidencias: ${evidence.join(', ')}',
        ].join(' · '),
        originLat: originPlace?.latitude,
        originLng: originPlace?.longitude,
        destinationLat: destinationPlace?.latitude,
        destinationLng: destinationPlace?.longitude,
        distanceKm: distanceKm(
          originPlace,
          destinationPlace,
        ),
        transport: widget.transport,
        fragile: widget.fragile,
        autoAssign: true,
        originRefs: widget.originRefs.isEmpty ? null : widget.originRefs,
        destinationRefs: widget.destinationRefs.isEmpty ? null : widget.destinationRefs,
        recipientName: widget.recipientName.isEmpty ? null : widget.recipientName,
        recipientPhone: widget.recipientPhone.isEmpty ? null : widget.recipientPhone,
        serviceType: widget.serviceType,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
        isScheduled: widget.isScheduled || widget.serviceType == 'Programado',
        weight: widget.weight.toDouble(),
        weightUnit: widget.weightUnit == 'lb' ? 'lb' : 'kg',
      );
      if (widget.paymentStatus == 'Pagado' || widget.paymentMethod.isNotEmpty) {
        await apiClient.updateTripPayment(
          id: created.id,
          method: widget.paymentMethod,
          amount: widget.paymentStatus == 'Pagado'
              ? (created.estimatedCostCs ?? 0)
              : 0,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SeguimientoPedido(trip: created),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        failed = true;
        failureMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        failed = true;
        failureMessage =
            'No se pudo conectar con la API de Render. Revisa la URL del APK y tu conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 28,
                      child: Image.asset(
                        'assets/brand/incoex-logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 25,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .28)),
                        ),
                        child: const Center(
                          child: Text(
                            '× Cancelar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imageHeight = (constraints.maxHeight * .55)
                          .clamp(220.0, 300.0)
                          .toDouble();
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: AnimatedBuilder(
                              animation: characterAnimation,
                              builder: (context, child) {
                                final value = characterAnimation.value;
                                return Transform.translate(
                                  offset: Offset(0, -5 * value),
                                  child: Transform.scale(
                                    scale: .98 + value * .02,
                                    child: child,
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/img/EstadosCrearEnvio/crearenvio.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!failed)
                                  const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (!failed) const SizedBox(width: 5),
                                Text(
                                  failed
                                      ? 'No se pudo asignar'
                                      : 'Buscando conductor...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            failed ? 'No se pudo crear el pedido' : 'Asignando conductor',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            failed
                                ? failureMessage ??
                                    'No se pudo conectar con la API. Intenta nuevamente.'
                                : 'Estamos buscando un conductor disponible\ncerca de ti.',
                            maxLines: failed ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE1E8FF),
                              fontSize: 9.5,
                              height: 1.25,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 188,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: failed ? 1 : null,
                                minHeight: 4,
                                backgroundColor: Colors.white,
                                color: accentBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Esto puede tardar unos segundos...',
                            style: const TextStyle(
                              color: Color(0xFFD4DCFA),
                              fontSize: 8.5,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          if (failed) ...[
                            const SizedBox(height: 18),
                            GlassButton(
                              label: 'Reintentar búsqueda',
                              filled: true,
                              height: 38,
                              onPressed: _begin,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
