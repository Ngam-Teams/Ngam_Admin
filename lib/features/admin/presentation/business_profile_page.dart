// =============================================================================
// BusinessProfilePage
// Full-screen view of a business's complete registration profile including
// core identity, compliance, and settings data per the Ngam schema.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../data/api_service.dart';
import '../models/business_summary_model.dart';
import '../../../widgets/glass_toast.dart';

class BusinessProfilePage extends StatefulWidget {
  final BusinessSummaryModel business;

  const BusinessProfilePage({super.key, required this.business});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Glass helpers
  // ---------------------------------------------------------------------------

  static LiquidGlassSettings _glass({double blur = 2.0}) => LiquidGlassSettings(
    thickness: 0.1,
    blur: blur,
    refractiveIndex: 1.0,
    glassColor: Colors.transparent,
    lightAngle: 45.0,
    lightIntensity: 0.1,
    ambientStrength: 1.0,
    saturation: 1.0,
    chromaticAberration: 0.0,
  );

  static Widget _glassCard({
    required Widget child,
    double radius = 16.0,
    EdgeInsetsGeometry? padding,
    Color? overrideColor,
    Color? overrideBorder,
  }) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: _glass(),
      child: Container(
        padding: padding,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: overrideColor ?? Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: overrideBorder ?? Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  static Widget _sectionHeader(String title, dynamic icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: color, size: 18, strokeWidth: 2.0),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _field(
    String label,
    String? value, {
    bool isMonospace = false,
    bool copyable = false,
    BuildContext? context,
  }) {
    final display = (value == null || value.isEmpty) ? '—' : value;
    final isMissing = value == null || value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: isMissing
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      fontFamily: isMonospace ? 'monospace' : null,
                      fontSize: 12,
                      fontWeight: isMissing ? FontWeight.w400 : FontWeight.w600,
                      fontStyle: isMissing
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                if (copyable && !isMissing && context != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      showGlassToast(context, '$label copied!', duration: const Duration(seconds: 2));
                    },
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCopy01,
                      color: Colors.cyanAccent,
                      size: 14,
                      strokeWidth: 2.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _divider() =>
      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);

  static Widget _buildMiniStat(String label, String value, dynamic icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: const Color(0xFF42A5F5), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget _chip(String label, Color color, [dynamic icon]) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          HugeIcon(icon: icon, color: color, size: 12),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final categoryColor = const Color(0xFF42A5F5);

    final statusColor = switch (business.status.toLowerCase()) {
      'active' => Colors.greenAccent,
      'suspended' => Colors.redAccent,
      _ => Colors.amberAccent,
    };

    final previewCoverUrl = business.coverUrl ?? 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?q=80&w=1200&auto=format&fit=crop';
    final previewLogoUrl = business.logoUrl ?? 'https://images.unsplash.com/photo-1599305445671-ac291c95aaa9?w=200&auto=format&fit=crop';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) {
                final offset = _scrollController.offset;
                const snapOffset = 224.0; // expandedHeight (280) - collapsedHeight (56)
                
                if (offset > 0 && offset < snapOffset) {
                  Future.microtask(() {
                    if (offset > (snapOffset / 2)) {
                      _scrollController.animateTo(snapOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                    } else {
                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                    }
                  });
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
              // ── App Bar (Cover Image Only) ──────────────────────────────────
              // ── App Bar (Dynamic Collapsible Header) ─────────────────────────
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                backgroundColor: Colors.transparent, // Allow body content to show underneath when scrolled
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                leading: const SizedBox.shrink(),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final expandedHeight = 280.0;
                    final collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                    
                    double collapsePercent = (expandedHeight - top) / (expandedHeight - collapsedHeight);
                    collapsePercent = collapsePercent.clamp(0.0, 1.0);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image & gradient (Fades out when scrolling up)
                        Opacity(
                          opacity: (1.0 - collapsePercent).clamp(0.0, 1.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (previewCoverUrl.isNotEmpty)
                                Image.network(previewCoverUrl, fit: BoxFit.cover)
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        categoryColor.withValues(alpha: 0.2),
                                        const Color(0xFF0A0A14),
                                      ],
                                    ),
                                  ),
                                ),
                              // Dark gradient overlay for text readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF0A0A14).withValues(alpha: 0.3),
                                      const Color(0xFF0A0A14).withValues(alpha: 0.6),
                                      const Color(0xFF0A0A14).withValues(alpha: 1.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded Content (Fades out quickly)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Opacity(
                            opacity: (1.0 - collapsePercent * 2).clamp(0.0, 1.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Business Name & Label
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (previewLogoUrl.isNotEmpty) ...[
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                                            image: DecorationImage(
                                              image: NetworkImage(previewLogoUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      Text(
                                        business.businessName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _chip(
                                            business.subscriptionTier.toUpperCase(),
                                            const Color(0xFF42A5F5),
                                            HugeIcons.strokeRoundedCrown,
                                          ),
                                          const SizedBox(width: 6),
                                          _chip(
                                            business.status.toUpperCase(),
                                            statusColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Phone/WhatsApp actions (Expanded)
                                GlassContainer(
                                  useOwnLayer: true,
                                  quality: GlassQuality.standard,
                                  shape: const LiquidRoundedSuperellipse(borderRadius: 24.0),
                                  settings: const LiquidGlassSettings(
                                    thickness: 0.1,
                                    blur: 12.0,
                                    refractiveIndex: 1.0,
                                    glassColor: Colors.transparent,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {},
                                          child: const HugeIcon(icon: HugeIcons.strokeRoundedCall02, color: Colors.greenAccent, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () => _showAdminActionsMenu(context),
                                          child: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.white70, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dynamic Pill (Starts as Back button, expands to full header)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          right: 16,
                          child: LayoutBuilder(
                            builder: (context, boxConstraints) {
                              final minWidth = 44.0;
                              final maxWidth = boxConstraints.maxWidth; // full width minus padding
                              
                              // Expand proportionally, but if stopped, the ScrollController snaps the scroll view!
                              double targetExpand = ((collapsePercent - 0.1) * 1.5).clamp(0.0, 1.0);

                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: targetExpand),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                builder: (context, expandValue, child) {
                                  final currentWidth = minWidth + (maxWidth - minWidth) * expandValue;

                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: GlassContainer(
                                      useOwnLayer: true,
                                      quality: GlassQuality.standard,
                                      shape: LiquidRoundedSuperellipse(borderRadius: 50.0 - (20.0 * expandValue)),
                                  settings: const LiquidGlassSettings(
                                    thickness: 0.1,
                                    blur: 15.0,
                                    refractiveIndex: 1.0,
                                    glassColor: Colors.transparent,
                                  ),
                                  child: Container(
                                    height: 44,
                                    width: currentWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: OverflowBox(
                                        alignment: Alignment.centerLeft,
                                        minWidth: maxWidth,
                                        maxWidth: maxWidth,
                                        child: Row(
                                          children: [
                                            // Back button (Always fixed size and clickable)
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context),
                                              child: Container(
                                                width: 44,
                                                height: 44,
                                                color: Colors.transparent, // Ensures the tap area fills the bounds
                                                alignment: Alignment.center,
                                                child: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.white, size: 20),
                                              ),
                                            ),
                                            // Expandable content
                                            Expanded(
                                              child: Opacity(
                                                opacity: Curves.easeIn.transform(expandValue),
                                                child: Row(
                                                  children: [
                                                    if (previewLogoUrl.isNotEmpty) ...[
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                                                          image: DecorationImage(
                                                            image: NetworkImage(previewLogoUrl),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                    ],
                                                    Expanded(
                                                      child: Text(
                                                        business.businessName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                      onTap: () {},
                                                      child: const HugeIcon(icon: HugeIcons.strokeRoundedCall02, color: Colors.greenAccent, size: 18),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    GestureDetector(
                                                      onTap: () => _showAdminActionsMenu(context),
                                                      child: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.white70, size: 18),
                                                    ),
                                                    const SizedBox(width: 16), // Right padding
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Top Performance Summary ─────────────────────────────────
                    _glassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'TOTAL REVENUE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'RM 45,290.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMiniStat('Rating', '4.8', HugeIcons.strokeRoundedStar),
                              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                              _buildMiniStat('Bookings', '1,452', HugeIcons.strokeRoundedCalendar01),
                              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                              _buildMiniStat('Customers', '892', HugeIcons.strokeRoundedUserGroup),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section 1: Core Identity ──────────────────────────────
                    _sectionHeader(
                      'CORE IDENTITY',
                      HugeIcons.strokeRoundedBuilding01,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _field(
                            'Business ID',
                            business.id,
                            isMonospace: true,
                            copyable: true,
                            context: context,
                          ),
                          _divider(),
                          _field('Trading Name', business.businessName),
                          _divider(),
                          _field('Category', business.industry ?? 'Not set'),
                          _divider(),
                          _field(
                            'SSM Number',
                            business.registrationNumber,
                            copyable: true,
                            context: context,
                          ),
                          _divider(),
                          _field(
                            'SST Number',
                            null,
                          ), // not in current model, hardcoded null
                          _divider(),
                          _field('Status', business.status),
                          _divider(),
                          _field(
                            'Registered On',
                            _formatDate(business.createdAt),
                          ),
                          _divider(),
                          _field(
                            'Owner UID',
                            business.ownerUserId,
                            isMonospace: true,
                            copyable: true,
                            context: context,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 2: Location ───────────────────────────────────
                    _sectionHeader(
                      'LOCATION',
                      HugeIcons.strokeRoundedLocation01,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _field(
                            'Address',
                            business.city != null ? '${business.city}' : null,
                          ),
                          _divider(),
                          _field('City', business.city),
                          _divider(),
                          _field('State', business.country),
                          _divider(),
                          _field('Postcode', null),
                          _divider(),
                          _field('Latitude', null),
                          _divider(),
                          _field('Longitude', null),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 3: Contact ────────────────────────────────────
                    _sectionHeader(
                      'CONTACT',
                      HugeIcons.strokeRoundedCall,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _field('Phone', business.phone),
                          _divider(),
                          _field('Email', business.email),
                          _divider(),
                          _field('Website', business.website),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 4: Compliance ─────────────────────────────────
                    _sectionHeader(
                      'COMPLIANCE & BANKING',
                      HugeIcons.strokeRoundedMoney02,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      overrideColor: Colors.amber.withValues(alpha: 0.04),
                      overrideBorder: Colors.amber.withValues(alpha: 0.12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Sensitive — visible to super admins only',
                              style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          _field('Bank Name', null),
                          _divider(),
                          _field('Account Holder', null),
                          _divider(),
                          _field('Account Number', null, isMonospace: true),
                          _divider(),
                          _field('EPF Number', null, isMonospace: true),
                          _divider(),
                          _field('SOCSO Number', null, isMonospace: true),
                          _divider(),
                          _field('EIS Number', null, isMonospace: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 5: Settings ───────────────────────────────────
                    _sectionHeader(
                      'BUSINESS SETTINGS',
                      HugeIcons.strokeRoundedSettings01,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _field('Halal Certified', null),
                          _divider(),
                          _field('Total Chairs', null),
                          _divider(),
                          _field('Slot Duration', '30 minutes (default)'),
                          _divider(),
                          _field('Operating Hours', 'Not configured'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 6: Subscription ───────────────────────────────
                    _sectionHeader(
                      'SUBSCRIPTION',
                      HugeIcons.strokeRoundedCrown,
                      const Color(0xFF42A5F5),
                    ),
                    _glassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _field(
                            'Plan',
                            business.subscriptionTier[0].toUpperCase() +
                                business.subscriptionTier.substring(1),
                          ),
                          _divider(),
                          _field('Status', business.isActive ? 'Active' : (business.isTrial ? 'Trial' : 'Suspended')),
                          _divider(),
                          _field('Billing Cycle', 'Monthly'),
                          _divider(),
                          _field('Next Renewal', '12 Oct 2026'),
                          _divider(),
                          _field('Payment Method', 'Card ending in 4242'),
                          _divider(),
                          _field('Last Billed', 'RM 199.00'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Close button ──────────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: _glassCard(
                        radius: 18,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          ),

        ],
      ),
    );
  }
  void _showAdminActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: const LiquidGlassSettings(
            thickness: 0.1,
            blur: 15.0,
            refractiveIndex: 1.0,
            glassColor: Colors.transparent,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A14).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Admin Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedCrown, color: Colors.blueAccent, size: 24),
                    title: const Text('Upgrade to Pro', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _performAction(() => ApiService().upgradeBusiness(widget.business.id, 'pro'));
                    },
                  ),
                  ListTile(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedCrown, color: Colors.amber, size: 24),
                    title: const Text('Upgrade to Enterprise', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _performAction(() => ApiService().upgradeBusiness(widget.business.id, 'enterprise'));
                    },
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedLock, color: Colors.redAccent, size: 24),
                    title: const Text('Suspend Business', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _performAction(() => ApiService().suspendBusiness(widget.business.id));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performAction(Future<void> Function() action) async {
    try {
      showGlassToast(context, 'Executing Edge Function...');
      await action();
      if (mounted) {
        showGlassToast(context, 'Action successful. Please refresh.');
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, 'Error: $e', isError: true, customColor: Colors.orange);
      }
    }
  }
}
