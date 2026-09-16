import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
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
  late final TextEditingController description;
  late final TextEditingController invoicePrice;
  late final TextEditingController invoiceNumber;
  String currency = 'C\$';
  bool fragile = true;
  String paymentStatus = 'Pendiente';
  String paymentMethod = 'Efectivo';
  final productPhotos = <Uint8List>[];
  Uint8List? invoicePhoto;
  AppSettings? settings;

  @override
  void initState() {
    super.initState();
    weight = widget.weight.clamp(1, 1500).toInt();
    weightUnit = widget.weightUnit == 'lb' ? 'lb' : 'kg';
    bundles = widget.bundles.clamp(1, 99).toInt();
    description = TextEditingController();
    invoicePrice = TextEditingController(text: '0,00');
    invoiceNumber = TextEditingController(text: 'FAC-1003');
    apiClient.getSettings().then((value) {
      if (mounted) setState(() => settings = value);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    description.dispose();
    invoicePrice.dispose();
    invoiceNumber.dispose();
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

  Future<void> _pickImage({required bool invoice, required ImageSource source}) async {
    if (!invoice && productPhotos.length >= 5) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la imagen.')),
      );
    }
  }

  Future<void> _chooseProductSource() =>
      _pickImage(invoice: false, source: ImageSource.gallery);

  Future<void> _chooseInvoiceSource() =>
      _pickImage(invoice: true, source: ImageSource.gallery);

  void _continue() {
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
          description: description.text.trim(),
          fragile: fragile,
          invoiceNumber: invoiceNumber.text.trim(),
          invoiceAmount: invoiceAmountCs,
          paymentStatus: paymentStatus,
          paymentMethod: paymentMethod,
          productPhotos: List<Uint8List>.of(productPhotos),
          invoicePhoto: invoicePhoto,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          serviceType: widget.startScheduled ? 'Programado' : 'Express',
          scheduledDate: widget.startDate,
          scheduledTime: widget.startTime,
          isScheduled: widget.startScheduled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Detalles de carga',
      subtitle: '¿Qué tipo de carga enviarás?',
      description:
          'Indica las características de tu carga y te recomendaremos el transporte adecuado.',
      step: 1,
      totalSteps: 3,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeightCard(
            weight: weight,
            unit: weightUnit,
            bundles: bundles,
            onUnitChanged: _setUnit,
            onWeightChanged: (value) => setState(() => weight = value.clamp(1, 1500).toInt()),
            onBundlesChanged: (value) => setState(() => bundles = value.clamp(1, 99).toInt()),
          ),
          const SizedBox(height: 14),
          _packageCard(),
          const SizedBox(height: 14),
          _productPhotosCard(),
          const SizedBox(height: 14),
          _invoiceCard(),
          const SizedBox(height: 14),
          _paymentCard(),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Siguiente',
            filled: true,
            textColor: Colors.white,
            onPressed: _continue,
          ),
        ],
      ),
    );
  }

  Widget _packageCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.shopping_bag_outlined,
            title: 'Información del paquete',
            badge: 'Paso 2',
          ),
          const SizedBox(height: 20),
          _fieldCaption('DESCRIPCIÓN DEL PAQUETE'),
          const SizedBox(height: 8),
          GlassField(
            label: 'Descripción',
            hint: 'Ej: Electrónicos, ropa, documentos...',
            controller: description,
            showFloatingLabel: false,
          ),
          const SizedBox(height: 17),
          _fieldCaption('PRECIO DE FACTURA'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GlassField(
                  label: 'Precio de factura',
                  hint: '0,00',
                  controller: invoicePrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 17),
          _fieldCaption('NÚMERO DE FACTURA'),
          const SizedBox(height: 8),
          GlassField(
            label: 'Número de factura',
            hint: 'FAC-1003',
            controller: invoiceNumber,
            showFloatingLabel: false,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glassBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5C63), size: 22),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Carga frágil?', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                      Text('Requiere manejo especial', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 11, fontFamily: 'Acumin Pro')),
                    ],
                  ),
                ),
                Text(fragile ? 'SÍ' : 'NO', style: const TextStyle(color: cyan, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                const SizedBox(width: 4),
                Switch.adaptive(
                  value: fragile,
                  onChanged: (value) => setState(() => fragile = value),
                  activeTrackColor: cyan,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPhotosCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldCaption('FOTOS DEL PAQUETE'),
          const SizedBox(height: 10),
          const Text(
            'Toma una foto clara o sube un archivo',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 11,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 8),
          _UploadTile(
            icon: Icons.photo_camera_outlined,
            title: 'Tomar foto',
            subtitle: 'Formatos soportados: JPG, PNG (Max 5MB)',
            onTap: () => _pickImage(invoice: false, source: ImageSource.camera),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final photo in productPhotos)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(photo, width: 64, height: 64, fit: BoxFit.cover),
                ),
              GestureDetector(
                onTap: productPhotos.length >= 5 ? null : _chooseProductSource,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: glassBorder),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          TextButton.icon(
            onPressed: productPhotos.length >= 5 ? null : _chooseProductSource,
            icon: const Icon(Icons.photo_library_outlined, color: cyan, size: 17),
            label: const Text('Seleccionar de galería', style: TextStyle(color: cyan, decoration: TextDecoration.underline, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
          ),
        ],
      ),
    );
  }

  Widget _invoiceCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldCaption('FACTURA DEL PRODUCTO'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickImage(invoice: true, source: ImageSource.camera),
            child: Container(
              height: 138,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: glassBorder),
              ),
              child: invoicePhoto == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined, color: cyan, size: 29),
                        SizedBox(height: 10),
                        Text('Toca para tomar foto de la factura', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(invoicePhoto!, fit: BoxFit.cover),
                    ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _chooseInvoiceSource,
              child: const Text('Seleccionar de galería', style: TextStyle(color: cyan, decoration: TextDecoration.underline, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESTADO DEL PAGO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _PaymentChoice(label: 'Pendiente', selected: paymentStatus == 'Pendiente', onTap: () => setState(() => paymentStatus = 'Pendiente'))),
              const SizedBox(width: 9),
              Expanded(child: _PaymentChoice(label: 'Pagado', selected: paymentStatus == 'Pagado', onTap: () => setState(() => paymentStatus = 'Pagado'))),
            ],
          ),
          const SizedBox(height: 19),
          const Text('Método de pago', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _PaymentChoice(label: 'Efectivo', icon: Icons.payments_outlined, selected: paymentMethod == 'Efectivo', onTap: () => setState(() => paymentMethod = 'Efectivo'))),
              const SizedBox(width: 9),
              Expanded(child: _PaymentChoice(label: 'Transferencia', icon: Icons.account_balance_outlined, selected: paymentMethod == 'Transferencia', onTap: () => setState(() => paymentMethod = 'Transferencia'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldCaption(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFFB9D4FF),
        fontSize: 10.5,
        letterSpacing: .7,
        fontWeight: FontWeight.w800,
        fontFamily: 'Acumin Pro',
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.icon, required this.title, required this.badge});

  final IconData icon;
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: cyan, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(color: cyan, borderRadius: BorderRadius.circular(18)),
          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
        ),
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.weight,
    required this.unit,
    required this.bundles,
    required this.onUnitChanged,
    required this.onWeightChanged,
    required this.onBundlesChanged,
  });

  final int weight;
  final String unit;
  final int bundles;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<int> onBundlesChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(icon: Icons.inventory_2_outlined, title: 'Peso y dimensiones', badge: 'Paso 1'),
          const SizedBox(height: 7),
          const Text('Para calcular el transporte adecuado', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 12, fontFamily: 'Acumin Pro')),
          const SizedBox(height: 19),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peso aproximado de la carga', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
              Text('Límite hasta 1,500 kg', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
            ],
          ),
          const SizedBox(height: 10),
          _counter(
            value: '$weight $unit',
            onMinus: weight > 1 ? () => onWeightChanged(weight - 1) : null,
            onPlus: weight < 1500 ? () => onWeightChanged(weight + 1) : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Unidad:', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 11, fontFamily: 'Acumin Pro')),
              const SizedBox(width: 9),
              for (final option in ['kg', 'lb']) ...[
                _SmallChoice(label: option.toUpperCase(), selected: unit == option, onTap: () => onUnitChanged(option)),
                const SizedBox(width: 7),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text('Atajos:', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 11, fontFamily: 'Acumin Pro')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 15, 45, 405].map((value) {
              final converted = unit == 'lb' ? (value * 2.20462).round() : value;
              return _SmallChoice(label: '$converted $unit', selected: weight == converted, onTap: () => onWeightChanged(converted));
            }).toList(),
          ),
          const SizedBox(height: 19),
          const Text('Cantidad de bultos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
          const SizedBox(height: 10),
          _counter(
            value: '$bundles Bulto${bundles == 1 ? '' : 's'}',
            onMinus: bundles > 1 ? () => onBundlesChanged(bundles - 1) : null,
            onPlus: bundles < 99 ? () => onBundlesChanged(bundles + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _counter({required String value, required VoidCallback? onMinus, required VoidCallback? onPlus}) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundControl(icon: Icons.remove_rounded, onTap: onMinus),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
          _RoundControl(icon: Icons.add_rounded, onTap: onPlus, filled: true),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? cyan : Colors.white.withValues(alpha: .12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white, size: 27),
        ),
      ),
    );
  }
}

class _SmallChoice extends StatelessWidget {
  const _SmallChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? figmaBlue : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? cyan : glassBorder),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 124,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cyan, size: 28),
            const SizedBox(height: 9),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFFB9D4FF), fontSize: 11, fontFamily: 'Acumin Pro')),
          ],
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
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(color: selected ? cyan : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFFB9D4FF), fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({required this.label, required this.selected, required this.onTap, this.icon});

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
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cyan : Colors.white.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? cyan : glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(height: 3)],
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
          ],
        ),
      ),
    );
  }
}
