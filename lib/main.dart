import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  // Gracefully initialize Supabase
  bool isBackendInitialized = false;
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl != null &&
        supabaseAnonKey != null &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      isBackendInitialized = true;
    } else {
      debugPrint('Supabase credentials missing from .env');
    }
  } catch (e) {
    debugPrint(
      'Supabase initialization failed (running in offline/mock mode): $e',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        // We can override state providers here for testing if needed
      ],
      child: FluentArcApp(isBackendInitialized: isBackendInitialized),
    ),
  );
}

class FluentArcApp extends StatelessWidget {
  final bool isBackendInitialized;

  const FluentArcApp({super.key, required this.isBackendInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FluentArc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
    );
  }
}
