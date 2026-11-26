import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AdminReservationsSource {
  Future<List<Map<String, dynamic>>> loadAll();
}

class AdminAccessDenied implements Exception {
  const AdminAccessDenied();
}

/// Read every bounded server page before applying client-side filters.
/// The UI separately paginates the complete filtered result, so searches
/// include orders beyond Supabase's default row limit.
Future<List<Map<String, dynamic>>> readReservationPages(
  Future<List<Map<String, dynamic>>> Function(int from, int to) readPage, {
  int pageSize = 100,
}) async {
  if (pageSize < 1) throw ArgumentError.value(pageSize, 'pageSize');
  final rows = <String, Map<String, dynamic>>{};
  for (var offset = 0; ; offset += pageSize) {
    final page = await readPage(offset, offset + pageSize - 1);
    var added = 0;
    for (final row in page) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty)
        throw const FormatException('Missing reservation ID');
      if (!rows.containsKey(id)) {
        added++;
      }
      rows[id] = row;
    }
    if (page.length < pageSize) break;
    if (added == 0) throw StateError('Reservation pagination made no progress');
  }
  return rows.values.toList();
}

class SupabaseAdminReservationsSource implements AdminReservationsSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> loadAll() async {
    final owner = _client.auth.currentUser?.id;
    if (owner == null || await _client.rpc('is_admin') != true) {
      throw const AdminAccessDenied();
    }
    // Exclude newly inserted rows during this read. Realtime/manual refresh
    // loads a fresh view; do not change the ordering between server pages.
    String? cutoff;
    final rows = await readReservationPages((from, to) async {
      if (_client.auth.currentUser?.id != owner)
        throw const AdminAccessDenied();
      var query = _client
          .from('bookings')
          .select(
            '*, profiles!booking_user_id_fkey(full_name, matric_number, phone_number, student_category), '
            'booking_items(price, status, time_slots(slot_date, start_time, end_time, facilities(name))), '
            'payments(status, payment_method, payment_gateway, transaction_reference, billplz_id, paid_at, amount)',
          );
      if (cutoff != null) {
        query = query.lte('created_at', cutoff!);
      }
      final page = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(from, to);
      if (cutoff == null && page.isNotEmpty) {
        cutoff = page.first['created_at']?.toString();
      }
      return [for (final row in page) Map<String, dynamic>.from(row)];
    });
    if (_client.auth.currentUser?.id != owner) throw const AdminAccessDenied();
    return rows;
  }
}
