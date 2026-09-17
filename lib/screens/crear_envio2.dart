import 'dart:typed_data';
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
  String invoiceFileName = 'factura.jpg';
  AppSettings? settings;

  @override
  void initState() {
    super.initState();
    weight = widget.weight.clamp(1, 1500).toInt();
    weightUnit = widget.weightUnit == 'lb' ? 'lb' : 'kg';
    bundles = widget.bundles.clamp(1, 99).toInt();
    description = TextEditingController();
    invoicePrice = TextEditingController();
    invoiceNumber = TextEditingController();
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
          invoiceFileName: invoiceFileName,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        darken: 0,
        backgroundLogoOpacity: .86,
        backgroundLogoOffsetY: -58,
        backgroundLogoScale: 1.08,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              _PageHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 28),
              const _PageSectionTitle(
                title: 'Peso y dimensiones',
                subtitle: 'Para calcular el transporte adecuado',
              ),
              const SizedBox(height: 12),
              _dimensionBlock(),
              const SizedBox(height: 27),
              const _PageSectionTitle(title: 'Detalles de envío'),
              const SizedBox(height: 14),
              _detailsBlock(),
              const SizedBox(height: 28),
              const _PageSectionTitle(
                title: '¿Qué tipo de carga enviarás?',
                subtitle:
                    'Indica las características de tu carga y te recomendaremos el transporte adecuado.',
              ),
              const SizedBox(height: 17),
              _fragileBlock(),
              const SizedBox(height: 14),
              _productPhotosBlock(),
              const SizedBox(height: 18),
              _paymentBlock(),
              const SizedBox(height: 26),
              GlassButton(
                label: 'Siguiente',
                filled: true,
                textColor: Colors.white,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
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
                fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
        const Text(
          '¿Carga frágil?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Acumin Pro',
          ),
        ),
        _BinaryToggle(
          value: fragile,
          first: 'Sí',
          second: 'No',
          onChanged: (value) => setState(() => fragile = value),
        ),
      ],
    );
  }

  Widget _productPhotosBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionUploadCard(
          icon: Icons.photo_library_outlined,
          title: 'Subir fotos del paquete',
          subtitle: 'Formatos soportados: JPG, PNG (Max 5MB)',
          onTap: () => _pickImage(invoice: false, source: ImageSource.camera),
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
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: productPhotos.length >= 5 ? null : _chooseProductSource,
            icon: const Icon(Icons.photo_library_outlined,
                color: Colors.white, size: 18),
            label: const Text(
              'Seleccionar de galería',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
        ),
      ],
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
                fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBack});

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
        const Expanded(
          child: Text(
            'Detalles de carga',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
        const _StepPill(text: 'Paso 2'),
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
          fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
              fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
            fontFamily: 'Acumin Pro',
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
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Acumin Pro',
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
                    fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
