import 'package:flutter_test/flutter_test.dart';

import 'package:amedspor_app/main.dart';

void main() {
  testWidgets('renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AmedsporApp());

    await tester.pump();

    expect(find.text('AMEDSPOR'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });
}
