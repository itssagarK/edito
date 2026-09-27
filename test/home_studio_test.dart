import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edito/core/constants/edito_brand.dart';
import 'package:edito/features/home/presentation/home_screen.dart';
import 'package:edito/features/home/presentation/widgets/ai_tools_hub.dart';
import 'package:edito/features/home/presentation/widgets/new_project_button.dart';
import 'package:edito/features/home/presentation/widgets/project_card.dart';
import 'package:edito/features/home/providers/project_list_provider.dart';
import 'package:edito/features/image_editor/models/video_layout_config.dart';
import 'package:edito/models/project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Animate.restartOnHotReload = false;
  });

  group('Edito Pro Studio UI/UX & Creative Resources Suite Tests', () {
    test('EditoBrand constants contain 36 CapCut studio lighting colors and 16 gradient pairs', () {
      expect(EditoBrand.appName, equals('Edito'));
      expect(EditoBrand.appTitle, equals('Edito Pro'));
      expect(EditoBrand.proBadge, equals('PRO'));
      expect(EditoBrand.aiBadge, equals('AI'));

      // Studio Lighting Palette (extracted from CapCut Pro smart_relight_colors.txt)
      expect(EditoBrand.studioLightingPalette.length, equals(36));
      expect(EditoBrand.studioLightingPalette.first, equals(const Color(0xFFFFFFFF)));

      // Gradient Pairs (extracted from CapCut Pro newBlendColors.txt)
      expect(EditoBrand.studioGradientPairs.length, equals(16));
      expect(EditoBrand.studioGradientPairs.first.length, equals(2));
    });

    test('ProjectListNotifier supports creating with ratio, duplicate, and rename', () async {
      final notifier = ProjectListNotifier();

      // 1. Create with 9:16 aspect ratio
      final verticalProj = await notifier.createNewProjectWithRatio(
        VideoLayoutRatio.ratio9_16,
        title: 'TikTok Viral Clip',
      );
      expect(verticalProj.title, equals('TikTok Viral Clip'));
      expect(verticalProj.width, equals(1080));
      expect(verticalProj.height, equals(1920));
      expect(verticalProj.layoutConfig.ratio, equals(VideoLayoutRatio.ratio9_16));

      // 2. Duplicate project
      final dup = await notifier.duplicateProject(verticalProj);
      expect(dup.id, isNot(equals(verticalProj.id)));
      expect(dup.title, equals('TikTok Viral Clip (Copy)'));
      expect(dup.width, equals(1080));
      expect(dup.height, equals(1920));

      // 3. Rename project
      await notifier.renameProject(dup.id, 'Renamed Master Cut');
      final renamed = notifier.state.firstWhere((p) => p.id == dup.id);
      expect(renamed.title, equals('Renamed Master Cut'));
    });

    testWidgets('AiToolsHub renders all CapCut Pro style tools with one-tap callbacks', (tester) async {
      String selectedTool = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiToolsHub(
              onToolSelected: (tool) {
                selectedTool = tool.name;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edito AI Studio & Quick Tools'), findsOneWidget);
      expect(find.text('PRO TIER'), findsOneWidget);
      expect(find.text('Auto Captions'), findsOneWidget);
      expect(find.text('AI Relight'), findsOneWidget);
      expect(find.text('Voice Changer'), findsOneWidget);
      expect(find.text('Video Glow'), findsOneWidget);
      expect(find.text('De-Noise'), findsOneWidget);
      expect(find.text('Smart Mosaic'), findsOneWidget);

      // Tap on Voice Changer tool
      final voiceChangerFinder = find.byKey(const ValueKey('home_ai_tool_voiceEffects'));
      expect(voiceChangerFinder, findsOneWidget);
      await tester.tap(voiceChangerFinder);
      expect(selectedTool, equals('voiceEffects'));
    });

    testWidgets('NewProjectButton renders ratio selector chips', (tester) async {
      VideoLayoutRatio? selectedRatio;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewProjectButton(
              onPressed: () {},
              onRatioSelected: (ratio) {
                selectedRatio = ratio;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Project'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('9:16'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('4:5'), findsOneWidget);

      // Tap 9:16 ratio chip
      await tester.tap(find.text('9:16'));
      expect(selectedRatio, equals(VideoLayoutRatio.ratio9_16));
    });

    testWidgets('ProjectCard displays ratio badge, clip count, and action menu', (tester) async {
      bool deleted = false;
      bool renamed = false;
      bool duplicated = false;

      final project = Project(
        id: 'proj_card_test_01',
        title: 'Cinematic Reel',
        width: 1080,
        height: 1920,
        durationMs: 15000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: project,
              onTap: () {},
              onDelete: () => deleted = true,
              onRename: () => renamed = true,
              onDuplicate: () => duplicated = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cinematic Reel'), findsOneWidget);
      expect(find.text('9:16'), findsOneWidget); // Vertical badge
      expect(find.text('0 clips'), findsOneWidget);

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Open Project'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Duplicate
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(duplicated, isTrue);
    });

    testWidgets('HomeScreen renders Edito Pro Studio branding and creative hubs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top Brand Header
      expect(find.text('EDITO'), findsOneWidget);
      expect(find.text('PRO'), findsNWidgets(2)); // Header PRO + New Project PRO
      expect(find.text('AI Creative Studio'), findsOneWidget);

      // Search & Filters
      expect(find.text('Recent Projects'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Vertical (9:16)'), findsOneWidget);
      expect(find.text('Landscape (16:9)'), findsOneWidget);
    });
  });
}
