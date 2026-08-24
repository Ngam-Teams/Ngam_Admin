// =============================================================================
// BusinessDirectoryView
// Data table listing all businesses from admin_tenant_view with real-time
// filtering by business name, business_id, and active/suspended status (§5.2).
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../data/api_service.dart';
import '../models/business_summary_model.dart';
import 'widgets/business_action_menu.dart';
import 'widgets/modal_sheet.dart';
import 'package:go_router/go_router.dart';

class BusinessDirectoryView extends StatefulWidget {
  const BusinessDirectoryView({super.key});

  @override
  State<BusinessDirectoryView> createState() => _BusinessDirectoryViewState();
}

class _BusinessDirectoryViewState extends State<BusinessDirectoryView> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<BusinessSummaryModel> _allBusinesses = [];
  List<BusinessSummaryModel> _filteredBusinesses = [];
  String _statusFilter = 'all';
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
    _searchController.addListener(_applyFilters);
    // Background auto-refresh every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadBusinesses(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final businesses = await _api.fetchAllBusinesses();
      if (!mounted) return;
      setState(() {
        _allBusinesses = businesses;
        _applyFilters();
        _loading = false;
      });
    } on ConsoleApiException catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBusinesses = _allBusinesses.where((t) {
        final matchesQuery =
            query.isEmpty ||
            t.businessName.toLowerCase().contains(query) ||
            t.id.toLowerCase().contains(query);

        final matchesStatus =
            _statusFilter == 'all' || t.status == _statusFilter;

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _setStatusFilter(String status) {
    setState(() => _statusFilter = status);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search + filter bar
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by business name or ID…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18,
                            strokeWidth: 2.1,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF42A5F5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                  _StatusChip(
                    label: 'All',
                    selected: _statusFilter == 'all',
                    onTap: () => _setStatusFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Active',
                    selected: _statusFilter == 'active',
                    color: Colors.greenAccent,
                    onTap: () => _setStatusFilter('active'),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Suspended',
                    selected: _statusFilter == 'suspended',
                    color: Colors.redAccent,
                    onTap: () => _setStatusFilter('suspended'),
                  ),
                  const SizedBox(width: 8),
                  // Refresh
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                      color: Colors.white54,
                      size: 18,
                      strokeWidth: 2.1,
                    ),
                    tooltip: 'Refresh',
                    onPressed: _loadBusinesses,
                  ),
                      ],
                    ), // closes Row
                  ), // closes SingleChildScrollView
                ],
              ), // closes Column
            ), // closes Container
          ),
        ),
        const SizedBox(height: 24),

        // Table content
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert01,
              color: Colors.redAccent,
              size: 32,
              strokeWidth: 2.1,
            ),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBusinesses, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredBusinesses.isEmpty) {
      return Center(
        child: Text(
          'No businesses found.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return isDesktop ? _buildDesktopTable() : _buildMobileCards();
      },
    );
  }

  Widget _buildMobileCards() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 160),
      itemCount: _filteredBusinesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final business = _filteredBusinesses[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showBusinessDetails(business),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                business.businessName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            BusinessActionMenu(
                              business: business,
                              apiService: _api,
                              onActionComplete: _loadBusinesses,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusBadge(status: business.status),
                            const SizedBox(width: 8),
                            _TierBadge(tier: business.subscriptionTier),
                            const Spacer(),
                            Text(
                              'Joined: ${_formatDate(business.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.white.withValues(alpha: 0.05)),
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 32,
                  horizontalMargin: 24,
                  headingRowHeight: 56,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 64,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.black.withValues(alpha: 0.2),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.04);
                    }
                    return Colors.transparent;
                  }),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Business',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    DataColumn(
                      label: Text(
                        'Tier',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Joined',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  rows: _filteredBusinesses.map(_buildRow).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BusinessSummaryModel business) {
    return DataRow(
      onSelectChanged: (_) => _showBusinessDetails(business),
      cells: [
        DataCell(
          Text(
            business.businessName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        DataCell(_TierBadge(tier: business.subscriptionTier)),
        DataCell(_StatusBadge(status: business.status)),
        DataCell(
          Text(
            _formatDate(business.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
        DataCell(
          BusinessActionMenu(
            business: business,
            apiService: _api,
            onActionComplete: _loadBusinesses,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Glass helpers (copied from Ngam's _buildInnerGlassCard / _buildStatItem)
  // ---------------------------------------------------------------------------

  LiquidGlassSettings _glassSettings(bool isDark, {double blur = 2.0}) =>
      LiquidGlassSettings(
        thickness: 0.1,
        blur: blur,
        refractiveIndex: 1.0,
        glassColor: Colors.transparent,
        lightAngle: 45.0,
        lightIntensity: isDark ? 0.1 : 0.2,
        ambientStrength: 1.0,
        saturation: 1.0,
        chromaticAberration: 0.0,
      );

  Widget _innerGlassCard({
    required Widget child,
    required bool isDark,
    double radius = 16.0,
    EdgeInsetsGeometry? padding,
    Color? overrideColor,
    Color? overrideBorder,
  }) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: _glassSettings(isDark),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: overrideColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.4)),
          border: Border.all(
            color: overrideBorder ??
                Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _statItem(dynamic icon, String value, String label, bool isDark) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: Colors.blue, size: 20, strokeWidth: 2.0),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _verticalDivider() => Container(
        height: 30,
        width: 1,
        color: Colors.white.withValues(alpha: 0.1),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Business detail bottom sheet
  // ---------------------------------------------------------------------------

  void _showBusinessDetails(BusinessSummaryModel business) {
    const bool isDark = true; // console is always dark

    // Hardcoded fallback values for fields not yet in the data model
    const double rating = 4.7;
    const int reviewCount = 128;
    const String aboutText =
        'A registered business operating on the Ngam platform. '
        'All service activities, transactions, and runner assignments are '
        'managed through this business workspace.';
    final List<String> services = [
      'Service Booking',
      'Task Management',
      'Runner Dispatch',
      'Wallet & Payments',
    ];
    final List<Map<String, String>> workingHours = [
      {'day': 'Mon – Fri', 'hours': '9:00 AM – 6:00 PM'},
      {'day': 'Saturday', 'hours': '10:00 AM – 4:00 PM'},
      {'day': 'Sunday', 'hours': 'Closed'},
    ];

    ModalSheet.show(
      context: context,
      initialChildSize: 0.65,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          (business.industry ?? 'GENERAL').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF42A5F5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusBadge(status: business.status),
                      ],
                    ),
                  ],
                ),
              ),
              BusinessActionMenu(
                business: business,
                apiService: _api,
                onActionComplete: () {
                  Navigator.pop(ctx);
                  _loadBusinesses();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stat bar (Tier · Rating · Joined) ──────────────────────────────
          _innerGlassCard(
            isDark: isDark,
            radius: 20.0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _statItem(
                    _TierBadge.getIcon(business.subscriptionTier),
                    business.subscriptionTier[0].toUpperCase() +
                        business.subscriptionTier.substring(1),
                    'Plan',
                    isDark,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _statItem(
                    HugeIcons.strokeRoundedStar,
                    '$rating ($reviewCount)',
                    'Rating',
                    isDark,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _statItem(
                    HugeIcons.strokeRoundedCalendar01,
                    _formatDate(business.createdAt),
                    'Joined',
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick-action row (Call · View Profile · Copy ID) ──────────────
          Row(
            children: [
              if (business.phone != null) ...
                [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: _innerGlassCard(
                        isDark: isDark,
                        radius: 14.0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        overrideColor:
                            const Color(0xFF42A5F5).withValues(alpha: 0.25),
                        overrideBorder:
                            const Color(0xFF42A5F5).withValues(alpha: 0.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCall,
                              color: Color(0xFF42A5F5),
                              size: 17,
                              strokeWidth: 2.0,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Color(0xFF42A5F5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              // View Full Profile button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/console/business', extra: business);
                  },
                  child: _innerGlassCard(
                    isDark: isDark,
                    radius: 14.0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    overrideColor: const Color(0xFF42A5F5).withValues(alpha: 0.2),
                    overrideBorder: const Color(0xFF42A5F5).withValues(alpha: 0.45),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedBuilding01,
                          color: Color(0xFF42A5F5),
                          size: 17,
                          strokeWidth: 2.0,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Business Profile',
                          style: TextStyle(
                            color: Color(0xFF42A5F5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: business.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Business ID copied!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: _innerGlassCard(
                    isDark: isDark,
                    radius: 14.0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    overrideColor: const Color(0xFF42A5F5).withValues(alpha: 0.2),
                    overrideBorder: const Color(0xFF42A5F5).withValues(alpha: 0.45),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCopy01,
                          color: Color(0xFF42A5F5),
                          size: 17,
                          strokeWidth: 2.0,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Copy ID',
                          style: TextStyle(
                            color: Color(0xFF42A5F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────────
          _sectionTitle('About'),
          _innerGlassCard(
            isDark: isDark,
            radius: 16.0,
            padding: const EdgeInsets.all(16),
            child: Text(
              aboutText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Reviews ───────────────────────────────────────────────────────
          _sectionTitle('Reviews & Rating'),
          _innerGlassCard(
            isDark: isDark,
            radius: 16.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedStar,
                      color: Colors.amber,
                      size: 26,
                      strokeWidth: 2.0,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$rating',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ 5.0   ($reviewCount reviews)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Star breakdown bars
                for (int s = 5; s >= 1; s--) ...
                  [
                    _StarBar(
                      stars: s,
                      percent: s == 5
                          ? 0.68
                          : s == 4
                              ? 0.20
                              : s == 3
                                  ? 0.08
                                  : s == 2
                                      ? 0.03
                                      : 0.01,
                    ),
                    if (s > 1) const SizedBox(height: 4),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Services ──────────────────────────────────────────────────────
          _sectionTitle('Services Available'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: services
                .map(
                  (s) => _innerGlassCard(
                    isDark: isDark,
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Working Hours ─────────────────────────────────────────────────
          _sectionTitle('Working Hours'),
          _innerGlassCard(
            isDark: isDark,
            radius: 16.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: workingHours.map((entry) {
                final isClosed = entry['hours'] == 'Closed';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            color: isClosed
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            size: 15,
                            strokeWidth: 2.0,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry['day']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        entry['hours']!,
                        style: TextStyle(
                          color: isClosed
                              ? Colors.redAccent
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Location / Contact ────────────────────────────────────────────
          _sectionTitle('Location & Contact'),
          _innerGlassCard(
            isDark: isDark,
            radius: 16.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _contactRow(
                  HugeIcons.strokeRoundedLocation01,
                  'Address',
                  (business.city != null || business.country != null)
                      ? '${business.city ?? ''}${business.city != null && business.country != null ? ', ' : ''}${business.country ?? ''}'
                      : 'Not provided',
                  const Color(0xFF42A5F5),
                ),
                if (business.phone != null) ...
                  [
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 20),
                    _contactRow(
                      HugeIcons.strokeRoundedCall,
                      'Phone',
                      business.phone!,
                      const Color(0xFF42A5F5),
                    ),
                  ],
                if (business.email != null) ...
                  [
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 20),
                    _contactRow(
                      HugeIcons.strokeRoundedMail01,
                      'Email',
                      business.email!,
                      const Color(0xFF42A5F5),
                    ),
                  ],
                if (business.website != null) ...
                  [
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 20),
                    _contactRow(
                      HugeIcons.strokeRoundedGlobe,
                      'Website',
                      business.website!,
                      const Color(0xFF42A5F5),
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── System Info ───────────────────────────────────────────────────
          _sectionTitle('System Info'),
          _innerGlassCard(
            isDark: isDark,
            radius: 16.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow('Business ID', business.id,
                    isMonospace: true, onCopy: () {
                  Clipboard.setData(ClipboardData(text: business.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Business ID copied!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
                Divider(
                    color: Colors.white.withValues(alpha: 0.07),
                    height: 20),
                _infoRow('Joined', _formatDate(business.createdAt)),
                if (business.registrationNumber != null) ...
                  [
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 20),
                    _infoRow('Reg. No.', business.registrationNumber!),
                  ],
                if (business.ownerUserId != null) ...
                  [
                    Divider(
                        color: Colors.white.withValues(alpha: 0.07),
                        height: 20),
                    _infoRow('Owner UID', business.ownerUserId!,
                        isMonospace: true),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Close ─────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: _innerGlassCard(
              isDark: isDark,
              radius: 18.0,
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
        ],
      ),
    );
  }

  Widget _contactRow(
    dynamic icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, color: iconColor, size: 17, strokeWidth: 2.0),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            Text(
              value.length > 20 ? '${value.substring(0, 20)}…' : value,
              style: TextStyle(
                color: Colors.white,
                fontFamily: isMonospace ? 'monospace' : null,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onCopy != null) ...
              [
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCopy01,
                    color: Colors.cyanAccent,
                    size: 15,
                    strokeWidth: 2.1,
                  ),
                ),
              ],
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.greenAccent,
      'suspended' => Colors.redAccent,
      'trial' => Colors.amber,
      _ => Colors.white38,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  static dynamic getIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'enterprise':
        return HugeIcons.strokeRoundedBuilding01;
      case 'pro':
        return HugeIcons.strokeRoundedCrown;
      case 'free':
      case 'free trial':
      case 'trial':
      default:
        return HugeIcons.strokeRoundedGift;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF42A5F5); // Rezrv blue
    final iconData = getIcon(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: iconData,
            color: color,
            size: 14,
            strokeWidth: 2.0,
          ),
          const SizedBox(width: 4),
          Text(
            tier.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Star rating breakdown bar
// ---------------------------------------------------------------------------

class _StarBar extends StatelessWidget {
  final int stars;
  final double percent; // 0.0 – 1.0

  const _StarBar({required this.stars, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Colors.amber, size: 11),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${(percent * 100).toInt()}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
