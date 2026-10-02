import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../widgets/glass_toast.dart';

class PayoutClearinghouseView extends StatefulWidget {
  final VoidCallback? onBack;
  const PayoutClearinghouseView({super.key, this.onBack});

  @override
  State<PayoutClearinghouseView> createState() => _PayoutClearinghouseViewState();
}

class _PayoutClearinghouseViewState extends State<PayoutClearinghouseView> {
  final formatCurrency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

  final List<Map<String, dynamic>> _settlements = [
    {
      'id': 'sttl_101',
      'merchant': 'The Barber Club Bangi',
      'bank': 'Maybank',
      'accNo': '5142 8901 2345',
      'gross': 3500.00,
      'mdrFee': 52.50,
      'net': 3447.50,
      'txCount': 72,
      'status': 'pending', // pending, released, held
      'flagReason': null,
    },
    {
      'merchant': 'Warung Kopi Tok Wan Subang',
      'bank': 'CIMB Bank',
      'accNo': '8009 2341 5567',
      'gross': 8920.00,
      'mdrFee': 133.80,
      'net': 8786.20,
      'txCount': 340,
      'status': 'pending',
      'flagReason': null,
    },
    {
      'merchant': 'Restoran Nasi Kandar Subang',
      'bank': 'RHB Bank',
      'accNo': '2120 4400 9912',
      'gross': 14200.00,
      'mdrFee': 213.00,
      'net': 13987.00,
      'txCount': 520,
      'status': 'held',
      'flagReason': 'Kenaikan mendadak +280% jualan DuitNow dalam 4 jam. Perlu semakan manual.',
    },
    {
      'merchant': 'Salun Jelita Muslimah Shah Alam',
      'bank': 'Bank Islam',
      'accNo': '1204 3020 9981',
      'gross': 5120.00,
      'mdrFee': 76.80,
      'net': 5043.20,
      'txCount': 38,
      'status': 'pending',
      'flagReason': null,
    },
    {
      'merchant': 'Bake & Brew Studio TTDI',
      'bank': 'Public Bank',
      'accNo': '3189 0041 2291',
      'gross': 11400.00,
      'mdrFee': 171.00,
      'net': 11229.00,
      'txCount': 215,
      'status': 'released',
      'flagReason': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pendingTotal = _settlements
        .where((s) => s['status'] == 'pending')
        .fold<double>(0.0, (acc, item) => acc + (item['net'] as double));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTreasuryCard(pendingTotal),
            const SizedBox(height: 24),
            _buildBatchActionBar(pendingTotal),
            const SizedBox(height: 20),
            const Text(
              'Senarai Penyelesaian Hari Ini',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._settlements.map((s) => _buildSettlementCard(s)),
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
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedBank,
            color: Color(0xFF10B981),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DuitNow Payout Clearinghouse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Audit pelepasan dana escrow ke akaun bank peniaga harian',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreasuryCard(double pendingTotal) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.15),
                const Color(0xFF6C63FF).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Baki Akaun Escrow Platform',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Bank Negara Malaysia Escrow', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency.format(248500.00),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn('Menunggu Batch Hari Ini', formatCurrency.format(pendingTotal), const Color(0xFFF59E0B)),
                  _statColumn('Selesai Pelepasan', formatCurrency.format(11229.00), const Color(0xFF10B981)),
                  _statColumn('Audit Ditahan', formatCurrency.format(13987.00), const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBatchActionBar(double pendingTotal) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white.withValues(alpha: 0.05),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pelepasan Berkelompok (Batch)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${_settlements.where((s) => s['status'] == 'pending').length} transaksi sedia untuk DuitNow clearing', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: pendingTotal == 0 ? null : _releaseBatch,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Lepaskan Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> s) {
    final status = s['status'] as String;
    Color statusColor;
    String statusLabel;
    if (status == 'released') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'DILULUSKAN & SELESAI';
    } else if (status == 'held') {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'DITAHAN UNTUK AUDIT';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'MENUNGGU PELEPASAN';
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
              border: Border.all(color: status == 'held' ? const Color(0xFFEF4444).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s['merchant'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${s['bank']} • ${s['accNo']} • ${s['txCount']} Transaksi',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
                if (s['flagReason'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s['flagReason'] as String, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jumlah Bersih (Net)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(formatCurrency.format(s['net']), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Text(
                      'Kutipan: ${formatCurrency.format(s['gross'])}\nFee MDR: -${formatCurrency.format(s['mdrFee'])}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                if (status != 'released') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (status == 'pending') ...[
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              s['status'] = 'held';
                              s['flagReason'] = 'Ditahan secara manual oleh Super Admin untuk semakan audit.';
                            });
                            showGlassToast(context, 'Payout ditahan untuk ${s['merchant']}');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          child: const Text('Tahan Audit', style: TextStyle(fontSize: 12)),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _releaseSingle(s),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Lepaskan Sekarang', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        ),
                      ] else if (status == 'held') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _releaseSingle(s),
                            icon: const Icon(Icons.lock_open, size: 16),
                            label: const Text('Nyah-Tahan & Lepaskan Payout', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                          ),
                        ),
                      ],
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

  void _releaseSingle(Map<String, dynamic> s) {
    setState(() {
      s['status'] = 'released';
      s['flagReason'] = null;
    });
    showGlassToast(context, 'Payout ${formatCurrency.format(s['net'])} berjaya dilepaskan ke akaun ${s['bank']} (${s['merchant']})!');
  }

  void _releaseBatch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white24)),
        title: const Text('Sahkan Pelepasan Batch DuitNow', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Semua payout yang bertaraf "Menunggu" akan diarahkan terus ke Payment Gateway Clearinghouse PayNet DuitNow. Teruskan?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (var s in _settlements) {
                  if (s['status'] == 'pending') {
                    s['status'] = 'released';
                  }
                }
              });
              showGlassToast(context, 'Batch payout berjaya diproses ke PayNet DuitNow!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Sahkan & Hantar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
