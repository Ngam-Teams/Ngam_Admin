// =============================================================================
// AppRouter
// GoRouter configuration with super_admin guard (§5.1).
// Protects all /admin routes – redirects to /login or /unauthorized.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/admin/presentation/dashboard.dart';
import '../../features/admin/presentation/business_profile_page.dart';
import '../../features/admin/models/business_summary_model.dart';
import '../../features/auth/presentation/login_screen.dart';

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedLock, color: Colors.redAccent, size: 56, strokeWidth: 2.1),
            const SizedBox(height: 20),
            const Text(
              'Unauthorized',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have super_admin access.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final appRouter = GoRouter(
  initialLocation: '/admin',
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final isGoingToAdmin = state.uri.path.startsWith('/admin');

    if (isGoingToAdmin) {
      // Unauthenticated – redirect to login
      if (user == null) return '/login';

      // Verify the super_admin role via user_roles table
      try {
        final response = await Supabase.instance.client
            .from('user_roles')
            .select('role')
            .eq('user_id', user.id)
            .single();

        if (response['role'] != 'super_admin') {
          return '/unauthorized'; // Standard merchants kicked back out
        }
      } catch (e) {
        return '/unauthorized';
      }
    }

    return null; // Allow navigation
  },
  routes: [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: '/admin/business',
      builder: (context, state) {
        final business = state.extra as BusinessSummaryModel;
        return BusinessProfilePage(business: business);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) => const _UnauthorizedScreen(),
    ),
  ],
);
