import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

class InsuranceSelectionResult {
  const InsuranceSelectionResult({this.option});

  final TripOptionSelection? option;
}

class SeguroEnvioScreen extends StatefulWidget {
  const SeguroEnvioScreen({
    super.key,
    required this.baseTotal,
    required this.insurancePrice,
  });

  final double baseTotal;
  final double insurancePrice;

  @override
  State<SeguroEnvioScreen> createState() => _SeguroEnvioScreenState();
}

class _SeguroEnvioScreenState extends State<SeguroEnvioScreen> {
  int selectedCoverage = 2;

  String _money(double value) =>
      formatFareCs(value, 5);

  TripOptionSelection? get _selectedOption {
    if (selectedCoverage == 2) return null;
    final title = selectedCoverage == 0 ? 'Seguro A' : 'Seguro B';
    return TripOptionSelection(
      code: selectedCoverage == 0 ? 'shipment-insurance-a' : 'shipment-insurance-b',
      title: title,
      description: 'Protección esencial durante el envío',
      priceCs: widget.insurancePrice,
      currency: 'NIO',
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.baseTotal +
        (selectedCoverage == 2 ? 0 : widget.insurancePrice);
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 34, height: 34),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text('Seguro de envío',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .30)),
                      ),
                      child: const Text('Paso 4',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    const _InsuranceHeading(),
                    const SizedBox(height: 14),
                    _CoverageCard(
                      title: 'Seguro A',
                      subtitle: 'Protección esencial durante el envío',
                      price: widget.insurancePrice,
                      benefits: const [
                        'Accidentes personales',
                        'Asistencia médica básica',
                        'Soporte durante el envío',
                      ],
                      selected: selectedCoverage == 0,
                      iconAsset: 'assets/img/HomeCliente/seguro_salud.png',
                      onTap: () => setState(() => selectedCoverage = 0),
                    ),
                    const SizedBox(height: 10),
                    _CoverageCard(
                      title: 'Seguro B',
                      subtitle: 'Protección ampliada durante el envío',
                      price: widget.insurancePrice,
                      benefits: const [
                        'Accidentes personales',
                        'Asistencia médica básica',
                        'Soporte durante el envío',
                      ],
                      selected: selectedCoverage == 1,
                      iconAsset:
                          'assets/img/HomeCliente/seguro_certificado.png',
                      onTap: () => setState(() => selectedCoverage = 1),
                    ),
                    const SizedBox(height: 10),
                    _NoInsuranceCard(
                      selected: selectedCoverage == 2,
                      onTap: () => setState(() => selectedCoverage = 2),
                    ),
                    const SizedBox(height: 14),
                    AppGlassSurface(
                      borderRadius: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Precio total con seguro',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Figtree')),
                            Text(_money(total),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _InsuranceInfoCard(),
                    const SizedBox(height: 10),
                    AppGlassSurface(
                      borderRadius: 11,
                      fillColor: Colors.white.withValues(alpha: .92),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Términos y condiciones',
                                style: TextStyle(
                                    color: Color(0xFF0A245E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree')),
                            Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF0A245E), size: 19),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
                child: GlassButton(
                  label: 'Confirmar seguro de envío',
                  filled: true,
                  height: 45,
                  fontSize: 14,
                  onPressed: () => Navigator.of(context).pop(
                    InsuranceSelectionResult(option: _selectedOption),
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

class _InsuranceHeading extends StatelessWidget {
  const _InsuranceHeading();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Icon(Icons.groups_2_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecciona el tipo de cobertura',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree')),
                SizedBox(height: 2),
                Text('Elige cómo deseas proteger tu envío',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      );
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.benefits,
    required this.selected,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double price;
  final List<String> benefits;
  final bool selected;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 12,
          selected: selected,
          fillColor: selected ? accentBlue : const Color(0x3A0A2C73),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                Image.asset(iconAsset,
                    width: 20, height: 20, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'Figtree')),
                      const SizedBox(height: 5),
                      for (final benefit in benefits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Image.asset(
                                  'assets/img/HomeCliente/seguro_check.png',
                                  width: 11,
                                  height: 11,
                                  fit: BoxFit.contain),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(benefit,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontFamily: 'Figtree')),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text('Precio de seguro',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatFareCs(price, 5),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree')),
                    const SizedBox(height: 7),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _NoInsuranceCard extends StatelessWidget {
  const _NoInsuranceCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppGlassSurface(
          borderRadius: 12,
          selected: selected,
          fillColor: selected ? accentBlue : const Color(0x3A0A2C73),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Image.asset('assets/img/HomeCliente/seguro_certificado.png',
                    width: 20, height: 20, fit: BoxFit.contain),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No deseo seguro para mi envío',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                      Text('Prefiero no usar un seguro en este envío',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'Figtree')),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
}

class _InsuranceInfoCard extends StatelessWidget {
  const _InsuranceInfoCard();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_2_rounded, color: Colors.white, size: 21),
              SizedBox(width: 8),
              Text('¿Qué cubren los seguros?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree')),
            ],
          ),
          const SizedBox(height: 3),
          const Padding(
            padding: EdgeInsets.only(left: 29),
            child: Text('Puedes leer toda la información de nuestros seguros',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'Figtree')),
          ),
          const SizedBox(height: 9),
          AppGlassSurface(
            borderRadius: 11,
            selected: true,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deseo saber más información de los seguros',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree')),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
}
