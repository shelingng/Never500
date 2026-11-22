class Booking {
  final dynamic id; // Supabase UUID
  final dynamic reference; // KRP-123456
  final dynamic userId;
  final dynamic facilityName;
  final DateTime date;
  final dynamic timeSlots; // Array of strings
  final dynamic pricePerSession;
  final dynamic participants;
  final dynamic totalPrice;
  final dynamic status;
  final dynamic paidAt;
  final dynamic paymentRef;

  Booking({
    required this.id,
    this.reference = '',
    required this.userId,
    required this.facilityName,
    required this.date,
    required this.timeSlots,
    required this.pricePerSession,
    this.participants = 1,
    required this.totalPrice,
    this.status = 'Pending Payment',
    this.paidAt,
    this.paymentRef,
  });
}
