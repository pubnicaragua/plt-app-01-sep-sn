const truckMaxWeightKg = <String, double>{
  'Camión de 2 toneladas': 2000,
  'Camión de 4 toneladas': 4000,
  'Camión de 5.5 toneladas': 5500,
  'Camión de 7 toneladas': 7000,
  'Camión de 8 toneladas': 8000,
};

const truckCapacityLabels = [
  'Camión de 2 toneladas',
  'Camión de 4 toneladas',
  'Camión de 5.5 toneladas',
  'Camión de 7 toneladas',
  'Camión de 8 toneladas',
];

double? truckMaxWeightKgForLabel(String label) => truckMaxWeightKg[label];

String? recommendedTruckForWeight(double weightKg) {
  for (final label in truckCapacityLabels) {
    if (weightKg <= truckMaxWeightKg[label]!) return label;
  }
  return null;
}

List<String> compatibleTrucksForWeight(double weightKg) => truckCapacityLabels
    .where((label) => weightKg <= truckMaxWeightKg[label]!)
    .toList(growable: false);

String truckAssetForLabel(String label) {
  if (label == 'Camión de 5.5 toneladas') {
    return 'assets/img/HomeCliente/carga_mediano.png';
  }
  if (label == 'Camión de 7 toneladas' || label == 'Camión de 8 toneladas') {
    return 'assets/img/HomeCliente/carga_grande.png';
  }
  return 'assets/img/HomeCliente/carga_extra_pequeno.png';
}
