import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edito/main.dart';

void main() {
  testWidgets('Edito App smoke test - launches Home Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EditoApp(),
      ),
    );

    // Verify EDITO title appears
    expect(find.text('EDITO'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
  });
}
