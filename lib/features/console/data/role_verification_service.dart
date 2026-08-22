// =============================================================================
// RoleVerificationService
// Validates that the currently authenticated user holds the `super_admin` role.
// Called once on app launch before rendering the Console.
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class RoleVerificationService {
  final SupabaseClient _client;

  RoleVerificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns `true` if the current user has the `super_admin` role.
  /// Throws a [RoleVerificationException] if the check fails or the user
  /// is not authenticated.
  Future<bool> isSuperAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw RoleVerificationException('User is not authenticated.');
    }

    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      return response['role'] == 'super_admin';
    } on PostgrestException catch (e) {
      throw RoleVerificationException('Role lookup failed: ${e.message}');
    } catch (e) {
      throw RoleVerificationException('Unexpected error during role verification: $e');
    }
  }

  /// Asserts super_admin access and throws if denied.
  Future<void> assertSuperAdmin() async {
    final ok = await isSuperAdmin();
    if (!ok) throw RoleVerificationException('Access denied – super_admin role required.');
  }
}

class RoleVerificationException implements Exception {
  final String message;
  const RoleVerificationException(this.message);

  @override
  String toString() => 'RoleVerificationException: $message';
}
