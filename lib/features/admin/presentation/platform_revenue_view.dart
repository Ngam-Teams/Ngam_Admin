import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../widgets/glass_toast.dart';

class PlatformRevenueView extends StatefulWidget {
  final VoidCallback? onBack;
  const PlatformRevenueView({super.key, this.onBack});

  @override
  State<PlatformRevenueView> createState() => _PlatformRevenueViewState();
}

class _PlatformRevenueViewState extends State<PlatformRevenueView> {
  final formatCurrency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

  final List<Map<String, dynamic>> _sectorBreakdown = [
    {
      'sector': 'Barber & Hair Salons',
      'gmv': 620000.00,
      'takeRate': 1.5,
      'revenue': 9300.00,
      'subsMrr': 7920.00,
      'totalEarned': 17220.00,
      'icon': HugeIcons.strokeRoundedScissor,
      'color': const Color(0xFF6C63FF),
    },
    {
      'sector': 'F&B, Kafe & Restoran',
      'gmv': 580000.00,
      'takeRate': 1.5,
      'revenue': 8700.00,
      'subsMrr': 6400.00,
      'totalEarned': 15100.00,
      'icon': HugeIcons.strokeRoundedCoffee01,
      'color': const Color(0xFF4ECDC4),
    },
    {
      'sector': 'Bengkel & Servis Automotif',
      'gmv': 182900.00,
      'takeRate': 1.5,
      'revenue': 2743.50,
      'subsMrr': 2850.00,
      'totalEarned': 5593.50,
      'icon': HugeIcons.strokeRoundedWrench01,
      'color': const Color(0xFFF9C80E),
    },
    {
      'sector': 'Spa & Pusat Terapi',
      'gmv': 100000.00,
      'takeRate': 1.5,
      'revenue': 1500.00,
      'subsMrr': 1480.00,
      'totalEarned': 2980.00,
      'icon': HugeIcons.strokeRoundedSparkles,
      'color': const Color(0xFFFF6B6B),
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
            const SizedBox(height: 20),

            // Top Revenue Hero Card
            _buildRevenueHeroCard(),
            const SizedBox(height: 24),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pecahan Mengikut Sektor', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: () => showGlassToast(context, 'Laporan Kewangan PDF dimuat turun ke Downloads!'),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Eksport Penyata PDF', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._sectorBreakdown.map((sec) => _buildSectorCard(sec)),

            const SizedBox(height: 24),
            _buildTakeRateExplainer(),
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
            icon: HugeIcons.strokeRoundedChartIncrease,
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
                'Platform Revenue & Take-Rate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Analisis kutipan langganan SaaS & komisen transaksi PayNet DuitNow',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Keuntungan Bersih Platform (Bulan Semasa)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('↑ +24.8% vs Ogos', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency.format(40893.50),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('Gross Volume (GMV)', formatCurrency.format(1482900.00), Colors.white),
                  _statItem('Komisen MDR (1.5%)', formatCurrency.format(22243.50), const Color(0xFF4ECDC4)),
                  _statItem('SaaS MRR', formatCurrency.format(18650.00), const Color(0xFF6C63FF)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectorCard(Map<String, dynamic> sec) {
    final color = sec['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: HugeIcon(icon: sec['icon'], color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(sec['sector'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      formatCurrency.format(sec['totalEarned']),
                      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GMV: ${formatCurrency.format(sec['gmv'])}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('MDR (1.5%): ${formatCurrency.format(sec['revenue'])}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('MRR: ${formatCurrency.format(sec['subsMrr'])}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
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

  Widget _buildTakeRateExplainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Struktur Hasil Ngam: Platform menjana hasil daripada komisen tetap 1.5% bagi setiap transaksi DuitNow QR serta yuran langganan bulanan SaaS (Starter RM49, Pro Growth RM99).',
              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
