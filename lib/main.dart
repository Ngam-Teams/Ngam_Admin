// =============================================================================
// main.dart
// Entry point for Ngam Admin – Super Admin Portal.
// Bootstraps Supabase, wires GoRouter, and applies the dark theme.
//
// ⚠️  Replace placeholder values with your actual Supabase project credentials:
//     SUPABASE_URL  →  https://<your-project-ref>.supabase.co
//     SUPABASE_ANON_KEY  →  your anon/public API key
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NgamAdminApp());
}

class NgamAdminApp extends StatefulWidget {
  const NgamAdminApp({super.key});

  @override
  State<NgamAdminApp> createState() => _NgamAdminAppState();
}

class _NgamAdminAppState extends State<NgamAdminApp> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    final String url = dotenv.env['SUPABASE_URL'] ?? 'https://rsueaoglsdxhzpupjljd.supabase.co';
    final String key = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_qP4whY5B6wxIasWOVGoPCw_vrhOXj_J';

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A14),
            ),
            home: const Scaffold(
              backgroundColor: Color(0xFF0A0A14),
              body: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
          );
        }

        return MaterialApp.router(
          title: 'Ngam Admin',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A14),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
              surface: const Color(0xFF0A0A14),
            ),
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
            ),
            iconTheme: const IconThemeData(color: Colors.white70),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
