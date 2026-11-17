import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

  // 1. Fetch available facilities from public.facilities
  getFacilities() async {
    final response = await _supabase.from('facilities').select().eq('is_active', true);
    return response;
  }

  // 2. Create a new booking
  createBooking(Booking booking, String customerCategory) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final ref = 'KRP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final String bookingDataString = '${booking.facilityName}|${booking.date.toIso8601String()}|${booking.timeSlots.join(",")}';

    // Insert into public.bookings
    final bookingResponse = await _supabase.from('bookings').insert({
      'user_id': user.id,
      'booking_reference': ref,
      'total_amount': booking.totalPrice,
      'status': 'Confirmed',
      'customer_category': customerCategory == 'KRP Student' ? 'krp' : 'non_krp',
      'booking_source': 'online',
      'admin_note': bookingDataString, 
    }).select().single();

    final bookingId = bookingResponse['id'];

    // Insert into public.booking_items 
    for (var timeSlot in booking.timeSlots) {
      await _supabase.from('booking_items').insert({
        'booking_id': bookingId,
        'price': booking.pricePerSession,
        'status': 'Confirmed',
      });
    }

    return bookingResponse;
  }

  // 3. Process payment and update status
  confirmPayment(String bookingId, num amount, String method) async {
    await _supabase.from('payments').insert({
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': method == 'E-Wallet' ? 'touch_n_go_ewallet' : 'fpx',
      'status': 'successful',
      'paid_at': DateTime.now().toIso8601String(),
    });

    await _supabase.from('bookings').update({'status': 'Confirmed'}).eq('id', bookingId);
  }

  // 4. Fetch the logged-in user's bookings
  getUserBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return _unpackBookings(response);
  }

  // 5. Fetch ALL bookings for a specific date to check live availability
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .neq('status', 'Cancelled')
        .neq('status', 'Rejected'); // Ignore cancelled bookings

    final allBookings = _unpackBookings(response);
    
    // Filter to only return bookings that overlap with the selected day
    return allBookings.where((b) => b.date.year == date.year && b.date.month == date.month && b.date.day == date.day).toList();
  }

  // 🌟 6. Create Report in Database
  Future<void> createReport({
    required String category,
    String? bookingId,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final title = description.split(RegExp(r'[.!?\n]')).first.trim();
    final ref = 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Map UI Category to Database Strict Format Constraint
    String dbCategory = 'other';
    if (category == 'Booking Issue') dbCategory = 'booking_issue';
    if (category == 'Payment Issue') dbCategory = 'payment_issue';
    if (category == 'Facility Problem') dbCategory = 'facility_problem';
    if (category == 'Account Issue') dbCategory = 'account_issue';

    await _supabase.from('reports').insert({
      'report_reference': ref,
      'user_id': user.id,
      'related_booking_id': bookingId,
      'category': dbCategory,
      'subject': title.isEmpty ? 'Facility report' : title,
      'description': description,
      'status': 'submitted',
    });
  }

  // 🌟 7. Fetch Reports from Database
  Future<List<dynamic>> getUserReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    
    final response = await _supabase
        .from('reports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
        
    return response;
  }

  // Helper method to unpack the prototype admin_note data
  List<Booking> _unpackBookings(List<dynamic> response) {
    List<Booking> results = [];
    for (var row in response) {
      String facility = 'Sports Facility';
      DateTime date = DateTime.parse(row['created_at']);
      List<String> times = ['12:00 AM - 1:00 AM'];

      if (row['admin_note'] != null && row['admin_note'].toString().contains('|')) {
        final parts = row['admin_note'].toString().split('|');
        if (parts.length >= 3) {
          facility = parts[0];
          date = DateTime.parse(parts[1]);
          times = parts[2].split(',');
        }
      }

      results.add(Booking(
        id: row['id'],
        reference: row['booking_reference'] ?? 'REF-ERR',
        userId: row['user_id'],
        facilityName: facility,
        date: date,
        timeSlots: times,
        pricePerSession: 0,
        totalPrice: row['total_amount'],
        status: row['status'] == 'Confirmed' ? 'Paid & Confirmed' : row['status'],
      ));
    }
    return results;
  }
}