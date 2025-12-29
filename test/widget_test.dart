import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shader_example/main.dart';

void main() {
  testWidgets('Splash screen shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FestiveShaderApp());

    // Verify that the splash screen shows
    expect(find.text('FESTIVE\nSHADER\nJOURNEY'), findsOneWidget);
  });
}
