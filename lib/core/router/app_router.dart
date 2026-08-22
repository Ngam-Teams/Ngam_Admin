// =============================================================================
// AppRouter
// GoRouter configuration with super_admin guard (§5.1).
// Protects all /console routes – redirects to /login or /unauthorized.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/console/presentation/dashboard.dart';
import '../../features/console/presentation/business_profile_page.dart';
import '../../features/console/models/business_summary_model.dart';

// ---------------------------------------------------------------------------
// Placeholder screens (replace with real auth/error screens as needed)
// ---------------------------------------------------------------------------

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/console');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedShield01, color: Color(0xFF6C63FF), size: 48, strokeWidth: 2.1),
              const SizedBox(height: 24),
              const Text('Ngam Console Login', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  initialLocation: '/console',
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final isGoingToConsole = state.uri.path.startsWith('/console');

    if (isGoingToConsole) {
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
      path: '/console',
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: '/console/business',
      builder: (context, state) {
        final business = state.extra as BusinessSummaryModel;
        return BusinessProfilePage(business: business);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const _LoginScreen(),
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) => const _UnauthorizedScreen(),
    ),
  ],
);
