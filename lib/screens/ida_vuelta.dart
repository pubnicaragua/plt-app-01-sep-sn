import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';

enum ReturnWaitMode { scheduledReturn, paidWait }

class IdaVueltaConfig {
  const IdaVueltaConfig({
    required this.passengerCount,
    required this.returnTime,
    required this.waitMode,
  });

  final int passengerCount;
  final TimeOfDay returnTime;
  final ReturnWaitMode waitMode;
}

class IdaVueltaScreen extends StatefulWidget {
  const IdaVueltaScreen({
    super.key,
    required this.initialPassengers,
    required this.maxPassengers,
    this.initialConfig,
  });

  final int initialPassengers;
  final int maxPassengers;
  final IdaVueltaConfig? initialConfig;

  @override
  State<IdaVueltaScreen> createState() => _IdaVueltaScreenState();
}

class _IdaVueltaScreenState extends State<IdaVueltaScreen> {
  late int passengers;
  late TimeOfDay returnTime;
  late ReturnWaitMode waitMode;

  int get _maxPassengers => widget.maxPassengers.clamp(1, 99).toInt();

  @override
  void initState() {
    super.initState();
    passengers = widget.initialConfig?.passengerCount ??
        widget.initialPassengers.clamp(1, _maxPassengers).toInt();
    returnTime = widget.initialConfig?.returnTime ??
        const TimeOfDay(hour: 18, minute: 0);
    waitMode = widget.initialConfig?.waitMode ?? ReturnWaitMode.scheduledReturn;
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

  void _save() {
    Navigator.of(context).pop(
      IdaVueltaConfig(
        passengerCount: passengers,
        returnTime: returnTime,
        waitMode: waitMode,
      ),
    );
  }

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
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 19),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 2),
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
                    const SizedBox(height: 10),
                    const _SectionHeading(
                      icon: 'assets/img/HomeCliente/ida_vuelta_icon.png',
                      title: 'Ida y vuelta',
                      subtitle: 'Indícanos cómo deseas el recorrido del viaje.',
                      boxedIcon: true,
                    ),
                    const SizedBox(height: 16),
                    const _SectionHeading(
                      icon: 'assets/img/HomeCliente/pasajeros_regreso_icon.png',
                      title: '¿Regresarán más pasajeros?',
                      subtitle: 'Ingresa la cantidad de pasajeros a recoger.',
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      borderRadius: 14,
                      color: const Color(0x35284678),
                      child: Row(
                        children: [
                          _CounterButton(
                            icon: Icons.remove_rounded,
                            enabled: passengers > 1,
                            onTap: () => setState(() => passengers--),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$passengers',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const Text(
                                  'Pasajeros',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Figtree',
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CounterButton(
                            icon: Icons.add_rounded,
                            enabled: passengers < _maxPassengers,
                            onTap: () => setState(() => passengers++),
                            filled: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      borderRadius: 12,
                      color: const Color(0x30254A82),
                      child: Row(
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
                                        'Recuerda que según el vehículo puedes llevar máximo:\n',
                                  ),
                                  TextSpan(
                                    text: 'Máximo $_maxPassengers pasajeros',
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
                    const SizedBox(height: 16),
                    const _SectionHeading(
                      materialIcon: Icons.access_time_rounded,
                      title: '¿Cuál es el horario de regreso?',
                      subtitle:
                          'Agrega la hora aproximada de regreso al punto de origen.',
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      borderRadius: 13,
                      color: const Color(0x30284678),
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
                    const SizedBox(height: 16),
                    const _SectionHeading(
                      icon: 'assets/img/HomeCliente/espera_punto_icon.png',
                      title: '¿Deseas que el chofer espere en el punto?',
                      subtitle:
                          'Elige si esperará en el lugar o regresará a la hora indicada.',
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ReturnModeCard(
                            selected:
                                waitMode == ReturnWaitMode.scheduledReturn,
                            icon: Icons.calendar_month_rounded,
                            label: 'Regreso programado',
                            onTap: () => setState(() =>
                                waitMode = ReturnWaitMode.scheduledReturn),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReturnModeCard(
                            selected: waitMode == ReturnWaitMode.paidWait,
                            icon: Icons.payments_rounded,
                            label: 'Espera pagada',
                            onTap: () => setState(
                                () => waitMode = ReturnWaitMode.paidWait),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _save,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x40FFFFFF)),
                      ),
                      alignment: Alignment.center,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Guardar configuración de Ida y Vuelta',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.icon,
    this.materialIcon,
    this.compact = false,
    this.boxedIcon = false,
  });

  final String title;
  final String subtitle;
  final String? icon;
  final IconData? materialIcon;
  final bool compact;
  final bool boxedIcon;

  @override
  Widget build(BuildContext context) {
    final leading = boxedIcon
        ? AppGlassSurface(
            borderRadius: 11,
            fillColor: const Color(0x33254A82),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Image.asset(icon!, width: 21, height: 21),
              ),
            ),
          )
        : icon != null
            ? Image.asset(icon!,
                width: compact ? 17 : 22, height: compact ? 17 : 22)
            : Icon(materialIcon, color: Colors.white, size: compact ? 17 : 22);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        SizedBox(width: boxedIcon ? 11 : 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Figtree',
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 14,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD4E3FF),
                    fontFamily: 'Figtree',
                    fontSize: 9,
                    height: 1.25,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
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

class _ReturnModeCard extends StatelessWidget {
  const _ReturnModeCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentBlue : const Color(0x38284678),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color:
                  selected ? const Color(0x6698C9FF) : const Color(0x44FFFFFF),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: Colors.white.withValues(alpha: selected ? 1 : .72),
                  size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: selected ? 1 : .75),
                    fontFamily: 'Figtree',
                    fontWeight: FontWeight.w700,
                    fontSize: 8.5,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: Colors.white.withValues(alpha: selected ? 1 : .5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
