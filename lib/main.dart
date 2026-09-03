import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReportingService.initialize();

  // Lock status bar and navigation styling for cinematic dark UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121216),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: EditoApp(),
    ),
  );
}

class EditoApp extends StatelessWidget {
  const EditoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
