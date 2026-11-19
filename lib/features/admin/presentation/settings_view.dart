import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/liquid_glass_compat.dart';
import '../../../core/services/app_update_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  LiquidGlassSettings _getGlassSettings() {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: 20,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: 0.1,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final user = Supabase.instance.client.auth.currentUser;
        final isSignedIn = user != null;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ─── Header Profil ───────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isSignedIn
                                  ? [
                                      const Color(0xFF6C63FF).withValues(alpha: 0.7),
                                      const Color(0xFF4ECDC4).withValues(alpha: 0.7),
                                    ]
                                  : [
                                      const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                      Colors.white24,
                                    ],
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: Color(0xFF141422),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isSignedIn ? 'Super Admin' : 'Mod Tetamu',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isSignedIn
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isSignedIn
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            isSignedIn ? 'SUPER ADMIN' : 'BELUM LOG MASUK',
                            style: TextStyle(
                              color: isSignedIn
                                  ? const Color(0xFFA5A0FF)
                                  : const Color(0xFFFBBF24),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'Sila log masuk untuk akses data langsung',
                          style: TextStyle(
                            color: isSignedIn ? Colors.white70 : Colors.white54,
                            fontSize: 13.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),

                  // ─── Akaun ───────────────────────────────────────────
                  _buildSectionHeader("Akaun"),
                  _buildGlassSection(
                    Column(
                      children: [
                        _buildSettingsTile(
                          HugeIcons.strokeRoundedUserEdit01,
                          "Butiran Akaun",
                          onTap: isSignedIn ? null : () => context.go('/login'),
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                        _buildSettingsTile(
                          HugeIcons.strokeRoundedShield01,
                          "Privasi & Keselamatan",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Pilihan ──────────────────────────────────────────
                  _buildSectionHeader("Pilihan"),
                  _buildGlassSection(
                    Column(
                      children: [
                        _buildSettingsTile(
                          HugeIcons.strokeRoundedGlobe02,
                          "Bahasa",
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Bahasa Melayu',
                                style: TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Sistem & Kemas Kini (Versi Aplikasi hanya di sini) ─
                  _buildSectionHeader("Sistem & Kemas Kini"),
                  _buildGlassSection(
                    Column(
                      children: [
                        _buildSettingsTile(
                          HugeIcons.strokeRoundedCloudDownload,
                          "Versi Aplikasi",
                          trailing: ValueListenableBuilder<String>(
                            valueListenable: AppUpdateService.versionNotifier,
                            builder: (context, ver, _) {
                              return ValueListenableBuilder<AppReleaseInfo?>(
                                valueListenable: AppUpdateService.availableUpdateNotifier,
                                builder: (context, update, _) {
                                  final hasUpdate = update != null;
                                  final Color statusColor = hasUpdate
                                      ? Colors.amberAccent
                                      : const Color(0xFF10B981);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: hasUpdate ? 0.16 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: statusColor.withValues(
                                              alpha: hasUpdate ? 0.45 : 0.30,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          hasUpdate
                                              ? 'Kemas Kini v${update.version}'
                                              : 'v$ver • TERKINI',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: 0.45),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          onTap: () {
                            final update = AppUpdateService.availableUpdateNotifier.value;
                            if (update != null) {
                              AppUpdateService.showUpdateDialog(context, update);
                            } else {
                              AppUpdateService.checkManually(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Butang Log Masuk / Log Keluar ───────────────────
                  if (isSignedIn)
                    _buildGlassButton(
                      context,
                      'Log Keluar',
                      Colors.redAccent,
                      () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    )
                  else
                    _buildGlassButton(
                      context,
                      'Log Masuk Akaun Super Admin',
                      const Color(0xFF6C63FF),
                      () => context.go('/login'),
                    ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  Widget _buildGlassSection(Widget child) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
      settings: _getGlassSettings(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildSettingsTile(dynamic icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing else Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
        settings: _getGlassSettings(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
