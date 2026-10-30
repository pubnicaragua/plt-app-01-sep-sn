import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:incoex_logistics_app/widgets/glass.dart';

import '../core/api_client.dart';
import '../core/driver_payment_summary.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import 'confirmar_entrega.dart';

const _blue = Color(0xFF0D47D9);
const _navy = Color(0xFF0D1F52);
const _muted = Color(0xFFB9D4FF);
const _mint = Color(0xFF1CDB83);

bool _paymentIsComplete(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized == 'pagado' ||
      normalized == 'verificado' ||
      normalized == 'aprobado' ||
      normalized == 'contado';
}

String _paymentMethodFor(Trip trip) {
  final value = (trip.servicePaymentMethod ?? trip.paymentMethod ?? '').trim();
  if (value.isEmpty) return 'Efectivo';
  final normalized = value.toLowerCase();
  if (normalized == 'cash') return 'Efectivo';
  if (normalized.contains('transfer')) return 'Transferencia';
  if (normalized.contains('tarjet') || normalized.contains('pocket')) {
    return 'Tarjeta / link de pago';
  }
  return value;
}

class PagoViaje extends StatefulWidget {
  const PagoViaje({super.key, required this.trip});

  final Trip trip;

  @override
  State<PagoViaje> createState() => _PagoViajeState();
}

class _PagoViajeState extends State<PagoViaje> {
  bool saving = false;
  bool uploading = false;
  String? evidenceName;
  Uint8List? evidencePreview;
  bool productCollected = false;

  Trip get trip => widget.trip;
  String get method => _paymentMethodFor(trip);
  String get status =>
      trip.servicePaymentStatus ?? trip.paymentStatus ?? 'Sin pagar';
  double get total => trip.estimatedCostCs ?? 0;
  bool get complete => _paymentIsComplete(status);
  DriverPaymentSummary get paymentSummary => driverPaymentSummaryFor(trip);
  bool get productSettled =>
      productCollected || !paymentSummary.productNeedsCollection;
  bool get allPaymentsComplete => complete && productSettled;
  bool get bypassEnabled =>
      kDebugMode ||
      const bool.fromEnvironment('INCOEX_PAYMENT_BYPASS', defaultValue: false);

  Future<void> _registerCash() async {
    await _savePayment(
      method: 'Efectivo',
      status: 'Pagado',
      amount: total,
      ref: 'EFECTIVO-${DateTime.now().millisecondsSinceEpoch}',
      collectProduct: paymentSummary.productNeedsCollection,
    );
  }

  Future<void> _pickTransferEvidence() async {
    if (uploading || saving) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        evidencePreview = bytes;
        uploading = true;
      });
      final uploaded = await apiClient.uploadEvidence(
        bytes,
        image.name,
        tripId: trip.id,
        type: 'payment_receipt',
      );
      if (!mounted) return;
      setState(() {
        evidenceName = uploaded['evidence']?.toString();
        uploading = false;
      });
      await _savePayment(
        method: 'Transferencia',
        status: 'Pendiente de revisión',
        amount: 0,
        ref: evidenceName,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => uploading = false);
      _showError(error);
    }
  }

  Future<void> _useLocalBypass() async {
    await _savePayment(
      method: method == 'Efectivo' ? 'Tarjeta' : method,
      status: 'Pagado',
      amount: total,
      ref: 'BYPASS_LOCAL_PAYMENT',
      collectProduct: paymentSummary.productNeedsCollection,
    );
  }

  Future<void> _savePayment({
    required String method,
    required String status,
    required double amount,
    String? ref,
    bool collectProduct = false,
  }) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final updated = await apiClient.updateTripPayment(
        id: trip.id,
        method: method,
        amount: amount,
        ref: ref,
        status: status,
      );
      if (!mounted) return;
      if (collectProduct) productCollected = true;
      final serviceComplete = _paymentIsComplete(
          updated.paymentStatus ?? updated.servicePaymentStatus);
      if (serviceComplete && (productCollected || !paymentSummary.productNeedsCollection)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ConfirmarEntrega(
              trip: updated,
              productCollected: productCollected,
            ),
          ),
        );
        return;
      }
      setState(() => saving = false);
      _showMessage('Comprobante enviado. Esperando validación administrativa.');
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        _showError(error);
      }
    }
  }

  void _continueIfComplete() {
    if (!complete) {
      _showMessage('Aún falta confirmar el pago del servicio.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmarEntrega(
          trip: trip,
          productCollected: productCollected,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _showError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'No se pudo actualizar el pago. Verifica tu conexión.';
    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = method == 'Transferencia';
    final isCash = method == 'Efectivo';
    final payment = paymentSummary;
    final productCashPending = payment.productNeedsCollection &&
        payment.productMethod == 'Efectivo';
    final cashToCollect = isCash || productCashPending;
    final awaitingReview = status.toLowerCase().contains('revisión') ||
        status.toLowerCase().contains('revision');

    return Scaffold(
      backgroundColor: _navy,
      bottomNavigationBar: complete
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: _PrimaryButton(
                  label: 'Continuar a completar entrega',
                  loading: false,
                  onTap: _continueIfComplete,
                ),
              ),
            )
          : null,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Pago del servicio',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const Text(
                      'ANTES DE COMPLETAR LA ENTREGA',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Revisa el método de pago',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Viaje ${trip.id} · ${trip.destination}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PaymentSummary(
                      payment: payment,
                      productSettled: productSettled,
                    ),
                    const SizedBox(height: 18),
                    if (allPaymentsComplete)
                      _InfoPanel(
                        icon: Icons.verified_rounded,
                        color: _mint,
                        title: 'Pago verificado',
                        text:
                            'Puedes continuar con la evidencia y el cierre de la entrega.',
                      )
                    else if (awaitingReview)
                      _InfoPanel(
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFFFC928),
                        title: 'Comprobante pendiente de revisión',
                        text:
                            'El panel administrativo debe validar el comprobante antes de cerrar el viaje.',
                      )
                    else
                      _InfoPanel(
                        icon: Icons.info_outline_rounded,
                        color: cyan,
                        title: cashToCollect
                            ? 'Confirma el efectivo recibido'
                            : isTransfer
                                ? 'Adjunta el comprobante'
                                : 'El pago lo realiza el cliente',
                        text: cashToCollect
                            ? 'Registra el efectivo del servicio o del producto pendiente antes de continuar.'
                            : isTransfer
                                ? 'Toma una foto clara del comprobante de transferencia.'
                                : 'El conductor solo consulta el estado; no inicia la pasarela de pago.',
                      ),
                    if (isTransfer && evidencePreview != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(evidencePreview!,
                            height: 170, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!complete && cashToCollect)
                      _PrimaryButton(
                          label: payment.productNeedsCollection && complete
                              ? 'Marcar producto recibido'
                              : 'Marcar efectivo recibido',
                          loading: saving,
                          onTap: _registerCash)
                    else if (!complete && isTransfer)
                      _PrimaryButton(
                        label: uploading
                            ? 'Subiendo comprobante…'
                            : evidenceName == null
                                ? 'Tomar comprobante'
                                : 'Reenviar comprobante',
                        loading: uploading || saving,
                        onTap: _pickTransferEvidence,
                      )
                    else if (!complete)
                      _PrimaryButton(
                        label: 'Esperar confirmación del pago',
                        loading: false,
                        onTap: () => _showMessage(
                            'El cliente debe completar el pago antes de continuar.'),
                      ),
                    if (bypassEnabled && !allPaymentsComplete) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: saving || uploading ? null : _useLocalBypass,
                        icon: const Icon(Icons.science_outlined, size: 17),
                        label:
                            const Text('Bypass local: aprobar pago de prueba'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _muted,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: .24)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          textStyle: const TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'El estado queda guardado en el viaje y es visible para operaciones.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _muted, fontSize: 11, fontFamily: 'Figtree'),
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

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.payment, required this.productSettled});

  final DriverPaymentSummary payment;
  final bool productSettled;

  @override
  Widget build(BuildContext context) {
    final paid = payment.servicePaid;
    return ShowcaseGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.payments_outlined, color: cyan),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pago del servicio',
                        style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontFamily: 'Figtree')),
                    const SizedBox(height: 3),
                    Text(payment.serviceMethod,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                  ],
                ),
              ),
              Icon(paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: paid ? _mint : const Color(0xFFFFC928)),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: .13), height: 1),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total del servicio',
                  style: TextStyle(
                      color: _muted, fontSize: 12, fontFamily: 'Figtree')),
              Text(formatFareCs(payment.serviceAmount),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estado actual',
                  style: TextStyle(
                      color: _muted, fontSize: 12, fontFamily: 'Figtree')),
              Text(paid ? 'Pagado' : 'Pendiente',
                  style: TextStyle(
                      color: paid ? _mint : const Color(0xFFFFC928),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
            ],
          ),
          if (payment.productAmount > 0) ...[
            const SizedBox(height: 15),
            Divider(color: Colors.white.withValues(alpha: .13), height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_outlined, color: cyan, size: 22),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Producto / factura',
                          style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontFamily: 'Figtree')),
                      const SizedBox(height: 3),
                      Text(payment.productMethod,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatFareCs(payment.productAmount),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                    const SizedBox(height: 3),
                    Text(productSettled ? 'Pagado / recibido' : 'Pendiente',
                        style: TextStyle(
                            color: productSettled
                                ? _mint
                                : const Color(0xFFFFC928),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                  ],
                ),
              ],
            ),
          ],
          if (payment.recipientPays) ...[
            const SizedBox(height: 13),
            Text('Paga el destinatario · efectivo',
                style: const TextStyle(
                    color: _muted, fontSize: 11, fontFamily: 'Figtree')),
          ],
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel(
      {required this.icon,
      required this.color,
      required this.title,
      required this.text});

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        height: 1.35,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.loading, required this.onTap});

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Material(
        color: loading ? const Color(0xFF0B3DBB) : _blue,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
          ),
        ),
      ),
    );
  }
}
