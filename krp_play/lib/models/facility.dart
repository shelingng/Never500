import 'student_category.dart';

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

  /// SCRUM-38: only a recognised KRP category gets the KRP rate.
  int priceFor(String category) =>
      StudentCategory.parse(category) == StudentCategory.krp
      ? krpPrice
      : nonKrpPrice;
}
