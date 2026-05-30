// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jadwalku/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize date formatting locale
    await initializeDateFormatting('id_ID', null);

    await tester.pumpWidget(const JadwalKuApp());
    expect(find.byType(JadwalKuApp), findsOneWidget);
    
    // Pump the 3.2 second splash screen delay timer
    await tester.pump(const Duration(milliseconds: 3200));
    // Pump 1 second to allow transition to complete and dispose the splash screen
    await tester.pump(const Duration(seconds: 1));
  });
}
