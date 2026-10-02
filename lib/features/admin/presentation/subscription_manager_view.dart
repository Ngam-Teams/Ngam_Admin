import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/glass_toast.dart';

class SubscriptionManagerView extends StatefulWidget {
  final VoidCallback? onBack;
  const SubscriptionManagerView({super.key, this.onBack});

  @override
  State<SubscriptionManagerView> createState() => _SubscriptionManagerViewState();
}

class _SubscriptionManagerViewState extends State<SubscriptionManagerView> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _merchants = [
    {
      'id': 'ten_001',
      'name': 'The Barber Club Bangi',
      'tier': 'Pro Growth',
      'price': 'RM 99/bln',
      'status': 'active',
      'renewsOn': '15 Okt 2026',
      'trialDaysLeft': 0,
    },
    {
      'id': 'ten_002',
      'name': 'Warung Kopi Tok Wan Subang',
      'tier': 'Pro Growth',
      'price': 'RM 99/bln',
      'status': 'active',
      'renewsOn': '02 Nov 2026',
      'trialDaysLeft': 0,
    },
    {
      'id': 'ten_003',
      'name': 'Salun Jelita Muslimah Shah Alam',
      'tier': 'Starter',
      'price': 'RM 49/bln',
      'status': 'trial',
      'renewsOn': '12 Okt 2026',
      'trialDaysLeft': 12,
    },
    {
      'id': 'ten_004',
      'name': 'Bake & Brew Studio TTDI',
      'tier': 'Enterprise',
      'price': 'RM 299/bln',
      'status': 'active',
      'renewsOn': '28 Okt 2026',
      'trialDaysLeft': 0,
    },
    {
      'id': 'ten_005',
      'name': 'Bengkel Motor Din King',
      'tier': 'Starter',
      'price': 'RM 49/bln',
      'status': 'suspended',
      'renewsOn': 'Tergantung',
      'trialDaysLeft': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _merchants.where((m) {
      if (_selectedFilter == 'starter' && m['tier'] != 'Starter') return false;
      if (_selectedFilter == 'pro' && m['tier'] != 'Pro Growth') return false;
      if (_selectedFilter == 'enterprise' && m['tier'] != 'Enterprise') return false;
      if (_selectedFilter == 'trial' && m['status'] != 'trial') return false;
      if (_selectedFilter == 'suspended' && m['status'] != 'suspended') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (m['name'] as String).toLowerCase();
        final id = (m['id'] as String).toLowerCase();
        return name.contains(q) || id.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSearchAndFilters(),
            const SizedBox(height: 20),
            ...filtered.map((m) => _buildMerchantCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.onBack != null || Navigator.canPop(context))
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedCrown02,
            color: Color(0xFF4ECDC4),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengurusan Pelan & Override',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tukar pelan langganan, lanjutkan percubaan & kawalan sekatan',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.white.withValues(alpha: 0.06),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari peniaga atau ID...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'Semua (${_merchants.length})'),
              _filterChip('starter', 'Starter (RM49)'),
              _filterChip('pro', 'Pro Growth (RM99)'),
              _filterChip('enterprise', 'Enterprise'),
              _filterChip('trial', 'Dalam Percubaan (Trial)'),
              _filterChip('suspended', 'Digantung'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = filterId),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> m) {
    final status = m['status'] as String;
    Color statusColor;
    String statusLabel;
    if (status == 'active') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'AKTIF';
    } else if (status == 'trial') {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'TRIAL (${m['trialDaysLeft']} Hari)';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'DIGANTUNG';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${m['id']} • Pembaharuan: ${m['renewsOn']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pelan Semasa', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('${m['tier']} (${m['price']})', style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _showExtendTrialModal(m),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF59E0B),
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            child: const Text('+30 Hari Percuma', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showChangeTierModal(m),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Tukar Pelan', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeTierModal(Map<String, dynamic> m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141428),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tukar Pelan untuk ${m['name']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _tierOption(m, 'Starter', 'RM 49/bln', 'Untuk kedai solo / kecil', ctx),
            _tierOption(m, 'Pro Growth', 'RM 99/bln', 'Pengurusan staf, multi-device & DuitNow QR', ctx),
            _tierOption(m, 'Enterprise', 'RM 299/bln', 'KDS Dapur, Custom API & Multi-cawangan', ctx),
          ],
        ),
      ),
    );
  }

  Widget _tierOption(Map<String, dynamic> m, String tier, String price, String desc, BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$tier — $price', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
        onTap: () {
          Navigator.pop(ctx);
          setState(() {
            m['tier'] = tier;
            m['price'] = price;
          });
          showGlassToast(context, 'Pelan bagi ${m['name']} ditukar ke $tier ($price)!');
        },
      ),
    );
  }

  void _showExtendTrialModal(Map<String, dynamic> m) {
    setState(() {
      m['status'] = 'trial';
      m['trialDaysLeft'] = (m['trialDaysLeft'] as int) + 30;
      m['renewsOn'] = 'Lanjutan +30 Hari';
    });
    showGlassToast(context, 'Tempoh percubaan ${m['name']} berjaya dilanjutkan sebanyak +30 Hari secara percuma!');
  }
}
