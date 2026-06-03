import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rdobhvuiadmsqdfugrlp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb2JodnVpYWRtc3FkZnVncmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjU4MzMsImV4cCI6MjA5NDc0MTgzM30.7pvs8B38unEmBkPmP14lfgDrr59wjd-WroMiqpkIzvY',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit, // ป้องกัน code verifier warning บน web
      ),
    );
  }

  User? getCurrentUser() => client.auth.currentUser;

  Future<void> signOut() async => client.auth.signOut();
}
