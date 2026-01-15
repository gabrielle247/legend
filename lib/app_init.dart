import 'package:flutter/material.dart';
import 'package:legend/constants/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legend/services/database_serv.dart';

class AppInit {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Supabase first
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      debug: false,
    );
    debugPrint("✅ Supabase initialized");

    // 2. Initialize PowerSync Database (offline-first layer)
    await DatabaseService().initializeStandalone();
    debugPrint("✅ PowerSync standalone mode ready (awaiting auth)");

    // Simulate startup delay for splash effect
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint("✅ AppInit complete");
  }
}

