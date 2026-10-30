import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/driver_payment_summary.dart';
import '../core/trip_routing.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/incident_sheet.dart';
import 'home_conductor.dart';

class ConfirmarEntrega extends StatefulWidget {
  const ConfirmarEntrega({
    super.key,
    required this.trip,
    this.productCollected = false,
  });

  final Trip trip;
  final bool productCollected;

  @override
  State<ConfirmarEntrega> createState() => _ConfirmarEntregaState();
}

class _ConfirmarEntregaState extends State<ConfirmarEntrega> {
  String picked = 'Entregado con éxito';
  bool updating = false;

  Future<String?> _askForDeliveryCode() async {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF172F70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Validación final',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicita al cliente el código de seguimiento de este viaje e introdúcelo para completar la entrega.',
              style: TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 12,
                height: 1.35,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Código de entrega',
              style: TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var index = 0; index < controllers.length; index++) ...[
                  Expanded(
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.text,
                      maxLength: 1,
                      onChanged: (value) {
                        setDialogState(() {});
                        if (value.isNotEmpty && index < controllers.length - 1) {
                          focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .06),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF168DFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF168DFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF52C7FF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index < controllers.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar',
                style:
                    TextStyle(color: Color(0xFFB9D4FF), fontFamily: 'Figtree')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controllers.map((controller) => controller.text).join(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D47D9),
              foregroundColor: Colors.white,
            ),
            child: const Text('Validar',
                style: TextStyle(
                    fontFamily: 'Figtree', fontWeight: FontWeight.w800)),
          ),
        ],
        ),
      ),
    );
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    return result;
  }

  String _normalizeCode(String value) =>
      value.trim().replaceFirst(RegExp(r'^#'), '').toLowerCase();

  Future<void> _submit() async {
    if (updating) return;
    if (widget.trip.status != 'En entrega') {
      setState(() => updating = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Este viaje está en estado «${widget.trip.status}»; no se puede confirmar la entrega. Refresca.',
            style: const TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      setState(() => updating = false);
      return;
    }
    if (picked == 'Entregado con éxito') {
      final payments = driverPaymentSummaryFor(widget.trip);
      final productSettled =
          widget.productCollected || !payments.productNeedsCollection;
      if (!payments.servicePaid || !productSettled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Primero debes confirmar todos los pagos pendientes del viaje.',
              style: TextStyle(fontFamily: 'Figtree'),
            ),
          ),
        );
        return;
      }
      final deliveryCode = await _askForDeliveryCode();
      if (!mounted || deliveryCode == null) return;
      if (_normalizeCode(deliveryCode) != _normalizeCode(widget.trip.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'El código no coincide con este viaje. Pídeselo nuevamente al cliente.',
              style: TextStyle(fontFamily: 'Figtree'),
            ),
          ),
        );
        return;
      }
      setState(() => updating = true);
      try {
        await apiClient.updateTripStatus(
          widget.trip.id,
          'Completado',
          deliveryCode: deliveryCode,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeConductor()),
          (route) => false,
        );
      } catch (error) {
        if (mounted) {
          setState(() => updating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                error is ApiException
                    ? error.message
                    : 'No se pudo confirmar la entrega. Verifica tu conexión.',
                style: const TextStyle(fontFamily: 'Figtree'),
              ),
            ),
          );
        }
      }
      return;
    }
    setState(() => updating = true);
    try {
      if (picked == 'No entregado') {
        final incident = await showIncidentSheet(
          context,
          tripId: widget.trip.id,
          driverName: widget.trip.driver,
          clientName: widget.trip.client,
        );
        if (!mounted) return;
        if (incident == null) {
          setState(() => updating = false);
          return;
        }
      }
      await apiClient.updateTripStatus(widget.trip.id, 'Cancelado');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeConductor()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() => updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No se pudo confirmar la entrega. Verifica tu conexión.',
              style: const TextStyle(fontFamily: 'Figtree'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final packageValue = trip.invoiceAmountCs ?? 0;
    final payment = driverPaymentSummaryFor(trip);
    final productStatus = RegExp(
      r'(?:Estado factura producto|Estado pago producto):\s*([^·]+)',
      caseSensitive: false,
    ).firstMatch(trip.description ?? '')?.group(1)?.trim().toLowerCase();
    final productIsPaid = widget.productCollected ||
        productStatus?.contains('pagad') == true ||
        productStatus == 'contado' ||
        productStatus?.contains('verificad') == true ||
        productStatus?.contains('aprob') == true;
    final productIsApproximate = RegExp(
          r'Tipo valor producto:\s*([^·]+)',
          caseSensitive: false,
        ).firstMatch(trip.description ?? '')?.group(1)?.toLowerCase().contains(
              'aproximado',
            ) ==
        true;
    final totalToCollect = (payment.servicePaid ? 0.0 : payment.serviceAmount) +
        (productIsPaid || productIsApproximate ? 0.0 : packageValue);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F52),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Confirmar Entrega',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B6DF5).withValues(alpha: .30),
                            const Color(0xFF3B6DF5).withValues(alpha: .12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0x553B6DF5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B6DF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Llegaste al destino de entrega',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isTripServiceMode(trip.serviceMode)
                                      ? 'Detalles del viaje'
                                      : 'Detalles del envío',
                                  style: TextStyle(
                                    color: Color(0xFF10224A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7EEFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Viaje ${trip.id}',
                                  style: const TextStyle(
                                    color: Color(0xFF0D47D9),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(color: Color(0x2210224A), height: 1),
                          const SizedBox(height: 13),
                          _DetailRow(
                            icon: Icons.person_rounded,
                            label: 'Cliente',
                            value: trip.recipientName ??
                                trip.contactName ??
                                'Cliente',
                          ),
                          const SizedBox(height: 15),
                          _DetailRow(
                            icon: Icons.near_me_rounded,
                            label: 'Dirección de entrega',
                            value: trip.destination,
                          ),
                          const SizedBox(height: 15),
                          _DetailRow(
                            icon: Icons.inventory_2_rounded,
                            label: 'Paquetes',
                            value:
                                '${trip.packages} unidad${trip.packages == 1 ? '' : 'es'} certificada${trip.packages == 1 ? '' : 's'}',
                          ),
                          if (trip.estimatedCostCs != null) ...[
                            const SizedBox(height: 15),
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Precio del viaje',
                              value: formatFareCs(trip.estimatedCostCs!),
                            ),
                            const SizedBox(height: 15),
                            _DetailRow(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Costo de los productos',
                              value: packageValue > 0
                                  ? '${formatFareCs(packageValue)} (valor del paquete)'
                                  : 'Sin valor registrado',
                            ),
                            const SizedBox(height: 15),
                            _DetailRow(
                              icon: Icons.receipt_long_outlined,
                              label: 'Total a cobrar al destinatario',
                              value: formatFareCs(totalToCollect),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Evidencia de entrega: foto + firma
                    _EvidenceDelivery(tripId: trip.id),
                    const SizedBox(height: 20),
                    const Text(
                      '¿Se realizó la entrega?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionButton(
                            label: 'Entregado con éxito',
                            picked: picked == 'Entregado con éxito',
                            filled: true,
                            onTap: () =>
                                setState(() => picked = 'Entregado con éxito'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OptionButton(
                            label: 'No entregado',
                            picked: picked == 'No entregado',
                            filled: false,
                            onTap: () =>
                                setState(() => picked = 'No entregado'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: Material(
                        color: updating
                            ? const Color(0xFF0B3DBB)
                            : const Color(0xFF0D47D9),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _submit,
                          child: Center(
                            child: updating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Registrar entrega',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        picked == 'Entregado con éxito'
                            ? 'El viaje pasará a tu historial de completados.'
                            : 'El viaje se marcará como cancelado.',
                        style: const TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 11,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D47D9), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A87A8),
                  fontSize: 10.5,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF10224A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.picked,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool picked;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        picked ? const Color(0xFF0D47D9) : const Color(0xFFD7DCE8);
    final bg = picked
        ? filled
            ? const Color(0xFFE7EEFF)
            : const Color(0xFFEFEFF3)
        : const Color(0xFFF5F6F9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filled ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: const Color(0xFF0D47D9),
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0D47D9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceDelivery extends StatefulWidget {
  const _EvidenceDelivery({required this.tripId});

  final String tripId;

  @override
  State<_EvidenceDelivery> createState() => _EvidenceDeliveryState();
}

class _EvidenceDeliveryState extends State<_EvidenceDelivery> {
  Uint8List? photo;
  String? photoName;
  bool uploading = false;

  Future<void> _pickPhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        photo = bytes;
        photoName = image.name;
        uploading = true;
      });
      final uploaded = await apiClient.uploadEvidence(
        photo!,
        photoName ?? 'entrega.jpg',
        tripId: widget.tripId,
        type: 'delivery',
      );
      if (!mounted) return;
      setState(() {
        photoName = uploaded['evidence']?.toString() ?? photoName;
        uploading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => uploading = false);
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
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: mint, size: 19),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Evidencia de entrega',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.tripId,
                  style: const TextStyle(
                    color: mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Toma una foto del paquete entregado para respaldar la entrega.',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 11,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickPhoto,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: photo == null
                    ? Colors.white.withValues(alpha: .06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      photo == null ? glassBorder : mint.withValues(alpha: .5),
                ),
              ),
              child: photo == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: Colors.white70, size: 26),
                          const SizedBox(height: 7),
                          const Text(
                            'Tomar foto de la evidencia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(photo!, fit: BoxFit.cover),
                          if (uploading)
                            Container(
                              color: Colors.black.withValues(alpha: .4),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          else
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Adjuntada',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Figtree',
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
          ),
        ],
      ),
    );
  }
}
