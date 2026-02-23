import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sato_printers_example/main.dart';

void main() {
  testWidgets('renders zpl example actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SATO Printer ZPL Example'), findsOneWidget);
    expect(find.text('Discover Printers'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Send ZPL to Printer'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Send ZPL to Printer'), findsOneWidget);
  });
}
