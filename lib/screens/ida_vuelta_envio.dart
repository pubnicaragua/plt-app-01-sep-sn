import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';
import 'ida_vuelta.dart';

class IdaVueltaEnvioScreen extends StatefulWidget {
  const IdaVueltaEnvioScreen({
    super.key,
    required this.transport,
    this.initialConfig,
  });

  final String transport;
  final IdaVueltaConfig? initialConfig;

  @override
  State<IdaVueltaEnvioScreen> createState() => _IdaVueltaEnvioScreenState();
}

class _IdaVueltaEnvioScreenState extends State<IdaVueltaEnvioScreen> {
  final picker = ImagePicker();
  late String packageType;
  late int weight;
  late TimeOfDay returnTime;
  late ReturnWaitMode waitMode;
  late bool fragile;
  final photos = <Uint8List>[];

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    packageType = config?.returnPackageType ?? 'Ropa y artículos personales';
    weight = config?.returnWeight ?? 2;
    returnTime = config?.returnTime ?? const TimeOfDay(hour: 18, minute: 0);
    waitMode = config?.waitMode ?? ReturnWaitMode.scheduledReturn;
    fragile = config?.returnFragile ?? false;
    photos.addAll(config?.returnPhotos ?? const []);
  }

  Future<void> _pickPhotos() async {
    final selected =
        await picker.pickMultiImage(imageQuality: 84, maxWidth: 1400);
    if (!mounted || selected.isEmpty) return;
    for (final file in selected.take(5 - photos.length)) {
      photos.add(await file.readAsBytes());
    }
    if (mounted) setState(() {});
  }

  void _save() => Navigator.of(context).pop(
        IdaVueltaConfig(
          passengerCount: 1,
          returnTime: returnTime,
          waitMode: waitMode,
          returnTransport: widget.transport,
          returnPackageType: packageType,
          returnWeight: weight,
          returnPhotos: List<Uint8List>.of(photos),
          returnFragile: fragile,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        darken: .04,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 19),
                        ),
                        const Expanded(
                          child: Text('Servicios adicionales',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Figtree')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ReturnHeader(),
                    const SizedBox(height: 16),
                    _ReturnField(
                      icon: 'assets/img/HomeCliente/envio_package.png',
                      label: '¿Qué vamos a transportar devuelta?',
                      value: packageType,
                      onTap: _choosePackageType,
                    ),
                    const SizedBox(height: 8),
                    _ReturnField(
                      icon: 'assets/img/HomeCliente/envio_weight.png',
                      label: 'Peso aproximado',
                      value: '$weight kg',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: weight > 1
                                ? () => setState(() => weight--)
                                : null,
                            icon: const Icon(Icons.remove, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () => setState(() => weight++),
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Image.asset('assets/img/HomeCliente/envio_photo.png',
                            width: 19, height: 19),
                        const SizedBox(width: 7),
                        const Text('Fotos del cargamento',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree')),
                      ],
                    ),
                    const SizedBox(height: 7),
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: AppGlassSurface(
                        borderRadius: 17,
                        child: SizedBox(
                          height: 106,
                          child: photos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                          'assets/img/HomeCliente/subir_fotos.png',
                                          width: 30,
                                          height: 30),
                                      const SizedBox(height: 7),
                                      const Text('Subir fotos del paquete',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Figtree')),
                                      const SizedBox(height: 3),
                                      const Text(
                                          'Formatos soportados: JPG, PNG (Max 5MB)',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9,
                                              fontFamily: 'Figtree')),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                  ),
                                  itemCount: photos.length,
                                  itemBuilder: (_, index) => Image.memory(
                                      photos[index],
                                      fit: BoxFit.cover),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FragileReturnRow(
                      value: fragile,
                      onChanged: (value) => setState(() => fragile = value),
                    ),
                    const SizedBox(height: 12),
                    const _ReturnInfoNote(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassButton(
                  label: 'Guardar configuración de ida y vuelta',
                  filled: true,
                  height: 48,
                  fontSize: 12,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choosePackageType() async {
    const values = [
      'Ropa y artículos personales',
      'Documentos',
      'Alimentos',
      'Otro'
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF102A68),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in values)
              ListTile(
                title: Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Figtree')),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => packageType = selected);
  }
}

class _ReturnHeader extends StatelessWidget {
  const _ReturnHeader();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset('assets/img/HomeCliente/ida_vuelta_icon.png',
              width: 24, height: 24),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ida y vuelta',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                Text('Indícanos cómo deseas el recorrido del envío.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      );
}

class _ReturnField extends StatelessWidget {
  const _ReturnField({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 17,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              children: [
                Image.asset(icon, width: 20, height: 20),
                const SizedBox(width: 9),
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
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white70,
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

class _ReturnInfoNote extends StatelessWidget {
  const _ReturnInfoNote();

  @override
  Widget build(BuildContext context) => AppGlassSurface(
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              Image.asset('assets/img/HomeCliente/taxi_passenger_info.png',
                  width: 18, height: 18),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'El servicio de ida y vuelta te permite utilizar el mismo vehículo para el regreso, ahorrando tiempo y costos.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      height: 1.2,
                      fontFamily: 'Figtree'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FragileReturnRow extends StatelessWidget {
  const _FragileReturnRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Image.asset('assets/img/HomeCliente/carga_fragil.png',
              width: 20, height: 20, fit: BoxFit.contain),
          const SizedBox(width: 8),
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
                Text('Nos ayudará a manipularlo correctamente.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
          AppGlassSurface(
            borderRadius: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: value ? accentBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('Sí',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: !value ? accentBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('No',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
