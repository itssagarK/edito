import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edito/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  testWidgets('Edito App smoke test - launches Home Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EditoApp(),
      ),
    );

    // Settle all initial animations
    await tester.pumpAndSettle();

    // Verify EDITO title appears
    expect(find.text('EDITO'), findsOneWidget);
  });
}
