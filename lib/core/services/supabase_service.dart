import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Initializes dotenv and the Supabase client using environment variables.
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final supabasePublishableKey = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
            dotenv.env['SUPABASE_ANON_KEY'])
        ?.trim() ??
        '';

    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'Supabase configuration error: SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY '
        'must be defined in the .env file.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      debug: kDebugMode,
    );
  }
}
