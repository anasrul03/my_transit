import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';

class SupabaseService {
  static Future<void> initialize() async {
    if (!EnvConstants.isConfigured) {
      throw Exception(
        'Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }
    
    await Supabase.initialize(
      url: EnvConstants.supabaseUrl,
      anonKey: EnvConstants.supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static GoTrueClient get auth => client.auth;
}

