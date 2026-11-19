import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  @override
  String toString() => message;
}

class BookingService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Payment backend (krp_play/backend). Set at run time, e.g.
  // flutter run -d chrome --dart-define=PAYMENT_BACKEND_URL=https://xxxx-3000.asse.devtunnels.ms
  // When empty, checkout falls back to the clearly labelled demo payment.
  static const String paymentBackendUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
  );

  bool get usesRealPayment => paymentBackendUrl.isNotEmpty;

  // Asks the backend to create (or reuse) a Billplz bill for a reserved booking.
  // The amount is taken from the database on the server, never from this app.
  Future<String> createBillplzPayment(String bookingId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw const PaymentException('Sign in to pay.');

    final base = paymentBackendUrl.replaceFirst(RegExp(r'/+$'), '');
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$base/api/create-payment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({'bookingId': bookingId}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment server. Check that the backend and tunnel are running.',
      );
    }

    Map<String, dynamic> body = {};
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {}

    if (response.statusCode != 200 || body['paymentUrl'] == null) {
      throw PaymentException(
        body['error']?.toString() ??
            'Payment server error (${response.statusCode}).',
      );
    }
    return body['paymentUrl'].toString();
  }

  // Returns {bookingStatus, paymentDeadline, lastAttempt}. bookingStatus is
  // written by the verified webhook; lastAttempt is Billplz's latest attempt
  // ('completed', 'failed', 'pending' or null if the user has not tried yet).
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw const PaymentException('Sign in to pay.');

    final base = paymentBackendUrl.replaceFirst(RegExp(r'/+$'), '');
    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$base/api/payment-status/$bookingId'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment server. Check that the backend is running.',
      );
    }

    Map<String, dynamic> body = {};
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {}
    if (response.statusCode != 200) {
      throw PaymentException(
        body['error']?.toString() ??
            'Payment server error (${response.statusCode}).',
      );
    }
    return body;
  }

  // 1. Fetch available facilities from public.facilities
  getFacilities() async {
    final response = await _supabase
        .from('facilities')
        .select()
        .eq('is_active', true);
    return response;
  }

  // A retry of the same checkout must reuse the same request ID.
  static String newCheckoutRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Map<String, dynamic>> reserveCart(
    List<Booking> cart, {
    required String requestId,
  }) async {
    return _checkout(cart, requestId: requestId);
  }

  // Explicit prototype payment: never used as evidence of real funds.
  Future<Map<String, dynamic>> demoPayCart(
    List<Booking> cart, {
    required String requestId,
    required String method,
  }) => _checkout(cart, requestId: requestId, demoMethod: method);

  Future<Map<String, dynamic>> _checkout(
    List<Booking> cart, {
    required String requestId,
    String? demoMethod,
  }) async {
    if (_supabase.auth.currentUser == null) {
      throw StateError('Sign in to reserve a slot.');
    }
    final items = cart
        .map(
          (b) => {
            'facility_name': b.facilityName.toString(),
            'date': _date(b.date),
            'start_times': List<String>.from(b.timeSlots as List)
                .map(_databaseTime)
                .toList(),
          },
        )
        .toList();
    final result = await _supabase.rpc(
      demoMethod == null ? 'reserve_cart' : 'demo_pay_cart',
      params: {
        'p_request_id': requestId,
        if (demoMethod != null) 'p_method': demoMethod,
        'p_items': items,
        'p_expected_total': cart.fold<num>(
          0,
          (sum, b) => sum + (b.totalPrice as num),
        ),
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  // Kept fail-closed for older screens: clients cannot attest that money arrived.
  Future<void> confirmPayment(
    String bookingId,
    num amount,
    String method,
  ) async {
    throw StateError(
      'Payment confirmation requires the verified server gateway.',
    );
  }

  Future<List<Booking>> getUserBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase
        .from('bookings')
        .select(
          '*, booking_items(price,status,time_slots(slot_date,start_time,facilities(name)))',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return _unpackBookings(response);
  }

  // No other user's order, identity or payment details are fetched for browsing.
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final response = await _supabase.rpc(
      'slot_availability',
      params: {'p_date': _date(date)},
    );
    return (response as List)
        .where((r) => r['status'] != 'available')
        .map(
          (r) => Booking(
            id: '${r['facility_name']}:${r['start_time']}',
            userId: '',
            facilityName: _displayFacility(r['facility_name'].toString()),
            date: DateTime.parse(r['slot_date'].toString()),
            timeSlots: [_displayTime(r['start_time'].toString())],
            pricePerSession: 0,
            totalPrice: 0,
            status: r['status'],
          ),
        )
        .toList();
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _databaseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$')
        .firstMatch(value.trim());
    if (match == null) throw FormatException('Invalid start time', value);
    final hour = int.parse(match[1]!) % 12 + (match[3] == 'PM' ? 12 : 0);
    return '${hour.toString().padLeft(2, '0')}:${match[2]}:00';
  }

  static String _displayTime(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts.first);
    return '${hour % 12 == 0 ? 12 : hour % 12}:${parts[1]} ${hour < 12 ? 'AM' : 'PM'}';
  }

  static String _displayFacility(String value) => value.replaceFirstMapped(
    RegExp(r' (\d+)$'),
    (m) => ' ${m[1]!.padLeft(2, '0')}',
  );

  // 🌟 6. Create Report in Database
  Future<void> createReport({
    required String category,
    String? bookingId,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final title = description.split(RegExp(r'[.!?\n]')).first.trim();
    final ref =
        'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

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

  // New orders use real slot joins. Legacy notes are read-only compatibility.
  List<Booking> _unpackBookings(List<dynamic> response) {
    final results = <Booking>[];
    for (final row in response) {
      var status = row['status'].toString().toLowerCase();
      final deadline = DateTime.tryParse(
        row['payment_deadline']?.toString() ?? '',
      );
      if (status == 'pending_payment' &&
          deadline != null &&
          !deadline.isAfter(DateTime.now())) {
        status = 'expired';
      }
      final label = switch (status) {
        'confirmed' => row['is_demo'] == true
            ? 'Demo paid & confirmed' : 'Paid & Confirmed',
        'pending_payment' => 'Reserved - awaiting payment',
        'expired' => 'Expired - unpaid',
        _ => status,
      };
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final raw in (row['booking_items'] as List? ?? [])) {
        final item = Map<String, dynamic>.from(raw as Map);
        final slot = item['time_slots'] as Map?;
        if (slot == null) continue;
        final facility =
            (slot['facilities'] as Map?)?['name']?.toString() ??
            'Sports Facility';
        final key = '$facility|${slot['slot_date']}';
        groups.putIfAbsent(key, () => []).add(item);
      }
      for (final entry in groups.entries) {
        final first = entry.value.first['time_slots'] as Map;
        final times =
            entry.value
                .map((i) => (i['time_slots'] as Map)['start_time'].toString())
                .toList()
              ..sort();
        results.add(
          Booking(
            id: row['id'],
            reference: row['booking_reference'],
            userId: row['user_id'],
            facilityName: _displayFacility(
              (first['facilities'] as Map)['name'].toString(),
            ),
            date: DateTime.parse(first['slot_date'].toString()),
            timeSlots: times.map(_displayTime).toList(),
            pricePerSession: entry.value.first['price'],
            totalPrice: entry.value.fold<num>(
              0,
              (sum, i) => sum + (i['price'] as num),
            ),
            status: label,
          ),
        );
      }
      if (groups.isEmpty) {
        final parts = row['admin_note']?.toString().split('|') ?? <String>[];
        results.add(
          Booking(
            id: row['id'],
            reference: row['booking_reference'],
            userId: row['user_id'],
            facilityName: parts.length >= 3
                ? parts[0]
                : 'Legacy booking - review required',
            date: parts.length >= 3
                ? DateTime.parse(parts[1])
                : DateTime.parse(row['created_at'].toString()),
            timeSlots: parts.length >= 3 ? parts[2].split(',') : <String>[],
            pricePerSession: 0,
            totalPrice: row['total_amount'],
            status: label,
          ),
        );
      }
    }
    return results;
  }
}
