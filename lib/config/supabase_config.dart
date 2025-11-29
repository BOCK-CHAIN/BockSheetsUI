// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}

// lib/config/supabase_config.dart
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class SupabaseConfig {
//   // For development, you can hardcode these values temporarily
//   // For production, use environment variables or a config service
  
//   static String get supabaseUrl {
//     if (kIsWeb) {
//       // For web, use compile-time constants or fetch from a config endpoint
//       return const String.fromEnvironment('SUPABASE_URL', 
//         defaultValue: 'YOUR_SUPABASE_URL_HERE');
//     }
//     // For mobile, you could still use dotenv if needed
//     return const String.fromEnvironment('SUPABASE_URL',
//       defaultValue: 'YOUR_SUPABASE_URL_HERE');
//   }
  
//   static String get supabaseAnonKey {
//     if (kIsWeb) {
//       return const String.fromEnvironment('SUPABASE_ANON_KEY',
//         defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE');
//     }
//     return const String.fromEnvironment('SUPABASE_ANON_KEY',
//       defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE');
//   }
  
//   static Future<void> initialize() async {
//     await Supabase.initialize(
//       url: supabaseUrl,
//       anonKey: supabaseAnonKey,
//     );
//   }
  
//   static SupabaseClient get client => Supabase.instance.client;
// }