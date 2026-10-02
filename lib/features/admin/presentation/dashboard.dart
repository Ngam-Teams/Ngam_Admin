// =============================================================================
// Dashboard
// Master layout for the Ngam Admin Super Admin portal.
// Dark glassmorphism aesthetic with NavigationRail + content area (§5.2).
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:intl/intl.dart';

import '../data/api_service.dart';
import 'business_directory_view.dart';
import 'billing_view.dart';
import 'db_health_view.dart';
import 'settings_view.dart';
import 'kyc_verification_view.dart';
import 'payout_clearinghouse_view.dart';
import 'impersonation_view.dart';
import 'system_control_view.dart';
import 'platform_revenue_view.dart';
import 'subscription_manager_view.dart';
import 'widgets/stat_card.dart';
import 'widgets/bottom_nav.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String? _activeSubView;

  static const _navItems = [
    (icon: HugeIcons.strokeRoundedHome11, label: 'Overview'),
    (icon: HugeIcons.strokeRoundedNote01, label: 'Businesses'),
    (icon: HugeIcons.strokeRoundedInvoice01, label: 'Billing'),
    (icon: HugeIcons.strokeRoundedDatabase01, label: 'DB Health'),
    (icon: HugeIcons.strokeRoundedSettings01, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A14),
          extendBody: true,
          bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
          body: SafeArea(
            bottom: false,
            child: isDesktop
                ? Row(
                    children: [
                      _buildNavigationRail(),
                      Expanded(child: _buildContent(isDesktop)),
                    ],
                  )
                : _buildContent(isDesktop),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNav(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() {
        _selectedIndex = index;
        _activeSubView = null;
      }),
      items: _navItems.map((item) {
        return NavItem(
          icon: item.icon,
          title: item.label,
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation Rail (frosted glass sidebar)
  // ---------------------------------------------------------------------------

  Widget _buildNavigationRail() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 220,
          color: Colors.white.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo / Wordmark
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Nav items
              ..._navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final selected = index == _selectedIndex && _activeSubView == null;

                return _NavItem(
                  icon: item.icon,
                  label: item.label,
                  selected: selected,
                  onTap: () => setState(() {
                    _selectedIndex = index;
                    _activeSubView = null;
                  }),
                );
              }),

              const Spacer(),

              // Bottom spacer for rail
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content Area
  // ---------------------------------------------------------------------------

  Widget _buildContent(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        isDesktop ? 32 : 16,
        isDesktop ? 32 : 16,
        isDesktop ? 32 : 0, // Removed extra bottom padding so content scrolls under navbar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pageTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Super Admin Portal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              _buildTopBarActions(),
            ],
          ),

          const SizedBox(height: 12),

          // Page body
          Expanded(child: _buildPageBody(isDesktop)),
        ],
      ),
    );
  }

  String get _pageTitle {
    if (_activeSubView != null) {
      return switch (_activeSubView) {
        'kyc' => 'SSM & KYC Verification',
        'payouts' => 'DuitNow Payouts',
        'impersonation' => 'Merchant Impersonation',
        'killswitch' => 'Platform Controls',
        'revenue' => 'Revenue & Take-Rate',
        'subscriptions' => 'Plans & Overrides',
        _ => 'Super Admin',
      };
    }
    return switch (_selectedIndex) {
      0 => 'Overview',
      1 => 'Business Directory',
      2 => 'Billing',
      3 => 'DB Health',
      4 => 'Settings',
      _ => 'Admin',
    };
  }

  Widget _buildPageBody(bool isDesktop) {
    if (_activeSubView != null) {
      return switch (_activeSubView) {
        'kyc' => KycVerificationView(onBack: () => setState(() => _activeSubView = null)),
        'payouts' => PayoutClearinghouseView(onBack: () => setState(() => _activeSubView = null)),
        'impersonation' => ImpersonationView(onBack: () => setState(() => _activeSubView = null)),
        'killswitch' => SystemControlView(onBack: () => setState(() => _activeSubView = null)),
        'revenue' => PlatformRevenueView(onBack: () => setState(() => _activeSubView = null)),
        'subscriptions' => SubscriptionManagerView(onBack: () => setState(() => _activeSubView = null)),
        _ => _buildOverviewPage(isDesktop),
      };
    }
    return IndexedStack(
      index: _selectedIndex.clamp(0, 4),
      children: [
        _buildOverviewPage(isDesktop),
        const BusinessDirectoryView(),
        const BillingView(),
        const DbHealthView(),
        const SettingsView(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Overview Page – stat cards grid
  // ---------------------------------------------------------------------------

  Widget _buildOverviewPage(bool isDesktop) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().fetchDashboardStats(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final formatCurrency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

        final rev = data?['platformRevenue'] ?? 0.0;
        final businesses = data?['totalBusinesses']?.toString() ?? '—';
        final active = data?['activeCount']?.toString() ?? '—';
        final suspended = data?['suspendedCount']?.toString() ?? '—';

        final cards = [
          StatCard(
            label: 'Platform Revenue',
            value: data == null ? '...' : formatCurrency.format(rev),
            subtitle: '↑ Expected collection this month',
            icon: HugeIcons.strokeRoundedChartIncrease,
            accentColor: const Color(0xFF6C63FF),
          ),
          StatCard(
            label: 'Total Businesses',
            value: data == null ? '...' : businesses,
            subtitle: 'Registered businesses',
            icon: HugeIcons.strokeRoundedBuilding03,
            accentColor: const Color(0xFF4ECDC4),
          ),
          StatCard(
            label: 'Active Subscriptions',
            value: data == null ? '...' : active,
            subtitle: 'Active / Trial businesses',
            icon: HugeIcons.strokeRoundedTickDouble01,
            accentColor: const Color(0xFF44CF6C),
          ),
          StatCard(
            label: 'Suspended Accounts',
            value: data == null ? '...' : suspended,
            icon: HugeIcons.strokeRoundedCancel01,
            accentColor: const Color(0xFFFF6B6B),
          ),
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1000) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 2;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Responsive Stat Cards
              _buildResponsiveStatCards(cards, crossAxisCount),
              const SizedBox(height: 24),

              // 2. Pusat Kawalan Pantas Super Admin (Quick Command Center)
              _buildSuperAdminCommandCenter(isDesktop),
              const SizedBox(height: 24),

              // 3. Responsive Dashboard Widgets
              if (width >= 1000)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRecentActivity()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildSystemHealth(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildRecentActivity(),
                    const SizedBox(height: 24),
                    _buildSystemHealth(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              // 3. Optional loading/error indicator
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading stats: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
        );
      }, // closes LayoutBuilder builder
    ); // closes LayoutBuilder
      }, // closes FutureBuilder builder
    ); // closes FutureBuilder
  } // closes _buildOverviewPage

  Widget _buildResponsiveStatCards(List<Widget> cards, int crossAxisCount) {
    if (crossAxisCount == 4) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: cards.indexOf(c) == 0 ? 0 : 16.0),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else if (crossAxisCount == 2) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildSystemHealth() {
    return _buildPanel(
      title: 'System Snapshot',
      icon: HugeIcons.strokeRoundedActivity01,
      child: Column(
        children: [
          _buildHealthRow('Uptime', '99.99%', const Color(0xFF44CF6C)),
          const SizedBox(height: 12),
          _buildHealthRow('DB Load', '42%', const Color(0xFFF9C80E)),
          const SizedBox(height: 12),
          _buildHealthRow('Active Conns', '1,204', const Color(0xFF6C63FF)),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      (time: 'Just now', event: 'New business registered: Barbera', icon: HugeIcons.strokeRoundedBuilding03, color: const Color(0xFF4ECDC4)),
      (time: '2h ago', event: 'Subscription upgraded: Coffee Shop', icon: HugeIcons.strokeRoundedArrowUp02, color: const Color(0xFF6C63FF)),
      (time: '5h ago', event: 'Database backup completed', icon: HugeIcons.strokeRoundedDatabase01, color: const Color(0xFF44CF6C)),
      (time: '1d ago', event: 'Account suspended: Test Corp', icon: HugeIcons.strokeRoundedCancel01, color: const Color(0xFFFF6B6B)),
    ];

    return _buildPanel(
      title: 'Recent Activity',
      icon: HugeIcons.strokeRoundedClock01,
      child: Column(
        children: activities
            .map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(icon: a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.event, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(a.time, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSuperAdminCommandCenter(bool isDesktop) {
    final commands = [
      (
        title: 'SSM & KYC Hub',
        subtitle: 'Verifikasi pendaftaran SSM & akaun peniaga',
        icon: HugeIcons.strokeRoundedLegal01,
        color: const Color(0xFF6C63FF),
        badge: '3 Menunggu',
        badgeColor: const Color(0xFFF59E0B),
        subView: 'kyc',
      ),
      (
        title: 'DuitNow Clearing',
        subtitle: 'Pelepasan dana escrow harian ke akaun bank',
        icon: HugeIcons.strokeRoundedBank,
        color: const Color(0xFF10B981),
        badge: 'RM 42.8k',
        badgeColor: const Color(0xFF10B981),
        subView: 'payouts',
      ),
      (
        title: 'Ghost Impersonate',
        subtitle: 'Masuk pandangan kedai untuk bantuan teknikal',
        icon: HugeIcons.strokeRoundedUserAccount,
        color: const Color(0xFFF59E0B),
        badge: '1-Klik Akses',
        badgeColor: const Color(0xFF6C63FF),
        subView: 'impersonation',
      ),
      (
        title: 'Platform Kill-Switch',
        subtitle: 'Suis kecemasan & mod penyelenggaraan',
        icon: HugeIcons.strokeRoundedShield01,
        color: const Color(0xFFEF4444),
        badge: 'Normal 99.9%',
        badgeColor: const Color(0xFF10B981),
        subView: 'killswitch',
      ),
      (
        title: 'Hasil & Take-Rate',
        subtitle: 'Analisis komisen MDR 1.5% & SaaS MRR',
        icon: HugeIcons.strokeRoundedChartIncrease,
        color: const Color(0xFF4ECDC4),
        badge: 'RM 40.8k Net',
        badgeColor: const Color(0xFF4ECDC4),
        subView: 'revenue',
      ),
      (
        title: 'Plan & Overrides',
        subtitle: 'Lanjut trial percuma, ubah tier & gantung',
        icon: HugeIcons.strokeRoundedCrown02,
        color: const Color(0xFF8B5CF6),
        badge: '5 Merchant',
        badgeColor: const Color(0xFF8B5CF6),
        subView: 'subscriptions',
      ),
    ];

    return _buildPanel(
      title: 'Pusat Kawalan Pantas Super Admin',
      icon: HugeIcons.strokeRoundedCommand,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: commands.map((cmd) {
              final cardWidth = isWide ? (constraints.maxWidth - 24) / 3 - 1 : (constraints.maxWidth - 12) / 2 - 1;
              return InkWell(
                onTap: () => setState(() => _activeSubView = cmd.subView),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cmd.color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cmd.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: HugeIcon(icon: cmd.icon, color: cmd.color, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cmd.badgeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cmd.badge,
                              style: TextStyle(color: cmd.badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        cmd.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cmd.subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return _buildPanel(
      title: 'Tindakan Terus Super Admin',
      icon: HugeIcons.strokeRoundedZap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuickActionButton(
            label: 'SSM & KYC Approvals',
            icon: HugeIcons.strokeRoundedLegal01,
            onTap: () => setState(() => _activeSubView = 'kyc'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'DuitNow Payout Clearing',
            icon: HugeIcons.strokeRoundedBank,
            onTap: () => setState(() => _activeSubView = 'payouts'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'Ghost Login / Impersonate',
            icon: HugeIcons.strokeRoundedUserAccount,
            onTap: () => setState(() => _activeSubView = 'impersonation'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'Platform Emergency Controls',
            icon: HugeIcons.strokeRoundedShield01,
            onTap: () => setState(() => _activeSubView = 'killswitch'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'Platform Revenue & Take-Rate',
            icon: HugeIcons.strokeRoundedChartIncrease,
            onTap: () => setState(() => _activeSubView = 'revenue'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'Subscription Plan Manager',
            icon: HugeIcons.strokeRoundedCrown02,
            onTap: () => setState(() => _activeSubView = 'subscriptions'),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            label: 'Lihat Direktori Peniaga',
            icon: HugeIcons.strokeRoundedNote01,
            onTap: () => setState(() {
              _selectedIndex = 1;
              _activeSubView = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({required String title, required dynamic icon, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(icon: icon, color: const Color(0xFF6C63FF), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Top bar actions
  // ---------------------------------------------------------------------------

  Widget _buildTopBarActions() {
    return Row(
      children: [
        IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedNotification02, color: Colors.white54, size: 20, strokeWidth: 2.1),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Color(0xFF6C63FF), size: 18, strokeWidth: 2.1),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nav Item
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: selected ? const Color(0xFF6C63FF) : Colors.white38,
              size: 20,
              strokeWidth: 2.1,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Action Button
// ---------------------------------------------------------------------------

class _QuickActionButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: const Color(0xFF6C63FF), size: 18, strokeWidth: 2.1),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
