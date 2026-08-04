import 'package:flutter_test/flutter_test.dart';

import 'package:arc_app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ArcApp());
    expect(find.byType(ArcApp), findsOneWidget);
  });
}
