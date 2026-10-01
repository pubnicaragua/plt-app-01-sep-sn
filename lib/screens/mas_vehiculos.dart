import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';

class MasVehiculosScreen extends StatefulWidget {
  const MasVehiculosScreen({
    super.key,
    required this.vehicleType,
    this.initialCount = 2,
  });

  final String vehicleType;
  final int initialCount;

  @override
  State<MasVehiculosScreen> createState() => _MasVehiculosScreenState();
}

class _MasVehiculosScreenState extends State<MasVehiculosScreen> {
  static const _maxVehicles = 99;
  late int count;

  @override
  void initState() {
    super.initState();
    count = widget.initialCount.clamp(1, _maxVehicles).toInt();
  }

  String get _pluralVehicleName {
    switch (widget.vehicleType.toLowerCase()) {
      case 'suv':
        return 'SUVs';
      case 'microbus':
        return 'Microbuses';
      case 'sedán':
      case 'sedan':
        return 'Sedanes';
      default:
        return '${widget.vehicleType}s';
    }
  }

  void _save() => Navigator.of(context).pop(count);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        darken: .04,
        backgroundLogoOpacity: .62,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 34,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 19),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Servicios adicionales',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        AppGlassSurface(
                          borderRadius: 11,
                          fillColor: const Color(0x33254A82),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Center(
                              child: Image.asset(
                                'assets/img/HomeCliente/taxi_more_vehicles.png',
                                width: 22,
                                height: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¿Deseas añadir más vehículos?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Agrega vehículos para recoger a tu personal.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .82),
                                  fontFamily: 'Figtree',
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 21),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '¿Cuántos vehículos adicionales quieres?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Selecciona la cantidad de vehículos',
                                style: TextStyle(
                                  color: Color(0xFFD4E3FF),
                                  fontFamily: 'Figtree',
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 8),
                      borderRadius: 14,
                      color: const Color(0x35284678),
                      child: Row(
                        children: [
                          _CountButton(
                            icon: Icons.remove_rounded,
                            enabled: count > 1,
                            onTap: () => setState(() => count--),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text('$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Figtree',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    )),
                                const Text('Vehículos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Figtree',
                                      fontSize: 10,
                                    )),
                              ],
                            ),
                          ),
                          _CountButton(
                            icon: Icons.add_rounded,
                            enabled: count < _maxVehicles,
                            filled: true,
                            onTap: () => setState(() => count++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 10),
                      borderRadius: 12,
                      color: const Color(0x30254A82),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/img/HomeCliente/taxi_passenger_info.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontSize: 9,
                                  height: 1.2,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Recuerda, los vehículos que agregues, son del mismo tipo que seleccionaste previamente.\n',
                                  ),
                                  TextSpan(
                                    text:
                                        'Ejemplo: ${widget.vehicleType} = cantidad de $_pluralVehicleName',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _save,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x40FFFFFF)),
                      ),
                      child: const Text(
                        'Añadir vehículos',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
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

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? accentBlue : const Color(0x553B5A91),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon,
              color: Colors.white.withValues(alpha: enabled ? 1 : .45),
              size: 21),
        ),
      ),
    );
  }
}
