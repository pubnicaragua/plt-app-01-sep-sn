import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/shipment_payment_logic.dart';
import '../core/trip_routing.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

String _invoiceServiceDescriptionValue(Trip trip, RegExp pattern) {
  final match = pattern.firstMatch(trip.description ?? '');
  return match?.group(1)?.trim() ?? '';
}

String invoiceServicePaymentStatusForTrip(Trip trip) {
  final fromDescription = _invoiceServiceDescriptionValue(
    trip,
    RegExp(r'Estado pago envío:\s*([^·]+)', caseSensitive: false),
  );
  if (fromDescription.isNotEmpty) return fromDescription;

  final value = trip.servicePaymentStatus?.trim();
  return value?.isNotEmpty == true ? value! : 'Pendiente';
}

String invoiceServicePaymentMethodForTrip(Trip trip) {
  final fromDescription = _invoiceServiceDescriptionValue(
    trip,
    RegExp(r'Método pago envío:\s*([^·]+)', caseSensitive: false),
  );
  final value = fromDescription.isNotEmpty
      ? fromDescription
      : trip.servicePaymentMethod?.trim() ?? '';
  if (value.isEmpty) return 'No definido';

  final normalized = value.toLowerCase();
  if (normalized == 'efectivo' || normalized == 'cash') return 'Efectivo';
  if (normalized.contains('transfer')) return 'Transferencia';
  if (normalized.contains('tarjet')) return 'Tarjeta';
  return value;
}

String invoiceProductPaymentStatusForTrip(Trip trip) {
  final description = trip.description ?? '';
  final match = RegExp(
    r'(?:Estado factura producto|Estado pago producto)\s*:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(description);
  final storedStatus = match?.group(1)?.trim();
  if (storedStatus?.isNotEmpty == true) return storedStatus!;
  return trip.invoiceStatus?.trim() ?? '';
}

bool invoiceProductIsSaleForTrip(Trip trip) {
  final value = _invoiceServiceDescriptionValue(
    trip,
    RegExp(r'Tipo valor producto:\s*([^·]+)', caseSensitive: false),
  );
  return value.isEmpty || !value.toLowerCase().contains('aproximado');
}

String invoiceServicePayerForTrip(Trip trip) {
  final value = _invoiceServiceDescriptionValue(
    trip,
    RegExp(r'Quién paga envío:\s*([^·]+)', caseSensitive: false),
  );
  if (value.toLowerCase().contains('destinat')) return 'Destinatario';
  return 'Remitente / Comercio';
}

class FinalizarViaje extends StatefulWidget {
  const FinalizarViaje({
    super.key,
    required this.trip,
    this.forceTravelLayout = false,
  });

  final Trip trip;
  final bool forceTravelLayout;

  @override
  State<FinalizarViaje> createState() => _FinalizarViajeState();
}

class _FinalizarViajeState extends State<FinalizarViaje> {
  int stars = 0;
  Uint8List? evidencePhoto;
  bool uploadingEvidence = false;

  Future<void> _openInvoice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacturaServicioScreen(
          trip: widget.trip,
          forceTravelLayout: widget.forceTravelLayout,
        ),
      ),
    );
  }

  Future<void> _pickEvidencePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        evidencePhoto = bytes;
        uploadingEvidence = true;
      });

      await apiClient.uploadEvidence(
        bytes,
        image.name.trim().isEmpty ? 'evidencia-entrega.jpg' : image.name,
      );
      if (mounted) setState(() => uploadingEvidence = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => uploadingEvidence = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudo subir la evidencia.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildTaxiCompletion(context);
    // The legacy package layout remains below for reference, but every
    // service now uses the unified Figma completion screen above.
    /*
    final trip = widget.trip;
    final isTaxi = widget.forceTravelLayout || trip.serviceMode == 'Taxi Privado';

    if (isTaxi) return _buildTaxiCompletion(context);

    return Scaffold(
      body: EstadoBackground(
        child: Stack(
          children: [
            // CAPA 1: La mascota gigante en el fondo (detrás de las tarjetas)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/img/mascotaEntrega.png',
                  width: 560,
                  height: 560,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // CAPA 2: Cuadro de información único sobrepuesto sobre la mascota
            Positioned.fill(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 300, 18, 80),
                  children: [
                    AppGlassSurface(
                      borderRadius: 24,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Check Verde
                            const _DeliveryCheck(),
                            const SizedBox(height: 16),

                            // Título
                            Text(
                              isTaxi
                                  ? '¡Viaje terminado!'
                                  : '¡Paquete entregado!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtítulo
                            Text(
                              isTaxi
                                  ? 'Tu pasajero ha llegado a su destino de forma segura y puntual.'
                                  : 'Tu paquete ha llegado a su destino con éxito.\nGracias por usar INCOEX.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.3,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 18),

                            // Destino Final
                            Text(
                              'Destino final',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.destination,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Pill con Icono de Reloj y Hora
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isTaxi
                                        ? 'Viaje hecho hoy, 14:30 hrs'
                                        : 'Entregado hoy, 14:30 hrs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Evidencia
                            InkWell(
                              onTap: _pickEvidencePhoto,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                child: Text(
                                  isTaxi
                                      ? 'Evidencia de viaje'
                                      : 'Evidencia de entrega',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Caja Interna de Calificación
                            AppGlassSurface(
                              borderRadius: 16,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      '¿Cómo fue tu experiencia?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Figtree',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var i = 1; i <= 5; i++)
                                          IconButton(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                setState(() => stars = i),
                                            icon: Icon(
                                              i <= stars
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: i <= stars
                                                  ? Colors.white
                                                  : Colors.white38,
                                              size: 32,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _openInvoice,
                              borderRadius: BorderRadius.circular(16),
                              child: AppGlassSurface(
                                borderRadius: 16,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: const Color(0x331B5DFF),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border:
                                              Border.all(color: glassBorder),
                                        ),
                                        child: const Icon(
                                          Icons.description_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tu factura ya está lista',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Figtree',
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Puedes ver los detalles del servicio y descargarla',
                                              style: TextStyle(
                                                color: Color(0xC9FFFFFF),
                                                fontSize: 10.5,
                                                height: 1.25,
                                                fontFamily: 'Figtree',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: Colors.white, size: 28),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CAPA 3: Botón inferior "Regresar al inicio"
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text(
                    'Regresar al inicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );*/
  }

  String get _completionAsset {
    final transport =
        '${widget.trip.transport ?? ''} ${widget.trip.truckType ?? ''}'
            .toLowerCase();
    if (transport.contains('moto')) {
      return 'assets/img/HomeCliente/figma_moto.png';
    }
    if (transport.contains('camion') ||
        transport.contains('camión') ||
        transport.contains('carga')) {
      final truck = (widget.trip.truckType ?? '').toLowerCase();
      if (truck.contains('grande')) {
        return 'assets/img/HomeCliente/carga_grande.png';
      }
      if (truck.contains('mediano')) {
        return 'assets/img/HomeCliente/carga_mediano.png';
      }
      return 'assets/img/HomeCliente/carga_extra_pequeno.png';
    }
    return 'assets/img/HomeCliente/figma_auto_hd.png';
  }

  bool get _isTravelCompletion =>
      widget.forceTravelLayout || widget.trip.serviceMode == 'Taxi Privado';

  Widget _buildTaxiCompletion(BuildContext context) {
    return Scaffold(
      body: EstadoBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 350,
                child: Center(
                  child: Image.asset(
                    _completionAsset,
                    width: 390,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: AppGlassSurface(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                      child: Column(
                        children: [
                          const _DeliveryCheck(),
                          const SizedBox(height: 16),
                          Text(
                            _isTravelCompletion
                                ? '¡Viaje terminado!'
                                : '¡Envío entregado!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isTravelCompletion
                                ? 'Tu viaje ha llegado a su destino con éxito.'
                                : 'Tu envío ha llegado a su destino con éxito.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xC9FFFFFF),
                              fontSize: 11,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white38, height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            '¿Cómo fue tu experiencia?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 1; i <= 5; i++)
                                IconButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => stars = i),
                                  icon: Icon(
                                    i <= stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: i <= stars ? Colors.white : Colors.white38,
                                    size: 30,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _openInvoice,
                            borderRadius: BorderRadius.circular(16),
                            child: AppGlassSurface(
                              borderRadius: 16,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0x331B5DFF),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: glassBorder),
                                      ),
                                      child: const Icon(Icons.description_outlined,
                                          color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tu factura ya está lista',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'Figtree')),
                                          SizedBox(height: 4),
                                          Text('Puedes ver los detalles del viaje y descargar la factura',
                                              style: TextStyle(
                                                  color: Color(0xC9FFFFFF),
                                                  fontSize: 10.5,
                                                  height: 1.25,
                                                  fontFamily: 'Figtree')),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: Colors.white, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white38, height: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Regresar al inicio',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
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

class FacturaServicioScreen extends StatefulWidget {
  const FacturaServicioScreen({
    super.key,
    required this.trip,
    this.forceTravelLayout = false,
  });

  final Trip trip;
  final bool forceTravelLayout;

  @override
  State<FacturaServicioScreen> createState() => _FacturaServicioScreenState();
}

class _FacturaServicioScreenState extends State<FacturaServicioScreen> {
  Trip get trip => widget.trip;

  bool get _isTaxi => isTripServiceMode(trip.serviceMode);

  String get _serviceTitle => _isTaxi
      ? 'Viaje terminado'
      : trip.transport == 'Camión'
          ? 'Carga entregada'
          : 'Envío entregado';

  String get _vehicleAsset {
    final variant = (trip.vehicleVariant ?? '').toLowerCase();
    final transport =
        '${trip.transport ?? ''} ${trip.serviceMode ?? ''} ${trip.description ?? ''}'
            .toLowerCase();
    if (_isTaxi) {
      if (variant.contains('suv')) return 'assets/img/HomeCliente/taxi_suv.png';
      if (variant.contains('micro') || variant.contains('bus')) {
        return 'assets/img/HomeCliente/taxi_microbus.png';
      }
      if (variant.contains('sed') || variant.contains('sedan')) {
        return 'assets/img/HomeCliente/taxi_sedan.png';
      }
      return 'assets/img/HomeCliente/figma_auto_hd.png';
    }
    if (transport.contains('camion') ||
        transport.contains('camión') ||
        transport.contains('carga')) {
      return 'assets/img/HomeCliente/camion.png';
    }
    if (transport.contains('moto')) return 'assets/img/HomeCliente/figma_moto.png';
    return 'assets/img/HomeCliente/figma_auto_hd.png';
  }

  String get _baseLabel => _isTaxi
      ? 'Tarifa base de viaje'
      : (trip.transport ?? '').toLowerCase().contains('camion')
          ? 'Tarifa base de carga'
          : 'Tarifa base de envío';

  double get _productAmount => trip.invoiceAmountCs ?? 0;

  bool get _productIsPaid {
    final status = invoiceProductPaymentStatusForTrip(trip).toLowerCase();
    return status.contains('pagad') || status == 'paid';
  }

  bool get _productIsSale => invoiceProductIsSaleForTrip(trip);

  double get _clientTotal =>
      _total + (!_productIsSale || _productIsPaid ? 0 : _productAmount);

  String get _invoiceNumber {
    final value = trip.serviceInvoiceNumber?.trim();
    if (value != null && value.isNotEmpty) return value;
    final id = trip.id.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
    return 'FAC-${id.isEmpty ? 'SERVICIO' : id}';
  }

  String get _paymentStatus {
    return invoiceServicePaymentStatusForTrip(trip);
  }

  String get _paymentMethod {
    return invoiceServicePaymentMethodForTrip(trip);
  }

  DateTime get _date =>
      DateTime.tryParse(
        trip.completedAt ?? trip.date,
      ) ??
      DateTime.now();

  String get _dateLabel {
    final date = _date;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute hrs';
  }

  double _optionAmount(TripOptionSelection option) {
    final quantity = option.quantity < 1 ? 1 : option.quantity;
    final unitAmount = option.currency.toUpperCase() == 'USD'
        ? option.priceCs * 36.5
        : option.priceCs;
    return unitAmount * quantity;
  }

  double get _optionsTotal {
    if (trip.optionsTotalCs > 0) return trip.optionsTotalCs;
    return trip.options
        .fold<double>(0, (sum, option) => sum + _optionAmount(option));
  }

  double get _total => trip.quotedServiceTotalCs ?? trip.estimatedCostCs ?? 0;

  double get _baseAmount => trip.quotedBaseCs ??
      (_total - _optionsTotal - (trip.quotedAdditionalCs ?? 0))
          .clamp(0, double.infinity)
          .toDouble();

  double get _additionalAmount {
    final quoted = trip.quotedAdditionalCs;
    if (quoted != null) return quoted;

    // Older trips may have the quoted base and total persisted without the
    // separate distance line. Recover that line from the same invoice math.
    final recovered = _total - _baseAmount - _optionsTotal;
    return recovered > 0 ? recovered : 0;
  }

  Future<void> _downloadInvoice() async {
    final invoiceUrl = trip.serviceInvoiceUrl?.trim();
    if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
      final launched = await launchUrl(
        Uri.parse(invoiceUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la factura.')),
        );
      }
      return;
    }

    final detail = <String>[
      'INCOEX LOGISTICS',
      'Factura de servicio: $_invoiceNumber',
      'Tipo: $_serviceTitle',
      'Destino: ${trip.destination}',
      'Fecha: $_dateLabel',
      'Método de pago: $_paymentMethod',
      'Estado del pago: $_paymentStatus',
      'Quién paga el envío: ${invoiceServicePayerForTrip(trip)}',
      '',
      if (_productAmount > 0)
        '${_productIsSale ? 'Factura del producto' : 'Valor aproximado del producto'}: ${formatFareCs(_productAmount)}${_productIsSale ? ' · ${_productIsPaid ? 'Pagado' : 'Paga destinatario'}' : ''}',
      '$_baseLabel: ${formatFareCs(_baseAmount)}',
      ...trip.options.map((option) =>
          '${option.title}: ${formatFareCs(_optionAmount(option))}'),
      'Subtotal del envío: ${formatFareCs(_total)} · ${invoiceServicePayerForTrip(trip) == 'Destinatario' ? 'Paga destinatario' : 'Paga remitente'}',
      'Total a pagar por el cliente: ${formatFareCs(_clientTotal)}',
    ].join('\n');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar factura del servicio',
      fileName: '$_invoiceNumber.txt',
      bytes: Uint8List.fromList(utf8.encode(detail)),
    );
    if (!mounted || path == null || path.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Factura descargada correctamente.')),
    );
  }

  Widget _infoCard({required Widget child}) => AppGlassSurface(
        borderRadius: 18,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      );

  Widget _amountLine(String label, double amount,
      {bool emphasized = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? Colors.white : const Color(0xD9FFFFFF),
                fontSize: emphasized ? 13 : 11.5,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(
              width: 116,
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            formatFareCs(amount),
            style: TextStyle(
              color: Colors.white,
              fontSize: emphasized ? 16 : 11.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentedValue(String selected, List<String> values) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((value) {
          final active = value.toLowerCase() == selected.toLowerCase();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? accentBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    fontFamily: 'Figtree')),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusIsPaid = {'pagado', 'contado'}.contains(
      _paymentStatus.toLowerCase(),
    );
    final shippingAmount =
        (_total - _optionsTotal).clamp(0, double.infinity).toDouble();
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Detalle del viaje',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _infoCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 72,
                            child: Image.asset(
                              _vehicleAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        color: Color(0xFF1CDB83), size: 9),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        _serviceTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Figtree',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text('Destino final',
                                    style: TextStyle(
                                        color: Color(0xBFFFFFFF),
                                        fontSize: 10,
                                        fontFamily: 'Figtree')),
                                Text(
                                  trip.destination,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(_dateLabel,
                                    style: const TextStyle(
                                        color: Color(0xBFFFFFFF),
                                        fontSize: 9.5,
                                        fontFamily: 'Figtree')),
                                Text('Factura $_invoiceNumber',
                                    style: const TextStyle(
                                        color: Color(0xD9FFFFFF),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Figtree')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles de facturación',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PaymentRow(
                            label: 'Método de pago',
                            trailing: _segmentedValue(
                              _paymentMethod,
                              shipmentPaymentMethodsFor(_paymentStatus),
                            ),
                          ),
                          _PaymentRow(
                            label: 'Moneda',
                            trailing: _segmentedValue('C\$', const ['C\$', 'USD']),
                          ),
                          const Divider(color: Colors.white38, height: 22),
                          if (_productAmount > 0)
                            _amountLine(
                              _productIsSale
                                  ? 'Factura'
                                  : 'Valor aproximado del producto',
                              _productAmount,
                              trailing: _productIsSale
                                  ? _StatusPill(
                                      label: _productIsPaid
                                          ? 'Pagado'
                                          : 'Paga destinatario',
                                      color: _productIsPaid
                                          ? const Color(0xFF1CDB83)
                                          : accentBlue,
                                      textColor: _productIsPaid
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          _amountLine('Tarifa de envío', shippingAmount),
                          ...trip.options.map(
                            (option) => _amountLine(
                              option.quantity == 1
                                  ? option.title
                                  : '${option.title} (x${option.quantity})',
                              _optionAmount(option),
                            ),
                          ),
                          const Divider(color: Colors.white38, height: 18),
                          _amountLine(
                            'Subtotal del envío',
                            _total,
                            trailing: _StatusPill(
                              label: invoiceServicePayerForTrip(trip) ==
                                      'Destinatario'
                                  ? 'Paga destinatario'
                                  : 'Paga remitente',
                              color: accentBlue,
                            ),
                          ),
                          const Divider(color: Colors.white38, height: 18),
                          _amountLine(
                            'Total a pagar por el cliente',
                            _clientTotal,
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _downloadInvoice,
                      borderRadius: BorderRadius.circular(18),
                      child: _infoCard(
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Descargar factura',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Figtree')),
                                  SizedBox(height: 4),
                                  Text(
                                      'Guarda una copia de tu factura del servicio',
                                      style: TextStyle(
                                          color: Color(0xBFFFFFFF),
                                          fontSize: 10.5,
                                          fontFamily: 'Figtree')),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Estado del pago',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Figtree')),
                          ),
                          _StatusPill(
                            label: _paymentStatus,
                            color: statusIsPaid
                                ? const Color(0xFF1CDB83)
                                : const Color(0xFFFFC928),
                            textColor: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.paddingOf(context).bottom + 10,
                ),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Regresar al inicio',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
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

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, this.value, this.trailing})
      : assert(value != null || trailing != null);

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 11.5,
                  fontFamily: 'Figtree')),
          trailing ??
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: glassBorder),
                ),
                child: Text(value!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree')),
              ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, this.textColor});

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree')),
    );
  }
}

class _DeliveryCheck extends StatelessWidget {
  const _DeliveryCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF00D656),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x6600D656),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
    );
  }
}
