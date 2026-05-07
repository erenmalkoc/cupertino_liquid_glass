import 'package:cupertino_liquid_glass_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app boots and renders default tab title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await tester.pump();

    expect(find.text('Gallery'), findsWidgets);
  });
}
