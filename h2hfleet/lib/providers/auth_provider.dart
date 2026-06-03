import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final currentUserProvider = StreamProvider<User?>((ref) {
  return SupabaseService().client.auth.onAuthStateChange.map((e) => e.session?.user);
});

class AuthRepository {
  final _supabase = SupabaseService();

  Future<UserModel?> login(String email, String password) async {
    final response = await _supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) return null;

    // maybeSingle() คืน null แทน throw เมื่อไม่พบ row
    final userRow = await _supabase.client
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    if (userRow == null) return null;
    return UserModel.fromJson(userRow);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
  }) async {
    final response = await _supabase.client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) return false;

    // สร้าง company ก่อน
    final company = await _supabase.client
        .from('companies')
        .insert({'name': companyName, 'plan': 'free'})
        .select()
        .single();

    // สร้าง user profile โดยใช้ auth uid เป็น id
    await _supabase.client.from('users').insert({
      'id': response.user!.id,
      'email': email,
      'name': name,
      'company_id': company['id'],
      'role': 'owner',
    });

    return true;
  }

  Future<void> logout() => _supabase.signOut();

  User? getCurrentUser() => _supabase.getCurrentUser();
}
