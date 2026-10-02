import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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
    final user = Supabase.instance.client.auth.currentUser;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ─── Header Profil ───────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white10,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Super Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "SUPER ADMIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'admin@ngam.app',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // ─── Akaun ───────────────────────────────────────────
              _buildSectionHeader("Account"),
              _buildGlassSection(
                Column(
                  children: [
                    _buildSettingsTile(
                      HugeIcons.strokeRoundedUserEdit01,
                      "Account Details",
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                    _buildSettingsTile(
                      HugeIcons.strokeRoundedShield01,
                      "Privacy & Security",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Pilihan ──────────────────────────────────────────
              _buildSectionHeader("Preferences"),
              _buildGlassSection(
                Column(
                  children: [
                    _buildSettingsTile(
                      HugeIcons.strokeRoundedGlobe02,
                      "Language",
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('English', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Sistem & Kemas Kini ─────────────────────────────
              _buildSectionHeader("System & Updates"),
              _buildGlassSection(
                Column(
                  children: [
                    _buildSettingsTile(
                      HugeIcons.strokeRoundedCloudDownload,
                      "Semak Kemas Kini",
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('v${AppUpdateService.currentVersion}', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                        ],
                      ),
                      onTap: () => AppUpdateService.checkManually(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Butang Log Keluar ───────────────────────────────
              _buildGlassButton(
                context,
                'Logout',
                Colors.redAccent,
                () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
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
