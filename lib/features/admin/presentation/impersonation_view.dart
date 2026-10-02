import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/glass_toast.dart';

class ImpersonationView extends StatefulWidget {
  final VoidCallback? onBack;
  const ImpersonationView({super.key, this.onBack});

  @override
  State<ImpersonationView> createState() => _ImpersonationViewState();
}

class _ImpersonationViewState extends State<ImpersonationView> {
  String _searchQuery = '';
  Map<String, dynamic>? _activeImpersonatedTenant;

  final List<Map<String, dynamic>> _tenants = [
    {
      'id': 'ten_001',
      'name': 'The Barber Club Bangi',
      'owner': 'Muhammad Farhan',
      'plan': 'Pro Growth (RM99/bln)',
      'status': 'active',
      'activeDevices': 3,
      'todaySales': 'RM 1,450.00',
      'openOrders': 4,
      'staffCount': 6,
    },
    {
      'id': 'ten_002',
      'name': 'Warung Kopi Tok Wan Subang',
      'owner': 'Wan Khadijah',
      'plan': 'Pro Growth (RM99/bln)',
      'status': 'active',
      'activeDevices': 4,
      'todaySales': 'RM 2,890.00',
      'openOrders': 12,
      'staffCount': 10,
    },
    {
      'id': 'ten_003',
      'name': 'Salun Jelita Muslimah Shah Alam',
      'owner': 'Nurul Izzati',
      'plan': 'Starter (RM49/bln)',
      'status': 'active',
      'activeDevices': 2,
      'todaySales': 'RM 820.00',
      'openOrders': 2,
      'staffCount': 4,
    },
    {
      'id': 'ten_004',
      'name': 'Bake & Brew Studio TTDI',
      'owner': 'Chong Wei Lun',
      'plan': 'Enterprise (Custom)',
      'status': 'active',
      'activeDevices': 5,
      'todaySales': 'RM 4,120.00',
      'openOrders': 8,
      'staffCount': 12,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),

            // Active Ghost Banner if impersonating
            if (_activeImpersonatedTenant != null) ...[
              _buildActiveGhostBanner(),
              const SizedBox(height: 20),
              _buildImpersonatedMerchantDashboard(),
              const SizedBox(height: 24),
            ],

            _buildSearchBox(),
            const SizedBox(height: 20),

            const Text(
              'Pilih Kedai / Tenant Untuk Impersonate',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ..._tenants
                .where((t) =>
                    _searchQuery.isEmpty ||
                    (t['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (t['id'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
                .map((t) => _buildTenantCard(t)),
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
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedUserAccount,
            color: const Color(0xFFF59E0B),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Impersonation Engine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mod "Ghost Login" sokongan teknikal tanpa kata laluan peniaga',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveGhostBanner() {
    final tenant = _activeImpersonatedTenant!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SESI IMPERSONATE AKTIF', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text('${tenant['name']} (${tenant['id']})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _activeImpersonatedTenant = null);
                showGlassToast(context, 'Sesi impersonate ditamatkan. Kembali ke mod Super Admin.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Tamat Sesi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpersonatedMerchantDashboard() {
    final tenant = _activeImpersonatedTenant!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Simulasi Pandangan POS Kedai', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Live Sync OK', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _simCard('Jualan Hari Ini', tenant['todaySales'], Colors.white),
                  const SizedBox(width: 10),
                  _simCard('Pesanan Terbuka', '${tenant['openOrders']} Pesanan', const Color(0xFFF9C80E)),
                  const SizedBox(width: 10),
                  _simCard('Staf Bertugas', '${tenant['staffCount']} Orang', const Color(0xFF26C6DA)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showGlassToast(context, 'Cache lokal POS berjaya di-flush & sync semula.'),
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Flush Sync Cache', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showGlassToast(context, 'Log diagnostik dihantar ke admin console.'),
                      icon: const Icon(Icons.bug_report_outlined, size: 16),
                      label: const Text('Diagnostik Sesi', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white.withValues(alpha: 0.06),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Cari kedai atau ID Tenant...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> t) {
    final isCurrent = _activeImpersonatedTenant?['id'] == t['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isCurrent ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Color(0xFF6C63FF), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${t['id']} • Pemilik: ${t['owner']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(t['plan'] as String, style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _activeImpersonatedTenant = t);
                    showGlassToast(context, 'Masuk sebagai ${t['name']} (Sesi Ghost Aktif)!');
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Masuk Sesi', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? const Color(0xFFF59E0B) : const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
