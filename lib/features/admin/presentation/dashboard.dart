// =============================================================================
// Dashboard
// Master layout for the Ngam Admin Super Admin portal.
// Dark glassmorphism aesthetic with NavigationRail + content area (§5.2).
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

import 'platform_revenue_view.dart';
import 'subscription_manager_view.dart';
import 'support_tickets_view.dart';
import 'disputes_view.dart';
import 'widgets/bottom_nav.dart';
import '../../../core/services/app_update_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  /// Preserves sidebar expanded/collapsed state across tab & route changes.
  static final ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(true);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String? _activeSubView;

  @override
  void initState() {
    super.initState();
    AppUpdateService.checkOnStartup(context);
  }

  static const _navItems = [
    (icon: HugeIcons.strokeRoundedHome11, label: 'Overview'),
    (icon: HugeIcons.strokeRoundedNote01, label: 'Businesses'),
    (icon: HugeIcons.strokeRoundedInvoice01, label: 'Billing'),
    (icon: HugeIcons.strokeRoundedRocket, label: 'DevOps'),
    (icon: HugeIcons.strokeRoundedSettings01, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isCompactHeight = constraints.maxHeight < 520;
        final useSidebar = constraints.maxWidth >= 768 || isLandscape;
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A14),
          extendBody: true,
          bottomNavigationBar: useSidebar ? null : _buildBottomNav(),
          body: SafeArea(
            bottom: false,
            child: useSidebar
                ? Row(
                    children: [
                      _buildNavigationRail(
                        isCompactHeight: isCompactHeight,
                        maxAvailableWidth: constraints.maxWidth,
                      ),
                      Expanded(child: _buildContent(useSidebar)),
                    ],
                  )
                : _buildContent(useSidebar),
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
  // Navigation Rail (Floating Collapsible Liquid Glass Sidebar — Ngam / Business)
  // ---------------------------------------------------------------------------

  Widget _buildNavigationRail({
    bool isCompactHeight = false,
    double maxAvailableWidth = 1000,
  }) {
    final user = Supabase.instance.client.auth.currentUser;
    final String adminName = (user?.userMetadata?['full_name'] ??
            user?.email?.split('@').first ??
            'Super Admin')
        .toString()
        .trim();
    final String adminSub = (user?.email ?? 'Super Admin Portal').toString();
    final double expandedWidth = (maxAvailableWidth * 0.35).clamp(180.0, 260.0);
    final double collapsedWidth = isCompactHeight ? 64.0 : 72.0;

    return ValueListenableBuilder<bool>(
      valueListenable: Dashboard.isExpandedNotifier,
      builder: (context, isExpanded, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isCompactHeight ? 10 : 16,
            isCompactHeight ? 8 : 16,
            0,
            isCompactHeight ? 8 : 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompactHeight ? 22 : 28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                width: isExpanded ? expandedWidth : collapsedWidth,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isCompactHeight ? 22 : 28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: isCompactHeight ? 8 : 16),

                    // Top Bar (Logo & Expand / Shrink Interactions)
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/app.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/splash.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'N',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ngam',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Color(0xFF42A5F5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _CollapseSidebarButton(
                              onTap: () => Dashboard.isExpandedNotifier.value = false,
                            ),
                          ],
                        ),
                      )
                    else
                      _LogoExpandButton(
                        brandName: 'Ngam Admin',
                        onTap: () => Dashboard.isExpandedNotifier.value = true,
                      ),

                    SizedBox(height: isCompactHeight ? 8 : 14),

                    // Admin Profile Section
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedIndex = 4;
                              _activeSubView = null;
                            }),
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: Colors.white.withValues(alpha: 0.08),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: isCompactHeight ? 5 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildAdminSidebarAvatar(
                                    adminName,
                                    isCompactHeight ? 14 : 17,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          adminName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 1.5),
                                        Text(
                                          adminSub,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Tooltip(
                        message: adminName,
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedIndex = 4;
                            _activeSubView = null;
                          }),
                          borderRadius: BorderRadius.circular(14),
                          child: _buildAdminSidebarAvatar(
                            adminName,
                            isCompactHeight ? 16 : 19,
                          ),
                        ),
                      ),

                    SizedBox(height: isCompactHeight ? 6 : 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 4 : 8),

                    // Nav items
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _navItems.length,
                        separatorBuilder: (_, __) => SizedBox(height: isCompactHeight ? 2 : 4),
                        itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final selected = index == _selectedIndex && _activeSubView == null;
                          return _SidebarNavItem(
                            icon: item.icon,
                            label: item.label,
                            selected: selected,
                            isExpanded: isExpanded,
                            isCompactHeight: isCompactHeight,
                            onTap: () => setState(() {
                              _selectedIndex = index;
                              _activeSubView = null;
                            }),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 4 : 6),

                    // Sign Out
                    _SidebarNavItem(
                      icon: HugeIcons.strokeRoundedLogout02,
                      label: 'Log Keluar',
                      selected: false,
                      isExpanded: isExpanded,
                      isCompactHeight: isCompactHeight,
                      onTap: () => _confirmAdminSignOut(context),
                    ),

                    SizedBox(height: isCompactHeight ? 8 : 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminSidebarAvatar(String name, double radius) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.88,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF141826),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAdminSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Keluar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Adakah anda pasti mahu log keluar daripada konsol Ngam Admin?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Log Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Content Area
  // ---------------------------------------------------------------------------

  Widget _buildContent(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        isDesktop ? 28 : 14,
        isDesktop ? 32 : 16,
        isDesktop ? 32 : 0, // Removed extra bottom padding so content scrolls under navbar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              if (_activeSubView != null) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _activeSubView = null),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pageTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 26 : 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Super Admin Portal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: isDesktop ? 13 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildTopBarActions(),
            ],
          ),

          const SizedBox(height: 14),

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
        'tickets' => 'Pusat Tiket & Lapor Bug',
        'disputes' => 'Pusat Pertikaian (Pemerhati & Penentu)',
        _ => 'Super Admin',
      };
    }
    return switch (_selectedIndex) {
      0 => 'Overview',
      1 => 'Business Directory',
      2 => 'Billing',
      3 => 'DevOps',
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
        'tickets' => SupportTicketsView(onBack: () => setState(() => _activeSubView = null)),
        'disputes' => DisputesView(onBack: () => setState(() => _activeSubView = null)),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Responsive 4 Stat Cards (2x2 Grid on Mobile like Pusat Operasi)
                  _buildAdminOverviewStats(
                    width: width,
                    data: data,
                    rev: rev,
                    businesses: businesses,
                    active: active,
                    suspended: suspended,
                    formatCurrency: formatCurrency,
                  ),
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
                  // 4. Optional loading/error indicator
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

  Widget _buildAdminOverviewStats({
    required double width,
    required Map<String, dynamic>? data,
    required dynamic rev,
    required String businesses,
    required String active,
    required String suspended,
    required NumberFormat formatCurrency,
  }) {
    final card0 = _buildAdminStatCard(
      label: 'Platform Revenue',
      value: data == null ? '...' : formatCurrency.format(rev),
      badge: 'Kutipan',
      badgeColor: const Color(0xFF6C63FF),
      icon: HugeIcons.strokeRoundedChartIncrease,
      accentColor: const Color(0xFF6C63FF),
      onTap: () => setState(() => _activeSubView = 'revenue'),
    );
    final card1 = _buildAdminStatCard(
      label: 'Total Businesses',
      value: data == null ? '...' : businesses,
      badge: 'Berdaftar',
      badgeColor: const Color(0xFF4ECDC4),
      icon: HugeIcons.strokeRoundedBuilding03,
      accentColor: const Color(0xFF4ECDC4),
      onTap: () => setState(() {
        _selectedIndex = 1;
        _activeSubView = null;
      }),
    );
    final card2 = _buildAdminStatCard(
      label: 'Active Subscriptions',
      value: data == null ? '...' : active,
      badge: 'Aktif',
      badgeColor: const Color(0xFF44CF6C),
      icon: HugeIcons.strokeRoundedTickDouble01,
      accentColor: const Color(0xFF44CF6C),
      onTap: () => setState(() => _activeSubView = 'subscriptions'),
    );
    final card3 = _buildAdminStatCard(
      label: 'Suspended Accounts',
      value: data == null ? '...' : suspended,
      badge: 'Perhatian',
      badgeColor: const Color(0xFFFF6B6B),
      icon: HugeIcons.strokeRoundedCancel01,
      accentColor: const Color(0xFFFF6B6B),
      onTap: () => setState(() {
        _selectedIndex = 1;
        _activeSubView = null;
      }),
    );

    if (width >= 1000) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: card0),
            const SizedBox(width: 12),
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card0),
                const SizedBox(width: 12),
                Expanded(child: card1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card2),
                const SizedBox(width: 12),
                Expanded(child: card3),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAdminStatCard({
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
    required dynamic icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: accentColor,
                      size: 20,
                      strokeWidth: 2.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final isSignedIn = Supabase.instance.client.auth.currentUser != null;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: isSignedIn
              ? Supabase.instance.client
                  .from('support_tickets')
                  .stream(primaryKey: ['id'])
                  .eq('status', 'open')
              : null,
          builder: (context, snapshot) {
            final openCount = snapshot.data?.length ?? 0;
            final ticketBadge = !isSignedIn
                ? 'Perlu Log Masuk'
                : (openCount > 0 ? '$openCount Baru' : 'Live Triage');
            final ticketBadgeColor = !isSignedIn
                ? const Color(0xFFF59E0B)
                : (openCount > 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF4ECDC4));

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
          (
            title: 'Pusat Tiket & Lapor Bug',
            subtitle: 'Triaj laporan pepijat, bukti tangkap layar & maklum balas pengguna/peniaga',
            icon: HugeIcons.strokeRoundedCustomerSupport,
            color: const Color(0xFF4ECDC4),
            badge: ticketBadge,
            badgeColor: ticketBadgeColor,
            subView: 'tickets',
          ),
        ];

        final disputesCard = StreamBuilder<List<Map<String, dynamic>>>(
          stream: isSignedIn ? ApiService().watchDisputes() : null,
          builder: (context, dispSnap) {
            final allDisp = dispSnap.data ?? const <Map<String, dynamic>>[];
            final activeDisp = allDisp.where((d) {
              final st = (d['status'] ?? '').toString();
              return !st.startsWith('resolved_') && st != 'withdrawn';
            }).length;
            final medDisp = allDisp.where((d) {
              final st = (d['status'] ?? '').toString();
              return st == 'escalated' || st == 'under_review';
            }).length;
            final dispBadge = !isSignedIn
                ? 'Perlu Log Masuk'
                : (medDisp > 0
                    ? '$medDisp Mediator'
                    : (activeDisp > 0 ? '$activeDisp Aktif' : 'Pemerhati'));

            return _buildCommandCard((
              title: 'Pusat Pertikaian (Pemerhati & Penentu)',
              subtitle:
                  'Pantau chat asal kedai-pelanggan, sertai mediasi 3-hala & putuskan escrow',
              icon: HugeIcons.strokeRoundedLegal01,
              color: const Color(0xFFF59E0B),
              badge: dispBadge,
              badgeColor: !isSignedIn
                  ? const Color(0xFFF59E0B)
                  : (medDisp > 0
                      ? const Color(0xFFA855F7)
                      : (activeDisp > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981))),
              subView: 'disputes',
            ));
          },
        );

        return _buildPanel(
          title: 'Pusat Kawalan Pantas Super Admin',
          icon: HugeIcons.strokeRoundedCommand,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              if (isWide) {
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[0])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[1])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[2])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[3])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[4])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[5])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[6])),
                          const SizedBox(width: 12),
                          Expanded(child: disputesCard),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[0])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[1])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[2])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[3])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[4])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCommandCard(commands[5])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCommandCard(commands[6])),
                          const SizedBox(width: 12),
                          Expanded(child: disputesCard),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildCommandCard(dynamic cmd) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeSubView = cmd.subView),
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (cmd.color as Color).withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: (cmd.color as Color).withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: (cmd.color as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HugeIcon(
                      icon: cmd.icon,
                      color: cmd.color as Color,
                      size: 20,
                      strokeWidth: 2.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (cmd.badgeColor as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cmd.badge,
                      style: TextStyle(
                        color: cmd.badgeColor as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                cmd.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 32,
                child: Text(
                  cmd.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            label: 'Pusat Tiket & Lapor Bug',
            icon: HugeIcons.strokeRoundedCustomerSupport,
            onTap: () => setState(() => _activeSubView = 'tickets'),
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final isSignedIn = Supabase.instance.client.auth.currentUser != null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Tiket & Laporan Bug',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _activeSubView = 'tickets'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification02,
                        color: Colors.white70,
                        size: 19,
                        strokeWidth: 2.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: isSignedIn
                  ? 'Profil & Tetapan'
                  : 'Log Masuk / Tetapan',
              child: InkWell(
                onTap: () => setState(() {
                  _selectedIndex = 4;
                  _activeSubView = null;
                }),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: Color(0xFF9C96FF),
                        size: 18,
                        strokeWidth: 2.1,
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: isSignedIn
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A0A14),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo Expand Button (Gemini Style: Hover logo -> Expand icon)
// ─────────────────────────────────────────────────────────────────────────────
class _LogoExpandButton extends StatefulWidget {
  final String brandName;
  final VoidCallback onTap;

  const _LogoExpandButton({
    required this.brandName,
    required this.onTap,
  });

  @override
  State<_LogoExpandButton> createState() => _LogoExpandButtonState();
}

class _LogoExpandButtonState extends State<_LogoExpandButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isHovered ? 'Expand sidebar' : widget.brandName,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _isHovered
                  ? const HugeIcon(
                      key: ValueKey('expand_icon'),
                      icon: HugeIcons.strokeRoundedSidebarLeft01,
                      color: Colors.white,
                      size: 20,
                      strokeWidth: 2.1,
                    )
                  : ClipRRect(
                      key: const ValueKey('logo_img'),
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/app.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/splash.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapse Button (Gemini Style: Top right icon button to collapse sidebar)
// ─────────────────────────────────────────────────────────────────────────────
class _CollapseSidebarButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CollapseSidebarButton({required this.onTap});

  @override
  State<_CollapseSidebarButton> createState() => _CollapseSidebarButtonState();
}

class _CollapseSidebarButtonState extends State<_CollapseSidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Collapse sidebar',
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSidebarLeft,
                color: Colors.white70,
                size: 18,
                strokeWidth: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Nav Item (Dual Mode: Icon + Text in Expand, Icon Only in Shrink)
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarNavItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final bool isExpanded;
  final bool isCompactHeight;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isExpanded,
    this.isCompactHeight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: Center(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isCompactHeight ? 12 : 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCompactHeight ? 42 : 48,
              height: isCompactHeight ? 42 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isCompactHeight ? 12 : 16),
                color: selected
                    ? const Color(0xFF42A5F5).withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF42A5F5).withValues(alpha: 0.35)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: selected ? const Color(0xFF42A5F5) : Colors.white38,
                  size: isCompactHeight ? 20 : 22,
                  strokeWidth: selected ? 2.3 : 1.9,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: isCompactHeight ? 1.5 : 3),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: isCompactHeight ? 7 : 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? const Color(0xFF42A5F5).withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? const Color(0xFF42A5F5).withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: selected ? const Color(0xFF42A5F5) : Colors.white38,
              size: isCompactHeight ? 18 : 20,
              strokeWidth: selected ? 2.3 : 1.9,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isCompactHeight ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
