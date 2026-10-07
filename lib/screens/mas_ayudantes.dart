import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';

class MasAyudantesScreen extends StatefulWidget {
  const MasAyudantesScreen({
    super.key,
    this.initialCount = 2,
  });

  final int initialCount;

  @override
  State<MasAyudantesScreen> createState() => _MasAyudantesScreenState();
}

class _MasAyudantesScreenState extends State<MasAyudantesScreen> {
  static const _maxHelpers = 99;
  late int count;

  @override
  void initState() {
    super.initState();
    count = widget.initialCount.clamp(1, _maxHelpers).toInt();
  }

  void _save() => Navigator.of(context).pop(count);

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
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Center(
                              child: Image.asset(
                                'assets/img/HomeCliente/carga_ayudante.png',
                                width: 25,
                                height: 25,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Deseas añadir ayudantes?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Agrega personal para ayudarte con la carga y descarga de tus productos.',
                                style: TextStyle(
                                  color: Color(0xD1FFFFFF),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Cuántos ayudantes necesitas?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Selecciona la cantidad de ayudantes',
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
                    AppGlassSurface(
                      borderRadius: 11,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 8),
                        child: Row(
                          children: [
                          _HelperCountButton(
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
                                const Text(
                                  'Ayudantes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Figtree',
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _HelperCountButton(
                            icon: Icons.add_rounded,
                            enabled: count < _maxHelpers,
                            filled: true,
                            onTap: () => setState(() => count++),
                          ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    AppGlassSurface(
                      borderRadius: 11,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Image.asset(
                            'assets/img/HomeCliente/taxi_passenger_info.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Figtree',
                                  fontSize: 9,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          'Recomendamos según el tamaño de tu carga.\n'),
                                  TextSpan(
                                    text: '2 Ayudantes',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
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
                        'Agregar ayudantes',
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

class _HelperCountButton extends StatelessWidget {
  const _HelperCountButton({
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
