import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'crear_envio3.dart';

class CrearEnvio2 extends StatefulWidget {
  const CrearEnvio2({
    super.key,
    required this.origin,
    required this.destination,
    required this.weight,
    required this.bundles,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Vehículo',
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
  });

  final String origin;
  final String destination;
  final int weight;
  final int bundles;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;

  @override
  State<CrearEnvio2> createState() => _CrearEnvio2State();
}

class _CrearEnvio2State extends State<CrearEnvio2> {
  final description = TextEditingController();
  late final TextEditingController recipient;
  late final TextEditingController phone;
  bool fragile = true;
  bool priority = true;
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  @override
  void initState() {
    super.initState();
    recipient = TextEditingController(text: widget.recipientName);
    phone = TextEditingController(text: widget.recipientPhone);
  }

  @override
  void dispose() {
    description.dispose();
    recipient.dispose();
    phone.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime value) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }

  String _fmtTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final latest = now.add(const Duration(hours: 24));
    final picked = await showDatePicker(
      context: context,
      initialDate: (scheduledDate ?? now).isBefore(now)
          ? now
          : (scheduledDate ?? now).isAfter(latest)
              ? latest
              : scheduledDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: latest,
      helpText: 'Fecha del viaje (máx. 24 h)',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      setState(() => scheduledDate = picked);
      if (scheduledTime == null) _pickTime();
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: scheduledTime ?? now,
      helpText: 'Hora de recogida',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) setState(() => scheduledTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Detalles del pedido',
      subtitle: 'Paso 2 de 2 · Datos del envío',
      description:
          'Indica las características de tu carga y te recomendamos el transporte adecuado.',
      step: 1,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESCRIPCIÓN DEL PAQUETE',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 8),
                GlassField(
                  label: 'Descripción',
                  hint: 'Ej. Cajas, vinilos, paquetes…',
                  controller: description,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DESTINATARIO',
                            style: TextStyle(
                              color: Color(0xFFB9D4FF),
                              fontSize: 9.5,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassField(
                            label: 'Nombre',
                            hint: 'Nombre completo',
                            controller: recipient,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TELÉFONO',
                            style: TextStyle(
                              color: Color(0xFFB9D4FF),
                              fontSize: 9.5,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassField(
                            label: 'Cel',
                            hint: '+505 …',
                            controller: phone,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Carga frágil?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (final option in ['SÍ', 'NO'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(
                              () => fragile = option == 'SÍ'),
                          child: Container(
                            width: 86,
                            padding: const EdgeInsets.symmetric(
                                vertical: 9),
                            decoration: BoxDecoration(
                              color:
                                  (option == 'SÍ') == fragile
                                      ? figmaBlue
                                      : Colors.white
                                          .withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: (option == 'SÍ') == fragile
                                    ? cyan
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUBIR FOTOS DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          color: Colors.white70),
                      const SizedBox(height: 6),
                      const Text(
                        'Tomar foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      const Text(
                        'Formatos soportados: JPG, PNG (máx. 5MB)',
                        style: TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 9.5,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    _thumb(Icons.checkroom),
                    const SizedBox(width: 9),
                    _thumb(Icons.card_giftcard),
                    const SizedBox(width: 9),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: glassBorder),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FACTURA DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined,
                            color: Colors.white70, size: 26),
                        const SizedBox(height: 6),
                        const Text(
                          'Adjuntar factura (PDF)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '¿Cómo quieres que se procese?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (final option in ['Prioritario', 'Programado'])
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: GestureDetector(
                          onTap: () => setState(
                              () => priority = option == 'Prioritario'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: (option == 'Prioritario') == priority
                                  ? figmaBlue
                                  : Colors.white.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color:
                                    (option == 'Prioritario') == priority
                                        ? cyan
                                        : Colors.transparent,
                              ),
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
                      ),
                  ],
                ),
                if (!priority) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cyan.withValues(alpha: .35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                color: cyan, size: 17),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Agenda tu viaje programado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Solo se permite programar dentro de las próximas 24 horas. Fechas pasadas quedan bloqueadas.',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 10.5,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ScheduleTile(
                                label: 'Fecha',
                                value: scheduledDate == null
                                    ? 'Seleccionar'
                                    : _fmtDate(scheduledDate!),
                                icon: Icons.calendar_today_rounded,
                                error: scheduledDate == null &&
                                        !priority
                                    ? 'Obligatoria'
                                    : null,
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _ScheduleTile(
                                label: 'Hora',
                                value: scheduledTime == null
                                    ? 'Seleccionar'
                                    : _fmtTime(scheduledTime!),
                                icon: Icons.access_time_rounded,
                                error: scheduledTime == null &&
                                        !priority
                                    ? 'Obligatoria'
                                    : null,
                                onTap: _pickTime,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Continuar',
            filled: true,
            textColor: Colors.white,
            onPressed: () {
              final isPriority = priority;
              if (!isPriority &&
                  (scheduledDate == null || scheduledTime == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Selecciona fecha y hora para el viaje programado.',
                      style: TextStyle(fontFamily: 'Acumin Pro'),
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CrearEnvio3(
                    origin: widget.origin,
                    destination: widget.destination,
                    weight: widget.weight,
                    bundles: widget.bundles,
                    originPlace: widget.originPlace,
                    destinationPlace: widget.destinationPlace,
                    transport: widget.transport,
                    originRefs: widget.originRefs,
                    destinationRefs: widget.destinationRefs,
                    recipientName: recipient.text.trim(),
                    recipientPhone: phone.text.trim(),
                    serviceType: isPriority ? 'Express' : 'Programado',
                    scheduledDate: scheduledDate == null
                        ? null
                        : '${scheduledDate!.year}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}',
                    scheduledTime: scheduledTime == null
                        ? null
                        : '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _thumb(IconData icon) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: Colors.white70),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.error,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: error != null
                ? const Color(0xFFE5484D).withValues(alpha: .6)
                : glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cyan, size: 15),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(
                  color: Color(0xFFFFB4B4),
                  fontSize: 9,
                  fontFamily: 'Acumin Pro',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
