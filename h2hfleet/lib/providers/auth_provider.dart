import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final currentUserProvider = StreamProvider<User?>((ref) {
  final client = SupabaseService().client;
  return client.auth.onAuthStateChange.asyncMap((data) async {
    final user = data.session?.user;
    if (user != null) {
      await ref.read(authRepositoryProvider).ensureUserProfile(user);
    }
    return user;
  });
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
    var userRow = await _supabase.client
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    if (userRow == null) {
      await ensureUserProfile(response.user!);
      userRow = await _supabase.client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();
    }

    if (userRow == null) {
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: response.user!.userMetadata?['full_name'] ??
            response.user!.userMetadata?['name'] ??
            email.split('@').first,
        companyId: 'default',
        role: 'owner',
      );
    }
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
      data: {
        'full_name': name,
        'company_name': companyName,
      },
    );

    if (response.user == null) return false;

    try {
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
    } catch (_) {
      // ignore if RLS or email confirmation is pending
    }

    return true;
  }

  String _getAuthRedirectUrl() {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'com.h2hfleet.app://login-callback/';
  }

  Future<bool> signInWithGoogle() async {
    return await _supabase.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _getAuthRedirectUrl(),
    );
  }

  Future<bool> signInWithApple() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
        // ─── Native Apple Sign In (Face ID / Passcode) ────────────────────
        final rawNonce = _generateRandomString();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken == null) return false;

        final authResponse = await _supabase.client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );

        if (authResponse.user != null) {
          final fullName = [
            credential.givenName,
            credential.familyName,
          ].where((n) => n != null && n.isNotEmpty).join(' ');

          if (fullName.isNotEmpty) {
            await _supabase.client.auth.updateUser(
              UserAttributes(data: {'full_name': fullName, 'name': fullName}),
            );
          }
          await ensureUserProfile(authResponse.user!);
          return true;
        }
        return false;
      } else {
        // ─── Web / Fallback OAuth Flow ──────────────────────────────────
        return await _supabase.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: _getAuthRedirectUrl(),
        );
      }
    } catch (e) {
      debugPrint('Sign in with Apple error: $e');
      rethrow;
    }
  }

  String _generateRandomString([int length = 32]) {
    final random = math.Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// ตรวจสอบและสร้าง company/user profile หากเพิ่งล็อกอินผ่าน OAuth ครั้งแรก
  Future<void> ensureUserProfile(User user) async {
    try {
      final existingUser = await _supabase.client
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        final email = user.email ?? 'user_${user.id.substring(0, 6)}@h2hfleet.app';
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            email.split('@').first;
        final companyName = '$name Fleet';

        // สร้าง company อัตโนมัติสำหรับบัญชีใหม่
        final company = await _supabase.client
            .from('companies')
            .insert({'name': companyName, 'plan': 'free'})
            .select()
            .single();

        await _supabase.client.from('users').insert({
          'id': user.id,
          'email': email,
          'name': name,
          'company_id': company['id'],
          'role': 'owner',
        });
      }
    } catch (_) {
      // ignore if user already exists or handled by DB trigger
    }
  }

  Future<void> logout() => _supabase.signOut();

  User? getCurrentUser() => _supabase.getCurrentUser();
}

