import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finora/main.dart';

void main() {
  testWidgets('shows empty transaction state after splash', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FinoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Finora'), findsOneWidget);
    expect(find.text('Start Tracking'), findsOneWidget);

    await tester.tap(find.text('Start Tracking'));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });
}
