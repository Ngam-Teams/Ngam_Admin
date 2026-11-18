import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widgets/glass_toast.dart';

class SupportTicketsView extends StatefulWidget {
  final VoidCallback? onBack;
  const SupportTicketsView({super.key, this.onBack});

  @override
  State<SupportTicketsView> createState() => _SupportTicketsViewState();
}

class _SupportTicketsViewState extends State<SupportTicketsView> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  String _statusFilter = 'all';
  String _appFilter = 'all';
  String _searchQuery = '';
  bool _manualRefreshing = false;
  bool _signingIn = false;
  bool _obscurePassword = true;
  String? _authError;
  int _streamEpoch = 0;
  List<Map<String, dynamic>>? _manualRows;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInInline() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _authError = 'Sila masukkan e-mel dan kata laluan Super Admin.');
      return;
    }

    setState(() {
      _signingIn = true;
      _authError = null;
    });

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;
      _passwordCtrl.clear();
      setState(() {
        _signingIn = false;
        _streamEpoch++;
      });
      showGlassToast(context, 'Log masuk berjaya! Memuatkan tiket sokongan...');
      await _refreshTickets();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _signingIn = false;
        _authError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _signingIn = false;
        _authError = 'Gagal log masuk. Sila semak sambungan internet dan butiran akaun.';
      });
    }
  }

  Future<void> _refreshTickets() async {
    if (_client.auth.currentUser == null) {
      showGlassToast(
        context,
        'Sila log masuk akaun Super Admin untuk memuatkan tiket.',
        isError: true,
      );
      return;
    }
    if (_manualRefreshing) return;
    setState(() => _manualRefreshing = true);
    try {
      final rows = await _client
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _manualRows = List<Map<String, dynamic>>.from(rows as List);
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final msg = e.code == '42501'
            ? 'Akses ditolak. Pastikan akaun ini didaftarkan sebagai super_admin.'
            : 'Gagal memuat semula tiket (${e.code ?? 'Ralat Pelayan'}).';
        showGlassToast(context, msg, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showGlassToast(
          context,
          'Gagal menyambung ke pelayan tiket. Sila cuba sebentar lagi.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _manualRefreshing = false);
      }
    }
  }

  void _openImageLightbox(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 24,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'open' => 'Baru',
        'in_progress' => 'Disemak',
        'resolved' => 'Selesai',
        'closed' => 'Ditutup',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'in_progress' => const Color(0xFFF59E0B),
        'resolved' => const Color(0xFF10B981),
        'closed' => const Color(0xFF64748B),
        _ => const Color(0xFF6C63FF),
      };

  String _priorityLabel(String priority) => switch (priority) {
        'urgent' => 'Segera',
        'high' => 'Tinggi',
        'low' => 'Rendah',
        _ => 'Biasa',
      };

  Color _priorityColor(String priority) => switch (priority) {
        'urgent' => const Color(0xFFEF4444),
        'high' => const Color(0xFFF59E0B),
        'low' => const Color(0xFF64748B),
        _ => const Color(0xFF4ECDC4),
      };

  String _categoryLabel(String category) => switch (category) {
        'bug' => 'Pepijat / Bug',
        'feature' => 'Cadangan Ciri',
        'order_issue' => 'Isu Pesanan / QR',
        'payment' => 'Bayaran / Payout',
        'account' => 'Akaun / Akses',
        'hardware' => 'Pencetak / Perkakasan',
        _ => 'Lain-lain',
      };

  String _appLabel(String sourceApp) => switch (sourceApp) {
        'ngam_business' => 'Ngam Business',
        'ngam_admin' => 'Ngam Admin',
        _ => 'Ngam Customer',
      };

  Color _appColor(String sourceApp) => switch (sourceApp) {
        'ngam_business' => const Color(0xFF42A5F5),
        'ngam_admin' => const Color(0xFF8B5CF6),
        _ => const Color(0xFF4ECDC4),
      };

  Future<void> _openTriageDialog(Map<String, dynamic> ticket) async {
    String selectedStatus = ticket['status']?.toString() ?? 'open';
    final replyCtrl = TextEditingController(
      text: ticket['admin_reply']?.toString() ?? '',
    );
    bool saving = false;

    final rawAttachments = ticket['attachment_urls'];
    final List<String> attachments = rawAttachments is List
        ? rawAttachments
            .map((e) => e?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : const [];

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: const Color(0xFF141422),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dialog Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ticket['ticket_code']?.toString() ?? '',
                              style: const TextStyle(
                                color: Color(0xFF9C96FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _appColor(ticket['source_app']?.toString() ?? 'ngam')
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _appLabel(ticket['source_app']?.toString() ?? 'ngam'),
                              style: TextStyle(
                                color: _appColor(ticket['source_app']?.toString() ?? 'ngam'),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ticket['subject']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket['description']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reporter & Diagnostics Metadata
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _metaRow(
                              'Pelapor',
                              '${ticket['reporter_name'] ?? '-'} (${ticket['reporter_email'] ?? '-'})',
                            ),
                            if ((ticket['reporter_phone']?.toString() ?? '').isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 14),
                              _metaRow('Telefon', ticket['reporter_phone'].toString()),
                            ],
                            const Divider(color: Colors.white10, height: 14),
                            _metaRow(
                              'Kategori / Keutamaan',
                              '${_categoryLabel(ticket['category']?.toString() ?? 'bug')} • ${_priorityLabel(ticket['priority']?.toString() ?? 'normal')}',
                            ),
                            if ((ticket['device_info']?.toString() ?? '').isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 14),
                              _metaRow('Diagnostik', ticket['device_info'].toString()),
                            ],
                          ],
                        ),
                      ),

                      if (attachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'LAMPIRAN BUKTI',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: attachments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, idx) {
                              final url = attachments[idx];
                              return GestureDetector(
                                onTap: () => _openImageLightbox(url),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Text(
                        'KEMAS KINI STATUS TIKET',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['open', 'in_progress', 'resolved', 'closed'].map((st) {
                          final active = selectedStatus == st;
                          final color = _statusColor(st);
                          return GestureDetector(
                            onTap: saving
                                ? null
                                : () => setModalState(() => selectedStatus = st),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: active
                                    ? color.withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active ? color : Colors.white12,
                                ),
                              ),
                              child: Text(
                                _statusLabel(st),
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'BALASAN RASMI ADMIN (DIPAPAR KEPADA PELAPOR)',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: replyCtrl,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Tulis maklum balas penyelesaian atau tindakan susulan...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white12),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      setModalState(() => saving = true);
                                      try {
                                        final nowIso = DateTime.now().toUtc().toIso8601String();
                                        final reply = replyCtrl.text.trim();
                                        final isDone = selectedStatus == 'resolved' ||
                                            selectedStatus == 'closed';

                                        await _client.from('support_tickets').update({
                                          'status': selectedStatus,
                                          'admin_reply': reply.isEmpty ? null : reply,
                                          if (reply.isNotEmpty) ...{
                                            'replied_by': _client.auth.currentUser?.id,
                                            'replied_at': nowIso,
                                          },
                                          'resolved_at': isDone ? nowIso : null,
                                        }).eq('id', ticket['id']);

                                        // Notify user in-app if ticket belongs to a signed-in account
                                        final targetUserId = ticket['user_id']?.toString();
                                        if (targetUserId != null && targetUserId.isNotEmpty) {
                                          try {
                                            final bizId = ticket['business_id']?.toString();
                                            await _client.from('notifications').insert({
                                              'user_id': targetUserId,
                                              if (bizId != null && bizId.isNotEmpty)
                                                'business_id': bizId,
                                              'title':
                                                  'Tiket ${ticket['ticket_code']} • ${_statusLabel(selectedStatus)}',
                                              'message': reply.isNotEmpty
                                                  ? reply
                                                  : 'Status tiket sokongan anda telah dikemas kini kepada ${_statusLabel(selectedStatus)}.',
                                              'type': 'sistem',
                                              'reference_id': ticket['id']?.toString(),
                                            });
                                          } catch (_) {
                                            // Non-fatal if user notification insert is skipped
                                          }
                                        }

                                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                        await _refreshTickets();
                                        if (mounted) {
                                          showGlassToast(
                                            context,
                                            'Tiket ${ticket['ticket_code']} berjaya dikemas kini!',
                                          );
                                        }
                                      } on PostgrestException catch (e) {
                                        setModalState(() => saving = false);
                                        if (mounted) {
                                          final msg = e.code == '42501'
                                              ? 'Akses ditolak. Akaun Super Admin diperlukan untuk mengemas kini tiket.'
                                              : 'Gagal menyimpan kemas kini (${e.code ?? 'Ralat'}).';
                                          showGlassToast(context, msg, isError: true);
                                        }
                                      } catch (_) {
                                        setModalState(() => saving = false);
                                        if (mounted) {
                                          showGlassToast(
                                            context,
                                            'Gagal menyimpan kemas kini. Sila cuba semula.',
                                            isError: true,
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const HugeIcon(
                                      icon: HugeIcons.strokeRoundedSent02,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                              label: Text(saving ? 'Menyimpan...' : 'Simpan & Maklum Pelapor'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    replyCtrl.dispose();
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<AuthState>(
        stream: _client.auth.onAuthStateChange,
        builder: (context, _) {
          final currentUser = _client.auth.currentUser;
          if (currentUser == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopContextBar(isSignedIn: false),
                  const SizedBox(height: 16),
                  _buildKpiGrid(openCount: 0, reviewCount: 0, resolvedCount: 0),
                  const SizedBox(height: 20),
                  _buildSignInRequiredCard(),
                ],
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('tickets_${currentUser.id}_$_streamEpoch'),
            stream: _client
                .from('support_tickets')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              final rows =
                  snapshot.data ?? _manualRows ?? const <Map<String, dynamic>>[];

              final openCount = rows.where((r) => r['status'] == 'open').length;
              final reviewCount =
                  rows.where((r) => r['status'] == 'in_progress').length;
              final resolvedCount = rows
                  .where((r) => r['status'] == 'resolved' || r['status'] == 'closed')
                  .length;

              final filtered = rows.where((r) {
                final st = r['status']?.toString() ?? 'open';
                final src = r['source_app']?.toString() ?? 'ngam';
                if (_statusFilter != 'all' && st != _statusFilter) return false;
                if (_appFilter != 'all' && src != _appFilter) return false;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final hay = [
                    r['ticket_code'],
                    r['subject'],
                    r['description'],
                    r['reporter_name'],
                    r['reporter_email'],
                    r['reporter_phone'],
                    r['platform'],
                  ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
                  return hay.contains(q);
                }
                return true;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopContextBar(isSignedIn: true),
                    const SizedBox(height: 14),
                    _buildKpiGrid(
                      openCount: openCount,
                      reviewCount: reviewCount,
                      resolvedCount: resolvedCount,
                    ),
                    const SizedBox(height: 16),
                    _buildFilters(rows.length),
                    const SizedBox(height: 16),
                    if (snapshot.hasError && rows.isEmpty)
                      _buildErrorState(snapshot.error)
                    else if (snapshot.connectionState == ConnectionState.waiting &&
                        rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 56),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        ),
                      )
                    else if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map(_buildTicketCard),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopContextBar({required bool isSignedIn}) {
    final bool isEmbedded = widget.onBack != null;
    final Color statusColor =
        isSignedIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                const Color(0xFF6C63FF).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              if (!isEmbedded && Navigator.canPop(context)) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.30),
                  ),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCustomerSupport,
                    color: Color(0xFF4ECDC4),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSignedIn ? 'TRIAJ MASA NYATA' : 'SESI TETAMU',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Laporan pepijat & aduan pelanggan serta peniaga',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSignedIn) ...[
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _manualRefreshing ? null : _refreshTickets,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: _manualRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4ECDC4),
                              ),
                            )
                          : const HugeIcon(
                              icon: HugeIcons.strokeRoundedRefresh,
                              color: Colors.white,
                              size: 17,
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid({
    required int openCount,
    required int reviewCount,
    required int resolvedCount,
  }) {
    return Row(
      children: [
        _buildStatTile(
          label: 'Baru',
          value: '$openCount',
          color: const Color(0xFF6C63FF),
          icon: HugeIcons.strokeRoundedAlert02,
          filterValue: 'open',
        ),
        const SizedBox(width: 10),
        _buildStatTile(
          label: 'Disemak',
          value: '$reviewCount',
          color: const Color(0xFFF59E0B),
          icon: HugeIcons.strokeRoundedClock01,
          filterValue: 'in_progress',
        ),
        const SizedBox(width: 10),
        _buildStatTile(
          label: 'Selesai',
          value: '$resolvedCount',
          color: const Color(0xFF10B981),
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          filterValue: 'resolved',
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required dynamic icon,
    required String filterValue,
  }) {
    final isSelected = _statusFilter == filterValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _statusFilter = isSelected ? 'all' : filterValue;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: isSelected ? 0.22 : 0.10),
                Colors.white.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isSelected ? 0.70 : 0.24),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(icon: icon, color: color, size: 16),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
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

  Widget _buildSignInRequiredCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      color: Color(0xFF9C96FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Masuk Super Admin Diperlukan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Akses tiket dilindungi RLS pangkalan data',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Untuk melindungi privasi pelanggan & peniaga, log masuk akaun Super Admin anda di bawah bagi menyemak dan membalas tiket sokongan.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'E-mel Super Admin',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54, size: 19),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _signingIn ? null : _signInInline(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Kata Laluan',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 19),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white54,
                      size: 19,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
                  ),
                ),
              ),
              if (_authError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _authError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _signingIn ? null : _signInInline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _signingIn
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _signingIn ? 'Mengesahkan...' : 'Log Masuk & Muat Tiket',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final isPermDenied = error is PostgrestException && error.code == '42501';
    final title = isPermDenied
        ? 'Akses Super Admin Diperlukan'
        : 'Gagal Memuatkan Senarai Tiket';
    final desc = isPermDenied
        ? 'Akaun semasa (${_client.auth.currentUser?.email ?? '-'}) tidak mempunyai peranan super_admin pada jadual user_roles.'
        : 'Sambungan masa nyata ke pelayan tiket tergendala sementara. Sila muat semula.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _streamEpoch++),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cuba Semula'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _client.auth.signOut();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tukar Akaun'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Cari kod tiket, tajuk atau pelapor...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white54,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                'Semua ($totalCount)',
                _statusFilter == 'all',
                () => setState(() => _statusFilter = 'all'),
              ),
              _chip(
                'Baru',
                _statusFilter == 'open',
                () => setState(() => _statusFilter = 'open'),
              ),
              _chip(
                'Disemak',
                _statusFilter == 'in_progress',
                () => setState(() => _statusFilter = 'in_progress'),
                accent: const Color(0xFFF59E0B),
              ),
              _chip(
                'Selesai',
                _statusFilter == 'resolved',
                () => setState(() => _statusFilter = 'resolved'),
                accent: const Color(0xFF10B981),
              ),
              _chip(
                'Ditutup',
                _statusFilter == 'closed',
                () => setState(() => _statusFilter = 'closed'),
                accent: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                'Semua App',
                _appFilter == 'all',
                () => setState(() => _appFilter = 'all'),
                accent: const Color(0xFF4ECDC4),
              ),
              _chip(
                'Ngam Customer',
                _appFilter == 'ngam',
                () => setState(() => _appFilter = 'ngam'),
                accent: const Color(0xFF4ECDC4),
              ),
              _chip(
                'Ngam Business',
                _appFilter == 'ngam_business',
                () => setState(() => _appFilter = 'ngam_business'),
                accent: const Color(0xFF42A5F5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color accent = const Color(0xFF6C63FF),
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTicket02,
            color: Color(0xFF4ECDC4),
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Tiada tiket ditemui',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Semua laporan pepijat & maklum balas daripada Ngam Customer dan Ngam Business akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final code = ticket['ticket_code']?.toString() ?? '-';
    final status = ticket['status']?.toString() ?? 'open';
    final priority = ticket['priority']?.toString() ?? 'normal';
    final category = ticket['category']?.toString() ?? 'bug';
    final sourceApp = ticket['source_app']?.toString() ?? 'ngam';
    final statusColor = _statusColor(status);
    final prioColor = _priorityColor(priority);
    final appColor = _appColor(sourceApp);
    final reply = ticket['admin_reply']?.toString().trim() ?? '';

    final rawUrls = ticket['attachment_urls'];
    final List<String> urls = rawUrls is List
        ? rawUrls
            .map((e) => e?.toString().trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : const [];

    final createdAt =
        DateTime.tryParse(ticket['created_at']?.toString() ?? '')?.toLocal();
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: InkWell(
            onTap: () => _openTriageDialog(ticket),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: status == 'open'
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          showGlassToast(context, 'Kod tiket $code disalin.');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Color(0xFF9C96FF),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _appLabel(sourceApp),
                          style: TextStyle(
                            color: appColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: prioColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _priorityLabel(priority),
                          style: TextStyle(
                            color: prioColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket['subject']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket['description']?.toString() ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                  ),
                  if (urls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          color: Color(0xFF4ECDC4),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${urls.length} lampiran gambar (klik untuk semak & balas)',
                          style: const TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (reply.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Balasan Admin: $reply',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${ticket['reporter_name'] ?? '-'} • ${_categoryLabel(category)} • $dateStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Urus & Balas →',
                        style: TextStyle(
                          color: Color(0xFF9C96FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
