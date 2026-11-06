class Facility {
  final String name;
  final String type;
  final int krpPrice;
  final int nonKrpPrice;
  final String unit;

  const Facility({
    required this.name,
    required this.type,
    required this.krpPrice,
    required this.nonKrpPrice,
    required this.unit,
  });

  int priceFor(String category) {
    return category == 'KRP Student' ? krpPrice : nonKrpPrice;
  }
}
