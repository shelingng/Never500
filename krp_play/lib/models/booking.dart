class Booking {
  final String id;
  final String userEmail;
  final String facilityName;
  final DateTime date;
  final List<String> timeSlots;
  final int pricePerSession;
  final int totalPrice;
  final String status;

  const Booking({
    required this.id,
    required this.userEmail,
    required this.facilityName,
    required this.date,
    required this.timeSlots,
    required this.pricePerSession,
    required this.totalPrice,
    this.status = 'Pending',
  });
}
