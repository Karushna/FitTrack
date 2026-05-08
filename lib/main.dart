import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF5A1F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A1F),
          primary: const Color(0xFFFF5A1F),
          secondary: const Color(0xFF111827),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        fontFamily: 'Arial',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: hasSession
          ? const MainNavigationScreen()
          : const AuthScreen(),
    );
  }
}