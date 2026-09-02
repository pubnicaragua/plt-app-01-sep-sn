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
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Continuar',
            filled: true,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
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
                ),
              ),
            ),
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
