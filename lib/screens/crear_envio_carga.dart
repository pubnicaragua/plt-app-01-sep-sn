import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'crear_envio2.dart';

bool shouldShowProductPaymentMethod(String status) =>
    status.trim().toLowerCase() == 'pendiente';

class CrearEnvioCarga extends StatefulWidget {
  const CrearEnvioCarga({
    super.key,
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
    required this.transport,
    this.estimatedShipping,
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
    this.truckType,
    this.truckAsset,
    this.bodyType,
    this.equipment,
  });

  final String origin;
  final String destination;
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
  final String? truckType;
  final String? truckAsset;
  final String? bodyType;
  final String? equipment;

  @override
  State<CrearEnvioCarga> createState() => _CrearEnvioCargaState();
}

class _CrearEnvioCargaState extends State<CrearEnvioCarga> {
  final picker = ImagePicker();
  final photos = <Uint8List>[];
  String packageType = '';
  int weight = 2;
  bool fragile = false;
  late final TextEditingController packageTypeController;
  late final TextEditingController weightController;
  late final TextEditingController invoicePriceController;
  late final TextEditingController invoiceNumberController;
  String currency = 'C\$';
  String productPaymentStatus = 'Pendiente';
  String productPaymentMethod = 'Efectivo';

  @override
  void initState() {
    super.initState();
    packageTypeController = TextEditingController();
    weightController = TextEditingController(text: '$weight');
    invoicePriceController = TextEditingController();
    invoiceNumberController = TextEditingController();
  }

  @override
  void dispose() {
    packageTypeController.dispose();
    weightController.dispose();
    invoicePriceController.dispose();
    invoiceNumberController.dispose();
    super.dispose();
  }

  bool get isTruck => widget.transport == 'Camión';

  String get vehicleLabel => isTruck
      ? 'Camión'
      : widget.transport == 'Moto'
          ? 'Moto'
          : 'Auto';

  String get vehicleAsset => isTruck
      ? 'assets/img/HomeCliente/figma_carga.png'
      : widget.transport == 'Moto'
          ? 'assets/img/HomeCliente/figma_moto.png'
          : 'assets/img/HomeCliente/figma_auto.png';

  Future<void> _pickPhotos() async {
    final selected =
        await picker.pickMultiImage(imageQuality: 84, maxWidth: 1400);
    if (!mounted || selected.isEmpty) return;
    final remaining = 5 - photos.length;
    final bytes = <Uint8List>[];
    for (final file in selected.take(remaining)) {
      bytes.add(await file.readAsBytes());
    }
    if (mounted) setState(() => photos.addAll(bytes));
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearEnvio2(
          origin: widget.origin,
          destination: widget.destination,
          originPlace: widget.originPlace,
          destinationPlace: widget.destinationPlace,
          transport: widget.transport,
          estimatedShipping: widget.estimatedShipping,
          weight: weight,
          bundles: 1,
          packageType: packageTypeController.text.trim(),
          initialProductPhotos: List<Uint8List>.of(photos),
          initialFragile: fragile,
          initialInvoicePrice: invoicePriceController.text.trim(),
          initialInvoiceCurrency: currency,
          initialInvoiceNumber: invoiceNumberController.text.trim(),
          initialProductPaymentStatus: productPaymentStatus,
          initialProductPaymentMethod: productPaymentMethod,
          originRefs: widget.originRefs,
          destinationRefs: widget.destinationRefs,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          startScheduled: widget.startScheduled,
          startDate: widget.startDate,
          startTime: widget.startTime,
          initialTruckType: widget.truckType,
          initialTruckBodyType: widget.bodyType,
          initialTruckEquipment: widget.equipment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    _CargaHeader(
                      title: 'Envíos',
                      onBack: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                    _ShippingVehicleCard(
                      label: widget.truckType ?? vehicleLabel,
                      asset: widget.truckAsset ?? vehicleAsset,
                    ),
                    const SizedBox(height: 16),
                    const _CargaSectionTitle(
                      icon: 'assets/img/HomeCliente/envio_package.png',
                      title: '¿Qué vamos a transportar?',
                      subtitle:
                          'Esta información nos ayudará a preparar correctamente el recojo y despacho',
                    ),
                    const SizedBox(height: 10),
                    _CargaField(
                      icon: 'assets/img/HomeCliente/envio_package.png',
                      label: 'Tipo de paquete',
                      value: '',
                      content: TextField(
                        controller: packageTypeController,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontFamily: 'Figtree'),
                        decoration: const InputDecoration(
                          hintText: 'Escribe qué vas a transportar',
                          hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Figtree'),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => packageType = value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CargaField(
                      icon: 'assets/img/HomeCliente/envio_weight.png',
                      label: 'Peso aproximado',
                      value: '',
                      content: SizedBox(
                        width: 105,
                        child: TextField(
                          controller: weightController,
                          textAlign: TextAlign.left,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontFamily: 'Figtree'),
                          decoration: const InputDecoration(
                            hintText: 'Escribe el peso',
                            hintStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Figtree'),
                            suffixText: 'kg',
                            suffixStyle: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Figtree'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              setState(
                                  () => weight = parsed.clamp(1, 9999).toInt());
                            }
                          },
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SmallAction(
                            icon: Icons.remove,
                            onTap: weight > 1
                                ? () {
                                    final next = weight - 1;
                                    setState(() {
                                      weight = next;
                                      weightController.text = '$next';
                                    });
                                  }
                                : null,
                          ),
                          _SmallAction(
                            icon: Icons.add,
                            onTap: () {
                              final next = (weight + 1).clamp(1, 9999).toInt();
                              setState(() {
                                weight = next;
                                weightController.text = '$next';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _invoiceBlock(),
                    const SizedBox(height: 16),
                    const _CargaSectionTitle(
                      icon: 'assets/img/HomeCliente/envio_photo.png',
                      title: 'Fotos del paquete',
                      subtitle:
                          'Ayúdanos a verificar el espacio y la manipulación',
                    ),
                    const SizedBox(height: 10),
                    _PhotoUploadBox(
                      photos: photos,
                      onTap: _pickPhotos,
                    ),
                    const SizedBox(height: 14),
                    _FragileRow(
                      value: fragile,
                      onChanged: (value) => setState(() => fragile = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassButton(
                  label: 'Siguiente',
                  filled: true,
                  height: 48,
                  fontSize: 14,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceBlock() {
    final showPaymentMethod =
        shouldShowProductPaymentMethod(productPaymentStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estado del producto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            SizedBox(
              width: 132,
              child: _InvoiceSegment(
                options: const ['Pagado', 'Pendiente'],
                value: productPaymentStatus,
                onChanged: (value) => setState(() {
                  productPaymentStatus = value;
                  if (value == 'Pagado') productPaymentMethod = '';
                  if (value == 'Pendiente' &&
                      productPaymentMethod.isEmpty) {
                    productPaymentMethod = 'Efectivo';
                  }
                }),
              ),
            ),
          ],
        ),
        if (showPaymentMethod) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Método de pago',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              SizedBox(
                width: 150,
                child: _InvoiceSegment(
                  options: const ['Efectivo', 'Transferencia'],
                  value: productPaymentMethod,
                  onChanged: (value) =>
                      setState(() => productPaymentMethod = value),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        _InvoiceInputField(
          controller: invoiceNumberController,
          hint: 'Número de factura',
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InvoiceInputField(
                controller: invoicePriceController,
                hint: 'Precio de factura',
                icon: Icons.sell_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: _InvoiceSegment(
                options: const ['C\$', 'USD'],
                value: currency,
                onChanged: (value) => setState(() => currency = value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CargaHeader extends StatelessWidget {
  const _CargaHeader({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree')),
          ),
          const _StepChip(label: 'Paso 2'),
        ],
      );
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree')),
      );
}

class _ShippingVehicleCard extends StatelessWidget {
  const _ShippingVehicleCard({required this.label, required this.asset});
  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 20,
        selected: true,
        fillColor: const Color(0x30284678),
        child: SizedBox(
          height: 214,
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 16,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Seleccionado',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                top: 36,
                bottom: 4,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      );
}

class _CargaSectionTitle extends StatelessWidget {
  const _CargaSectionTitle(
      {required this.icon, required this.title, required this.subtitle});
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      );
}

class _CargaField extends StatelessWidget {
  const _CargaField(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap,
      this.trailing,
      this.content});
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? content;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Image.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      const SizedBox(height: 2),
                      content ??
                          Text(value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      );
}

class _InvoiceInputField extends StatelessWidget {
  const _InvoiceInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 18,
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
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

class _InvoiceSegment extends StatelessWidget {
  const _InvoiceSegment({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
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
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? figmaBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: Colors.white, size: 18),
      );
}

class _PhotoUploadBox extends StatelessWidget {
  const _PhotoUploadBox({required this.photos, required this.onTap});
  final List<Uint8List> photos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 18,
          child: SizedBox(
            height: 126,
            child: photos.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text('Subir fotos del paquete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      SizedBox(height: 3),
                      Text('Formatos soportados: JPG, PNG (Max 5MB)',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontFamily: 'Figtree')),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(photos[index], fit: BoxFit.cover),
                    ),
                  ),
          ),
        ),
      );
}

class _FragileRow extends StatelessWidget {
  const _FragileRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset('assets/img/HomeCliente/carga_fragil.png',
              width: 22, height: 22, fit: BoxFit.contain),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿El producto es frágil?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                SizedBox(height: 2),
                Text('Nos ayudará a manipularlo correctamente.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                _FragileChoice(
                  label: 'No',
                  selected: !value,
                  onTap: () => onChanged(false),
                ),
                _FragileChoice(
                  label: 'Sí',
                  selected: value,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ),
        ],
      );
}

class _FragileChoice extends StatelessWidget {
  const _FragileChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
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
