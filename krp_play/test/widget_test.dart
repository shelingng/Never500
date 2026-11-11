import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/main.dart';

void main() {
  testWidgets('KrpPlayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KrpPlayApp());
    expect(find.textContaining('KRP PLAY'), findsWidgets);
  });
}
