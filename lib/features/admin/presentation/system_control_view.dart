import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/glass_toast.dart';

class SystemControlView extends StatefulWidget {
  final VoidCallback? onBack;
  const SystemControlView({super.key, this.onBack});

  @override
  State<SystemControlView> createState() => _SystemControlViewState();
}

class _SystemControlViewState extends State<SystemControlView> {
  bool _maintenanceMode = false;
  bool _gatewayKillSwitch = false; // true = blocked/frozen
  bool _posOfflineForced = false;
  bool _signupLocked = false;
  bool _isBackingUp = false;

  final TextEditingController _maintenanceMessageController = TextEditingController(
    text: 'Sistem Ngam sedang menjalani naiktaraf sistem keselamatan sehingga 4:00 AM.',
  );

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    super.dispose();
  }

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

            // Emergency Alert Banner
            if (_maintenanceMode || _gatewayKillSwitch)
              _buildCriticalWarningBanner()
            else
              _buildSystemNormalBanner(),
            const SizedBox(height: 24),

            const Text(
              'Suis Kecemasan Platform (Emergency Kill-Switches)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Toggle 1: Global Maintenance
            _buildSwitchTile(
              title: 'Mod Penyelenggaraan Global',
              subtitle: 'Paparkan skrin penyelenggaraan kepada semua pengguna & halang transaksi baru.',
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: const Color(0xFFEF4444),
              value: _maintenanceMode,
              onChanged: (val) {
                setState(() => _maintenanceMode = val);
                showGlassToast(
                  context,
                  val ? '⚠️ MOD PENYELENGGARAAN DIAKTIFKAN!' : 'Mod Penyelenggaraan dinyahaktifkan.',
                );
              },
            ),

            if (_maintenanceMode) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mesej Hebahan untuk Pengguna:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maintenanceMessageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black38,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Toggle 2: DuitNow Gateway Freeze
            _buildSwitchTile(
              title: 'Bekukan Payment Gateway & DuitNow QR',
              subtitle: 'Gantung penerimaan bayaran digital serta-merta jika gateway bank mengalami gangguan.',
              icon: HugeIcons.strokeRoundedCreditCardPos,
              color: const Color(0xFFF59E0B),
              value: _gatewayKillSwitch,
              onChanged: (val) {
                setState(() => _gatewayKillSwitch = val);
                showGlassToast(
                  context,
                  val ? '🛑 Payment Gateway telah dibekukan sementara!' : 'Payment Gateway beroperasi seperti biasa.',
                );
              },
            ),

            const SizedBox(height: 14),

            // Toggle 3: Force POS Offline Mode
            _buildSwitchTile(
              title: 'Paksa Peranti POS Beroperasi Offline',
              subtitle: 'Semua terminal POS akan simpan transaksi dalam memori lokal bagi kurangkan beban database.',
              icon: HugeIcons.strokeRoundedWifiDisconnected01,
              color: const Color(0xFF3B82F6),
              value: _posOfflineForced,
              onChanged: (val) {
                setState(() => _posOfflineForced = val);
                showGlassToast(context, 'Arahan mod offline dihantar ke semua POS.');
              },
            ),

            const SizedBox(height: 14),

            // Toggle 4: Signup lock
            _buildSwitchTile(
              title: 'Kunci Pendaftaran Peniaga Baru',
              subtitle: 'Halang pendaftaran akaun tenant baru buat sementara waktu.',
              icon: HugeIcons.strokeRoundedLock,
              color: const Color(0xFF8B5CF6),
              value: _signupLocked,
              onChanged: (val) {
                setState(() => _signupLocked = val);
                showGlassToast(context, val ? 'Pendaftaran baru dikunci.' : 'Pendaftaran baru dibuka.');
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Operasi Penyelenggaraan Pantas (DevOps Actions)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Instant Backup
            _buildActionButton(
              title: 'Lakukan Sandaran Database Segera (Instant Backup)',
              subtitle: 'Simpan snapshot penuh PostgreSQL & fail media ke Cloud Storage (GCS)',
              icon: HugeIcons.strokeRoundedDatabase01,
              buttonText: _isBackingUp ? 'Sedang Backup...' : 'Mula Backup Sekarang',
              buttonColor: const Color(0xFF10B981),
              isLoading: _isBackingUp,
              onTap: () async {
                setState(() => _isBackingUp = true);
                await Future.delayed(const Duration(seconds: 2));
                if (!context.mounted) return;
                setState(() => _isBackingUp = false);
                showGlassToast(context, '✅ Database Snapshot 20260930_1730 berjaya disimpan ke GCS!');
              },
            ),

            const SizedBox(height: 12),

            // Flush Cache
            _buildActionButton(
              title: 'Flush Cache Edge Function & Redis',
              subtitle: 'Kosongkan memori sementara untuk selesaikan isu paparan data lama',
              icon: HugeIcons.strokeRoundedClean,
              buttonText: 'Flush Cache Sekarang',
              buttonColor: const Color(0xFF6C63FF),
              isLoading: false,
              onTap: () => showGlassToast(context, 'Semua edge cache & session cache berjaya dikosongkan!'),
            ),
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
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedShield01,
            color: const Color(0xFFEF4444),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Kill-Switch & Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kawalan kecemasan keselamatan, mod offline, dan sekatan platform',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERHATIAN: SUIS KECEMASAN AKTIF', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Satu atau lebih suis kecemasan platform sedang diaktifkan. Transaksi atau capaian peniaga mungkin terjejas.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemNormalBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Platform: Normal & Selamat', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Semua subsistem pembayaran, pangkalan data, dan API beroperasi 100%.', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required dynamic icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: value ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(icon: icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required dynamic icon,
    required String buttonText,
    required Color buttonColor,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(icon: icon, color: buttonColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isLoading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
