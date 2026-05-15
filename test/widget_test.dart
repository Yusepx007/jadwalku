// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalku/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JadwalKuApp());
    expect(find.byType(JadwalKuApp), findsOneWidget);
  });
}
