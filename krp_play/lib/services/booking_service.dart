import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/booking_order.dart';
import '../models/checkout_recovery.dart';

typedef JsonMap = Map<String, dynamic>;

class ReportPhotoUpload {
  final String name;
  final Uint8List bytes;

  const ReportPhotoUpload({required this.name, required this.bytes});
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  @override
  String toString() => message;
}

class BookingService {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const String reportBucket = 'report-attachments';

  static const String paymentBackendUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
  );

  bool get usesRealPayment => paymentBackendUrl.isNotEmpty;

  // Free ngrok shows a "you are about to visit" page to browsers instead of
  // forwarding the request; this header skips it. Other servers ignore it.
  static const Map<String, String> _tunnelHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

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
              ..._tunnelHeaders,
            },
            body: jsonEncode({'bookingId': bookingId}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment server. Check that the backend and tunnel are running.',
      );
    }

    JsonMap body = {};
    try {
      body = JsonMap.from(jsonDecode(response.body) as Map);
    } catch (_) {}

    if (response.statusCode != 200 || body['paymentUrl'] == null) {
      throw PaymentException(
        body['error']?.toString() ??
            'Payment server error (${response.statusCode}).',
      );
    }
    return body['paymentUrl'].toString();
  }

  Future<JsonMap> getPaymentStatus(String bookingId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw const PaymentException('Sign in to pay.');

    final base = paymentBackendUrl.replaceFirst(RegExp(r'/+$'), '');
    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$base/api/payment-status/$bookingId'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              ..._tunnelHeaders,
            },
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment server. Check that the backend is running.',
      );
    }

    JsonMap body = {};
    try {
      body = JsonMap.from(jsonDecode(response.body) as Map);
    } catch (_) {}
    if (response.statusCode != 200) {
      throw PaymentException(
        body['error']?.toString() ??
            'Payment server error (${response.statusCode}).',
      );
    }
    return body;
  }

  Future<bool> cancelPendingBooking(String bookingId) async {
    final session = _supabase.auth.currentSession;
    final userId = checkoutUserId;
    if (session == null || userId == null) {
      throw const PaymentException('Sign in to cancel a booking.');
    }

    if (usesRealPayment) {
      final base = paymentBackendUrl.replaceFirst(RegExp(r'/+$'), '');
      final http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('$base/api/cancel-payment/$bookingId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${session.accessToken}',
                ..._tunnelHeaders,
              },
            )
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        throw const PaymentException(
          'Could not reach the payment server. Check that the backend and tunnel are running.',
        );
      }

      JsonMap body = {};
      try {
        body = JsonMap.from(jsonDecode(response.body) as Map);
      } catch (_) {}

      if (response.statusCode != 200) {
        throw PaymentException(
          body['error']?.toString() ??
              'Could not cancel payment (${response.statusCode}).',
        );
      }
      return true;
    }

    final updatedRows = await _supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId)
        .eq('user_id', userId)
        .eq('status', 'pending_payment')
        .select('id');

    if ((updatedRows as List).isEmpty) return false;

    try {
      await _supabase
          .from('booking_items')
          .update({'status': 'cancelled'})
          .eq('booking_id', bookingId);
    } catch (_) {}

    return true;
  }

  String? get checkoutUserId => _supabase.auth.currentUser?.id;

  /// Always constrain recovery by the authenticated owner as well as RLS.
  Future<CheckoutRecovery?> getCheckoutForRecovery({String? bookingId}) async {
    final userId = checkoutUserId;
    if (userId == null) return null;
    var query = _supabase
        .from('bookings')
        .select(
          '*, booking_items(price, status, '
          'time_slots(slot_date, start_time, end_time, facilities(name))), '
          'payments(status, payment_method, payment_gateway, '
          'transaction_reference, billplz_id, paid_at, amount)',
        )
        .eq('user_id', userId)
        .eq('is_demo', false);
    if (bookingId != null) query = query.eq('id', bookingId);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(1);
    if (checkoutUserId != userId) {
      throw StateError('Account changed while loading checkout.');
    }
    if (rows.isEmpty) return null;
    // Do not resurrect an older unpaid cart after a newer completed order.
    final status = rows.first['status']?.toString().toLowerCase();
    if (bookingId == null &&
        status != 'pending_payment' &&
        status != 'expired') {
      return null;
    }
    return CheckoutRecovery.fromRow(JsonMap.from(rows.first));
  }

  Future<List<JsonMap>> getOperatingSchedules() async {
    final rows = await _supabase
        .from('operating_schedules')
        .select('day_of_week, start_time, end_time, slot_minutes, is_active')
        .eq('is_active', true)
        .order('day_of_week')
        .order('start_time');
    return [for (final row in rows) JsonMap.from(row)];
  }

  Future<List<dynamic>> getFacilities() async {
    final response = await _supabase
        .from('facilities')
        .select()
        .eq('is_active', true);
    return response as List<dynamic>;
  }

  static String newCheckoutRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<JsonMap> reserveCart(
    List<Booking> cart, {
    required String requestId,
  }) async {
    return _checkout(cart, requestId: requestId);
  }

  Future<JsonMap> demoPayCart(
    List<Booking> cart, {
    required String requestId,
    required String method,
  }) => _checkout(cart, requestId: requestId, demoMethod: method);

  Future<JsonMap> _checkout(
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
            'start_times': List<String>.from(
              b.timeSlots as List,
            ).map(_databaseTime).toList(),
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
    return JsonMap.from(result as Map);
  }

  Future<void> confirmPayment(String bookingId, num amount, String method) async {
    throw StateError(
      'Payment confirmation requires the verified server gateway.',
    );
  }

  Future<List<Booking>> getUserBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return <Booking>[];
    final response = await _supabase
        .from('bookings')
        .select(
          '*, booking_items(price,status,time_slots(slot_date,start_time,facilities(name))), payments(status,paid_at,transaction_reference,billplz_id)',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return _unpackBookings(response as List<dynamic>);
  }

  /// SCRUM-48: the signed-in student's own orders, newest first, each with
  /// all its sessions and payments. RLS also limits the rows to this user.
  Future<List<BookingOrder>> getMyOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Sign in to see your bookings.');
    final rows = await _supabase
        .from('bookings')
        .select(
          'id, booking_reference, status, total_amount, payment_deadline, '
          'created_at, is_demo, facility_name, booking_date, start_time, '
          'booking_items(price, status, '
          'time_slots(slot_date, start_time, end_time, facilities(name))), '
          'payments(status, payment_method, payment_gateway, '
          'transaction_reference, billplz_id, paid_at, amount)',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return [
      for (final row in rows as List)
        BookingOrder.fromRow(JsonMap.from(row as Map)),
    ];
  }

  String _facilityMatchKey(String raw) {
    var s = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirstMapped(RegExp(r' 0+(\d+)$'), (m) => ' ${m[1]}');
    if (s == 'dart board' ||
        s == 'dart board 1' ||
        s == 'dart' ||
        s == 'board 1' ||
        s == 'dart 1') {
      return 'dart 1';
    }
    if (s == 'snooker table' ||
        s == 'snooker table 1' ||
        s == 'snooker' ||
        s == 'table 1' ||
        s == 'snooker 1') {
      return 'snooker 1';
    }
    return s;
  }

  String _formatTimeFlexible(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final ampmMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (ampmMatch != null) {
      final hour = int.parse(ampmMatch[1]!);
      final min = ampmMatch[2]!;
      final period = ampmMatch[3]!.toUpperCase();
      return '$hour:$min $period';
    }
    final isoMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(trimmed);
    if (isoMatch != null) {
      final hour = int.parse(isoMatch[1]!);
      final min = isoMatch[2]!;
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final period = hour < 12 ? 'AM' : 'PM';
      return '$h12:$min $period';
    }
    return trimmed;
  }

  bool _isInactiveStatus(String stLower) {
    if (stLower.contains('closed') || stLower.contains('maintenance')) {
      return false;
    }
    return stLower.contains('cancel') ||
        stLower.contains('expir') ||
        stLower.contains('fail') ||
        stLower.contains('refund');
  }

  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final dateStr = _date(date);
    final bookings = <Booking>[];

    void addOrUpgrade(
      String facilityRaw,
      String timeRaw,
      String statusRaw, {
      bool forceUpgrade = false,
    }) {
      final fClean = facilityRaw.trim();
      final tClean = _formatTimeFlexible(timeRaw);
      final stClean = statusRaw.trim().toLowerCase();
      if (fClean.isEmpty || tClean.isEmpty) return;
      if (stClean == 'available' ||
          stClean == 'open' ||
          _isInactiveStatus(stClean)) {
        return;
      }

      final displayFac = _displayFacility(fClean);
      final matchFac = _facilityMatchKey(fClean);
      final idx = bookings.indexWhere(
        (b) =>
            _facilityMatchKey(b.facilityName) == matchFac &&
            b.timeSlots.contains(tClean),
      );

      final normalizedStatus =
          (stClean.contains('closed') || stClean.contains('maintenance'))
          ? 'closed'
          : (stClean == 'reserved' || stClean == 'pending_payment'
                ? 'reserved'
                : 'booked');

      if (idx == -1) {
        bookings.add(
          Booking(
            id: '$matchFac:$tClean',
            userId: '',
            facilityName: displayFac,
            date: date,
            timeSlots: [tClean],
            pricePerSession: 0,
            totalPrice: 0,
            status: normalizedStatus,
          ),
        );
      } else if (forceUpgrade &&
          bookings[idx].status != 'closed' &&
          normalizedStatus == 'closed') {
        bookings[idx] = Booking(
          id: bookings[idx].id,
          userId: bookings[idx].userId,
          facilityName: bookings[idx].facilityName,
          date: bookings[idx].date,
          timeSlots: bookings[idx].timeSlots,
          pricePerSession: bookings[idx].pricePerSession,
          totalPrice: bookings[idx].totalPrice,
          status: normalizedStatus,
        );
      }
    }

    try {
      final response = await _supabase.rpc(
        'slot_availability',
        params: {'p_date': dateStr},
      );
      for (final r in (response as List)) {
        final map = JsonMap.from(r as Map);
        addOrUpgrade(
          (map['facility_name'] ?? '').toString(),
          (map['start_time'] ?? '').toString(),
          (map['status'] ?? '').toString(),
        );
      }
    } catch (_) {}

    try {
      final bookingRows = await _supabase
          .from('bookings')
          .select('id, facility_name, booking_date, start_time, status')
          .eq('booking_date', dateStr);
      for (final r in (bookingRows as List)) {
        final row = JsonMap.from(r as Map);
        addOrUpgrade(
          (row['facility_name'] ?? '').toString(),
          (row['start_time'] ?? '').toString(),
          (row['status'] ?? '').toString(),
          forceUpgrade: true,
        );
      }
    } catch (_) {}

    return bookings;
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _databaseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2}) (AM|PM)$',
    ).firstMatch(value.trim());
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

  Future<JsonMap> createReport({
    required String category,
    String? bookingId,
    String? subject,
    required String description,
    List<ReportPhotoUpload> photos = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final cleanedSubject = (subject ?? '').trim();
    final fallbackTitle = description.split(RegExp(r'[.!?\n]')).first.trim();
    final finalSubject = cleanedSubject.isNotEmpty
        ? cleanedSubject
        : (fallbackTitle.isEmpty ? 'Facility report' : fallbackTitle);

    final ref =
        'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    String dbCategory = 'other';
    if (category == 'Booking Issue') dbCategory = 'booking_issue';
    if (category == 'Payment Issue') dbCategory = 'payment_issue';
    if (category == 'Facility Problem') dbCategory = 'facility_problem';
    if (category == 'Account Issue') dbCategory = 'account_issue';

    final inserted = await _supabase
        .from('reports')
        .insert({
          'report_reference': ref,
          'user_id': user.id,
          'related_booking_id': bookingId,
          'category': dbCategory,
          'is_refund_request': false,
          'subject': finalSubject,
          'description': description,
          'status': 'submitted',
        })
        .select('id')
        .single();

    final reportId = inserted['id']?.toString();
    if (reportId != null && photos.isNotEmpty) {
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final ext = photo.name.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final storagePath =
            '${user.id}/$reportId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

        await _supabase.storage
            .from(reportBucket)
            .uploadBinary(
              storagePath,
              photo.bytes,
              fileOptions: FileOptions(contentType: mime, upsert: true),
            );

        await _supabase.from('report_attachments').insert({
          'report_id': reportId,
          'storage_path': storagePath,
          'file_name': photo.name,
          'mime_type': mime,
          'file_size_bytes': photo.bytes.length,
        });
      }
    }

    return JsonMap.from(inserted);
  }

  Future<List<dynamic>> getUserReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('reports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response as List<dynamic>;
  }

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
        'confirmed' =>
          row['is_demo'] == true ? 'Demo paid & confirmed' : 'Paid & Confirmed',
        'pending_payment' => 'Reserved - awaiting payment',
        'expired' => 'Expired - unpaid',
        _ => status,
      };
      final paid = (row['payments'] as List? ?? [])
          .cast()
          .where((p) => p['status'] == 'paid')
          .firstOrNull;
      final groups = <String, List>{};
      for (final raw in (row['booking_items'] as List? ?? [])) {
        final item = JsonMap.from(raw as Map);
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
            paidAt: paid?['paid_at'],
            paymentRef: paid?['transaction_reference'] ?? paid?['billplz_id'],
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