import 'package:flutter_test/flutter_test.dart';
import 'package:smn/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SMNApp());
  });
}
