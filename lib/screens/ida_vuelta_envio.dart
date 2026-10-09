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
  late final TextEditingController packageTypeController;
  late final TextEditingController weightController;
  late TimeOfDay returnTime;
  late ReturnWaitMode waitMode;
  late bool fragile;
  final photos = <Uint8List>[];

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    packageType = config?.returnPackageType ?? '';
    weight = config?.returnWeight ?? 2;
    packageTypeController = TextEditingController(text: packageType);
    weightController = TextEditingController(text: '$weight');
    returnTime = config?.returnTime ?? const TimeOfDay(hour: 18, minute: 0);
    waitMode = config?.waitMode ?? ReturnWaitMode.scheduledReturn;
    fragile = config?.returnFragile ?? false;
    photos.addAll(config?.returnPhotos ?? const []);
  }

  @override
  void dispose() {
    packageTypeController.dispose();
    weightController.dispose();
    super.dispose();
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

  Future<void> _chooseReturnTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: returnTime,
      helpText: 'Hora aproximada de regreso',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: accentBlue,
                surface: const Color(0xFF102755),
                onSurface: Colors.white,
              ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Color(0xFF102755),
            dialHandColor: accentBlue,
            hourMinuteColor: Color(0xFF18386B),
            hourMinuteTextColor: Colors.white,
            dayPeriodColor: Color(0xFF18386B),
            dayPeriodTextColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) setState(() => returnTime = selected);
  }

  String _timeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$hour:${time.minute.toString().padLeft(2, '0')} '
        '${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _save() => Navigator.of(context).pop(
        IdaVueltaConfig(
          passengerCount: 1,
          returnTime: returnTime,
          waitMode: waitMode,
          returnTransport: widget.transport,
          returnPackageType: packageTypeController.text.trim(),
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
                      value: '',
                      content: TextField(
                        controller: packageTypeController,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15.5,
                            fontFamily: 'Figtree'),
                        decoration: const InputDecoration(
                          hintText: 'Escribe qué vas a transportar',
                          hintStyle: TextStyle(
                              color: Colors.white54,
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
                    _ReturnField(
                      icon: 'assets/img/HomeCliente/envio_weight.png',
                      label: 'Peso aproximado',
                      value: '',
                      content: SizedBox(
                        width: 105,
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15.5,
                              fontFamily: 'Figtree'),
                          decoration: const InputDecoration(
                            hintText: 'Escribe el peso',
                            hintStyle: TextStyle(
                                color: Colors.white54,
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
                              setState(() =>
                                  weight = parsed.clamp(1, 9999).toInt());
                            }
                          },
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: weight > 1
                                ? () {
                                    final next = weight - 1;
                                    setState(() {
                                      weight = next;
                                      weightController.text = '$next';
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {
                              final next = (weight + 1).clamp(1, 9999).toInt();
                              setState(() {
                                weight = next;
                                weightController.text = '$next';
                              });
                            },
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
                    if (widget.transport == 'Camión') ...[
                      const SizedBox(height: 14),
                      const _ReturnScheduleHeading(),
                      const SizedBox(height: 10),
                      AppGlassSurface(
                        borderRadius: 13,
                        fillColor: const Color(0x30284678),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Hora aproximada de regreso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Material(
                                color: accentBlue,
                                borderRadius: BorderRadius.circular(22),
                                child: InkWell(
                                  onTap: _chooseReturnTime,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          _timeLabel(returnTime),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Figtree',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white,
                                            size: 17),
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

class _ReturnScheduleHeading extends StatelessWidget {
  const _ReturnScheduleHeading();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Cuándo será el regreso?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                Text('Indica el horario aproximado del viaje de vuelta.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
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
    this.content,
  });

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
                      content ??
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
              ],
            ),
          ),
        ],
      );
}
