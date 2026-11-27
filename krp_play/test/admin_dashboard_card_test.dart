import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/screens/admin/admin_metric_card.dart';

void main() {
  testWidgets('dashboard metric cards respond to taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdminMetricCard(
              width: 280,
              icon: Icons.calendar_today,
              iconBackground: Colors.green.shade50,
              title: 'DAILY BOOKINGS',
              value: '3',
              subtitle: 'View reservations',
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('DAILY BOOKINGS'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
