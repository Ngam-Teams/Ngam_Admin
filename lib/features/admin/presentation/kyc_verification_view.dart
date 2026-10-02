import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/glass_toast.dart';

class KycVerificationView extends StatefulWidget {
  final VoidCallback? onBack;
  const KycVerificationView({super.key, this.onBack});

  @override
  State<KycVerificationView> createState() => _KycVerificationViewState();
}

class _KycVerificationViewState extends State<KycVerificationView> {
  String _selectedFilter = 'pending';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _applications = [
    {
      'id': 'kyc_001',
      'businessName': 'The Barber Club Bangi',
      'ssmNo': '202401089234 (1567890-K)',
      'businessType': 'Enterprise — Gunting Rambut & Grooming',
      'ownerName': 'Muhammad Farhan bin Razali',
      'icNo': '940812-10-5431',
      'bankName': 'Maybank',
      'accountNo': '5142 8901 2345',
      'submittedDate': 'Hari Ini, 10:30 AM',
      'status': 'pending',
      'docs': ['Sijil SSM Borang D', 'Salinan MyKad Depan/Belakang', 'Penyata Bank Maybank'],
    },
    {
      'id': 'kyc_002',
      'businessName': 'Warung Kopi Tok Wan Subang',
      'ssmNo': '202303120045 (1498721-M)',
      'businessType': 'PLT — Kafe & Minuman Tradisional',
      'ownerName': 'Wan Khadijah binti Wan Omar',
      'icNo': '880520-14-6122',
      'bankName': 'CIMB Bank',
      'accountNo': '8009 2341 5567',
      'submittedDate': 'Semalam, 4:15 PM',
      'status': 'pending',
      'docs': ['Sijil SSM e-Info', 'Salinan MyKad Pemilik', 'Lesen PBT Majlis Bandaraya'],
    },
    {
      'id': 'kyc_003',
      'businessName': 'Salun Jelita Muslimah Shah Alam',
      'ssmNo': '202402004561 (1589012-P)',
      'businessType': 'Sdn Bhd — Rawatan Rambut & Spa',
      'ownerName': 'Nurul Izzati binti Azman',
      'icNo': '910304-10-5980',
      'bankName': 'Bank Islam',
      'accountNo': '1204 3020 9981',
      'submittedDate': '28 Sept 2026',
      'status': 'pending',
      'docs': ['Borang 9 / SSM Certificate', 'Borang 49 (Senarai Pengarah)', 'Penyata Bank 3 Bulan'],
    },
    {
      'id': 'kyc_004',
      'businessName': 'Bake & Brew Studio TTDI',
      'ssmNo': '202201045982 (1420911-A)',
      'businessType': 'Enterprise — Bakeri & Kafe Khas',
      'ownerName': 'Chong Wei Lun',
      'icNo': '900215-14-5339',
      'bankName': 'Public Bank',
      'accountNo': '3189 0041 2291',
      'submittedDate': '25 Sept 2026',
      'status': 'approved',
      'docs': ['Sijil Pendaftaran SSM', 'MyKad Pengarah', 'Penyata Syarikat'],
    },
    {
      'id': 'kyc_005',
      'businessName': 'Bengkel Motor Din King',
      'ssmNo': '202001099881 (1309881-W)',
      'businessType': 'Tunggal — Servis & Tayar',
      'ownerName': 'Kamarudin bin Saleh',
      'icNo': '850119-08-5111',
      'bankName': 'RHB Bank',
      'accountNo': '2120 4400 9912',
      'submittedDate': '22 Sept 2026',
      'status': 'rejected',
      'rejectReason': 'Sijil SSM telah tamat tempoh dan nama pemegang akaun bank berbeza.',
      'docs': ['Sijil SSM Luput', 'MyKad'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _applications.where((app) {
      if (_selectedFilter != 'all' && app['status'] != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (app['businessName'] as String).toLowerCase();
        final ssm = (app['ssmNo'] as String).toLowerCase();
        final owner = (app['ownerName'] as String).toLowerCase();
        return name.contains(q) || ssm.contains(q) || owner.contains(q);
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
            // Top Bar
            _buildHeader(context),
            const SizedBox(height: 20),

            // Stat Summary Cards
            _buildSummaryStats(),
            const SizedBox(height: 20),

            // Search & Filter
            _buildSearchAndFilters(),
            const SizedBox(height: 20),

            // List of Applications
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map((app) => _buildApplicationCard(app)),
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
            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedLegal01,
            color: Color(0xFF6C63FF),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SSM & Merchant KYC Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pengesahan pendaftaran perniagaan & kelulusan akaun merchant',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final pendingCount = _applications.where((a) => a['status'] == 'pending').length;
    final approvedCount = _applications.where((a) => a['status'] == 'approved').length;
    final rejectedCount = _applications.where((a) => a['status'] == 'rejected').length;

    return Row(
      children: [
        _buildStatTile('Menunggu', '$pendingCount', const Color(0xFFF59E0B), HugeIcons.strokeRoundedClock01),
        const SizedBox(width: 12),
        _buildStatTile('Diluluskan', '$approvedCount', const Color(0xFF10B981), HugeIcons.strokeRoundedCheckmarkBadge01),
        const SizedBox(width: 12),
        _buildStatTile('Ditolak', '$rejectedCount', const Color(0xFFEF4444), HugeIcons.strokeRoundedCancelCircle),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color, dynamic icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(icon: icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.white.withValues(alpha: 0.06),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama bisnes, no SSM, nama pemilik...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'Semua (${_applications.length})'),
              _filterChip('pending', 'Menunggu (${_applications.where((a) => a['status'] == 'pending').length})'),
              _filterChip('approved', 'Diluluskan (${_applications.where((a) => a['status'] == 'approved').length})'),
              _filterChip('rejected', 'Ditolak (${_applications.where((a) => a['status'] == 'rejected').length})'),
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
            color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = app['status'] as String;
    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'DILULUSKAN';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'DITOLAK';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'MENUNGGU SEMAKAN';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Business name + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['businessName'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app['businessType'] as String,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('No. Pendaftaran SSM', app['ssmNo'] as String, isCopyable: true),
                      const Divider(color: Colors.white10, height: 16),
                      _detailRow('Nama Pemilik / IC', '${app['ownerName']} (${app['icNo']})'),
                      const Divider(color: Colors.white10, height: 16),
                      _detailRow('Bank Payout', '${app['bankName']} — ${app['accountNo']}'),
                      const Divider(color: Colors.white10, height: 16),
                      _detailRow('Tarikh Hantar', app['submittedDate'] as String),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Documents attached
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (app['docs'] as List<String>).map((doc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.file_present_rounded, color: Color(0xFF6C63FF), size: 14),
                          const SizedBox(width: 6),
                          Text(doc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (status == 'pending') ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // View Documents
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewDocsModal(app),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Semak Dokumen', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reject
                      OutlinedButton(
                        onPressed: () => _showRejectDialog(app),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      // Approve
                      ElevatedButton(
                        onPressed: () => _approveApp(app),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Luluskan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isCopyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Tiada permohonan KYC dijumpai',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _approveApp(Map<String, dynamic> app) {
    setState(() {
      app['status'] = 'approved';
    });
    showGlassToast(
      context,
      'Permohonan ${app['businessName']} telah DILULUSKAN! Peniaga kini aktif.',
    );
  }

  void _showRejectDialog(Map<String, dynamic> app) {
    final reasonController = TextEditingController(text: 'Dokumen SSM tidak sepadan dengan nama pemilik akaun bank.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white24)),
        title: const Text('Tolak Permohonan SSM', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sila nyatakan sebab penolakan bagi ${app['businessName']}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                app['status'] = 'rejected';
                app['rejectReason'] = reasonController.text;
              });
              showGlassToast(
                context,
                'Permohonan ${app['businessName']} ditolak.',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Sahkan Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewDocsModal(Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121226),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lampiran Dokumen Peniaga',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...((app['docs'] as List<String>).map((doc) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          doc,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showGlassToast(context, 'Membuka $doc (Simulasi PDF Viewer)...');
                        },
                        child: const Text('Buka Fail', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                      ),
                    ],
                  ),
                ))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
