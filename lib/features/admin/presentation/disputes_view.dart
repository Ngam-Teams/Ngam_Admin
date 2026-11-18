import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../widgets/glass_toast.dart';
import '../data/api_service.dart';

// =============================================================================
// Ngam Admin — Pemerhati & Penentu (Dispute Observer & Adjudication Center)
// =============================================================================

class DisputesView extends StatefulWidget {
  final VoidCallback? onBack;
  const DisputesView({super.key, this.onBack});

  @override
  State<DisputesView> createState() => _DisputesViewState();
}

class _DisputesViewState extends State<DisputesView> {
  final ApiService _api = ApiService();
  final NumberFormat _currFmt =
      NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

  String _filter = 'action'; // action | all | resolved
  String? _selectedDisputeId;
  bool _isResolving = false;
  bool _isSendingMsg = false;

  // Original chat observer cache keyed by dispute id
  final Map<String, Future<Map<String, dynamic>>> _origChatFutures = {};

  // Composer & Adjudication Form
  final TextEditingController _chatCtrl = TextEditingController();
  final TextEditingController _verdictNoteCtrl = TextEditingController();
  final TextEditingController _partialAmountCtrl = TextEditingController();
  String _selectedVerdict = 'refund_full';

  @override
  void dispose() {
    _chatCtrl.dispose();
    _verdictNoteCtrl.dispose();
    _partialAmountCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getOriginalChatFuture(
      Map<String, dynamic> d) {
    final id = (d['id'] ?? '').toString();
    return _origChatFutures.putIfAbsent(
      id,
      () => _api.fetchOriginalConversationMessages(
        conversationId: d['conversation_id']?.toString(),
        businessId: (d['business_id'] ?? '').toString(),
        customerId: (d['customer_id'] ?? '').toString(),
      ),
    );
  }

  void _selectDispute(Map<String, dynamic> d) {
    setState(() {
      _selectedDisputeId = d['id']?.toString();
      final req =
          double.tryParse((d['requested_refund_amount'] ?? 0).toString()) ??
              0.0;
      _partialAmountCtrl.text = (req * 0.5).toStringAsFixed(2);
      _verdictNoteCtrl.clear();
      _selectedVerdict = 'refund_full';
    });
  }

  Future<void> _sendMediatorMsg(String disputeId) async {
    final txt = _chatCtrl.text.trim();
    if (txt.isEmpty || _isSendingMsg) return;
    setState(() => _isSendingMsg = true);
    _chatCtrl.clear();
    try {
      await _api.sendModeratorMessage(disputeId: disputeId, message: txt);
    } catch (e) {
      if (mounted) showGlassToast(context, 'Gagal menghantar mesej: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingMsg = false);
    }
  }

  Future<void> _executeVerdict(Map<String, dynamic> d) async {
    final note = _verdictNoteCtrl.text.trim();
    if (note.isEmpty) {
      showGlassToast(
        context,
        'Sila tulis catatan rasmi keputusan Admin Ngam terlebih dahulu.',
        type: GlassToastType.warning,
      );
      return;
    }

    final reqAmt =
        double.tryParse((d['requested_refund_amount'] ?? 0).toString()) ?? 0.0;
    final orderTotal =
        double.tryParse((d['order_total_amount'] ?? 0).toString()) ?? 0.0;
    final maxCap = orderTotal > 0 ? orderTotal : reqAmt;

    double? partialAmt;
    String confirmSummary;
    if (_selectedVerdict == 'refund_full') {
      confirmSummary =
          'Refund Penuh (${_currFmt.format(reqAmt)}) akan dipulangkan daripada kedai ke Dompet Ngam pelanggan.';
    } else if (_selectedVerdict == 'refund_partial') {
      partialAmt = double.tryParse(_partialAmountCtrl.text.trim());
      if (partialAmt == null || partialAmt <= 0 || partialAmt > maxCap) {
        showGlassToast(
          context,
          'Masukkan jumlah refund separa yang sah (RM 0.01 - ${_currFmt.format(maxCap)}).',
          type: GlassToastType.warning,
        );
        return;
      }
      confirmSummary =
          'Refund Separa (${_currFmt.format(partialAmt)}) akan dipulangkan kepada pelanggan & baki dilepaskan kepada kedai.';
    } else {
      confirmSummary =
          'Pertikaian ditolak dan dana (${_currFmt.format(maxCap)}) kekal dilepaskan kepada pihak kedai.';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLegal01,
              color: Color(0xFFA855F7),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sahkan Keputusan Muktamad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$confirmSummary\n\nCatatan Rasmi: "$note"\n\nTindakan ini mengemas kini lejar kewangan secara atomik dan memaklumkan kedua-dua pihak.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Laksana Keputusan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isResolving = true);
    try {
      await _api.resolveDisputeCase(
        disputeId: d['id'].toString(),
        verdict: _selectedVerdict,
        moderatorNote: note,
        partialRefundAmount: partialAmt,
      );
      if (mounted) {
        _verdictNoteCtrl.clear();
        showGlassToast(
          context,
          'Keputusan muktamad telah direkodkan & lejar kewangan dikemas kini.',
          type: GlassToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, 'Ralat keputusan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _openLightbox(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _api.watchDisputes(),
        builder: (context, snap) {
          final all = snap.data ?? const <Map<String, dynamic>>[];

          final filtered = all.where((d) {
            final st = (d['status'] ?? '').toString();
            final resolved = st.startsWith('resolved_') || st == 'withdrawn';
            if (_filter == 'action') return !resolved;
            if (_filter == 'resolved') return resolved;
            return true;
          }).toList();

          Map<String, dynamic>? selected;
          if (_selectedDisputeId != null) {
            for (final d in all) {
              if (d['id']?.toString() == _selectedDisputeId) {
                selected = d;
                break;
              }
            }
          }

          return LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 960;

              if (isWide) {
                selected ??= filtered.isNotEmpty
                    ? filtered.first
                    : (all.isNotEmpty ? all.first : null);
                return Column(
                  children: [
                    _buildHeader(context, all),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 350,
                            child: _buildQueuePanel(filtered),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: selected == null
                                ? _buildEmptyWorkspace()
                                : _buildAdjudicationWorkspace(selected!, isWide),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Mobile / Narrow layout
              if (selected != null) {
                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              setState(() => _selectedDisputeId = null),
                        ),
                        Expanded(
                          child: Text(
                            'Kes #${selected['case_number'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildAdjudicationWorkspace(selected!, false),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildHeader(context, all),
                  const SizedBox(height: 14),
                  Expanded(child: _buildQueuePanel(filtered)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, List<Map<String, dynamic>> all) {
    final openCount = all.where((d) {
      final st = (d['status'] ?? '').toString();
      return !st.startsWith('resolved_') && st != 'withdrawn';
    }).length;
    final escalatedCount = all.where((d) {
      final st = (d['status'] ?? '').toString();
      return st == 'escalated' || st == 'under_review';
    }).length;

    return Row(
      children: [
        if (widget.onBack != null || Navigator.canPop(context))
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            ),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedLegal01,
            color: Color(0xFFF59E0B),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat Pertikaian (Pemerhati & Penentu)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Perhati chat asal kedai-pelanggan, selia mediasi 3-hala & laksana keputusan escrow.',
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _miniStatPill('$openCount Aktif', const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _miniStatPill('$escalatedCount Mediator', const Color(0xFFA855F7)),
      ],
    );
  }

  Widget _miniStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildQueuePanel(List<Map<String, dynamic>> filtered) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _filterChip('Aktif', 'action'),
                  const SizedBox(width: 6),
                  _filterChip('Semua', 'all'),
                  const SizedBox(width: 6),
                  _filterChip('Selesai', 'resolved'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Tiada kes pertikaian dalam kategori ini.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final d = filtered[i];
                          final id = (d['id'] ?? '').toString();
                          final isSel = id == _selectedDisputeId;
                          final st = (d['status'] ?? 'open').toString();
                          final sCol = _statusColor(st);
                          final req = double.tryParse(
                                  (d['requested_refund_amount'] ?? 0)
                                      .toString()) ??
                              0.0;
                          return GestureDetector(
                            onTap: () => _selectDispute(d),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.16)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF6C63FF)
                                      : sCol.withValues(alpha: 0.28),
                                  width: isSel ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: sCol.withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _statusLabel(st),
                                          style: TextStyle(
                                            color: sCol,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _currFmt.format(req),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '#${d['case_number'] ?? ''} • ${d['business_name'] ?? 'Kedai'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Pelanggan: ${d['customer_name'] ?? 'Pelanggan'}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (d['reason_text'] ?? '').toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String key) {
    final active = _filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF6C63FF)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWorkspace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedShield01,
              color: Colors.white24,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Pilih kes pertikaian untuk memantau & membuat keputusan.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjudicationWorkspace(Map<String, dynamic> d, bool isWide) {
    final st = (d['status'] ?? 'open').toString();
    final isResolved = st.startsWith('resolved_') || st == 'withdrawn';
    final sCol = _statusColor(st);
    final reqAmt =
        double.tryParse((d['requested_refund_amount'] ?? 0).toString()) ?? 0.0;
    final orderTotal =
        double.tryParse((d['order_total_amount'] ?? 0).toString()) ?? 0.0;
    final approvedAmt = d['approved_refund_amount'] != null
        ? double.tryParse(d['approved_refund_amount'].toString())
        : null;

    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            // Case Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: sCol.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                _statusLabel(st),
                                style: TextStyle(
                                  color: sCol,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '#${d['case_number'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d['customer_name'] ?? 'Pelanggan'}  ↔  ${d['business_name'] ?? 'Kedai'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currFmt.format(approvedAmt ?? reqAmt),
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Jumlah Asal: ${_currFmt.format(orderTotal)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const TabBar(
              indicatorColor: Color(0xFFA855F7),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Mediasi 3-Hala'),
                Tab(text: 'Pemerhati Chat Asal'),
                Tab(text: 'Bukti & Penentu'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildMediationTab(d, isResolved),
                  _buildOriginalChatObserverTab(d),
                  _buildEvidenceAndVerdictTab(d, isResolved, maxCap: orderTotal > 0 ? orderTotal : reqAmt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediationTab(Map<String, dynamic> d, bool isResolved) {
    final disputeId = (d['id'] ?? '').toString();
    final st = (d['status'] ?? 'open').toString();

    return Column(
      children: [
        if (!isResolved && st != 'escalated' && st != 'under_review')
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCrown02,
                  color: Color(0xFFC084FC),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kes ini masih dalam perbincangan kedai-pelanggan. Anda boleh memerhati atau sertai terus.',
                    style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 11.5),
                  ),
                ),
                TextButton(
                  onPressed: () => _api.enterModerationAsObserver(disputeId),
                  child: const Text(
                    'Sertai Mediator',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _api.watchDisputeMessages(disputeId),
            builder: (ctx, snap) {
              final msgs = snap.data ?? const <Map<String, dynamic>>[];
              if (msgs.isEmpty) {
                return const Center(
                  child: Text(
                    'Tiada mesej mediasi lagi.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                itemCount: msgs.length,
                itemBuilder: (_, i) => _buildMediationBubble(msgs[i]),
              );
            },
          ),
        ),
        if (!isResolved)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E111D),
              border: const Border(top: BorderSide(color: Colors.white12)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Hantar arahan atau soalan sebagai NGAM MEDIATOR...',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 12.5),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMediatorMsg(disputeId),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSendingMsg
                      ? null
                      : () => _sendMediatorMsg(disputeId),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text(
                    'Hantar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMediationBubble(Map<String, dynamic> m) {
    final role = (m['sender_role'] ?? 'customer').toString();
    final msg = (m['message'] ?? '').toString();
    final sender = (m['sender_name'] ?? '').toString();
    final atts = (m['attachments'] is List)
        ? (m['attachments'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final dt = DateTime.tryParse((m['created_at'] ?? '').toString())?.toLocal();
    final time = dt != null ? DateFormat('hh:mm a').format(dt) : '';

    if (role == 'system') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    final isMed = role == 'moderator';
    final isBiz = role == 'business';
    final badgeCol = isMed
        ? const Color(0xFFC084FC)
        : (isBiz ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24));

    return Align(
      alignment: isMed ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(11),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: badgeCol.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: badgeCol.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMed
                  ? 'NGAM MEDIATOR (ANDA)'
                  : '$sender • ${isBiz ? 'KEDAI' : 'PELANGGAN'}',
              style: TextStyle(
                  color: badgeCol, fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(msg,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.35)),
            if (atts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: atts
                    .map((u) => GestureDetector(
                          onTap: () => _openLightbox(u),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(u,
                                width: 96, height: 96, fit: BoxFit.cover),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 3),
            Text(time,
                style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalChatObserverTab(Map<String, dynamic> d) {
    final bizId = (d['business_id'] ?? '').toString();
    final custId = (d['customer_id'] ?? '').toString();
    final custName = (d['customer_name'] ?? 'Pelanggan').toString();
    final bizName = (d['business_name'] ?? 'Kedai').toString();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.visibility_rounded,
                  color: Color(0xFF34D399), size: 17),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MOD PEMERHATI (READ-ONLY) • Rekod chat asal 2-hala antara Pelanggan & Kedai sebelum/semasa transaksi.',
                  style: TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getOriginalChatFuture(d),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                );
              }
              final data = snap.data ?? const {};
              final msgs =
                  (data['messages'] as List<Map<String, dynamic>>?) ?? const [];
              if (msgs.isEmpty) {
                return const Center(
                  child: Text(
                    'Tiada rekod chat asal dijumpai antara pelanggan & kedai ini.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final senderId = (m['sender_id'] ?? '').toString();
                  final isCustomer = senderId == custId;
                  final roleCol = isCustomer
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF38BDF8);
                  final label = isCustomer
                      ? '$custName (Pelanggan)'
                      : '$bizName (Kedai / Staf • $bizId)';
                  final content = (m['content'] ?? '').toString();
                  final mediaUrl = m['media_url']?.toString();
                  final dt = DateTime.tryParse(
                          (m['created_at'] ?? '').toString())
                      ?.toLocal();
                  final timeStr = dt != null
                      ? DateFormat('dd MMM, hh:mm a').format(dt)
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: roleCol.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleCol.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: roleCol,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (content.isNotEmpty)
                          Text(
                            content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _openLightbox(mediaUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                mediaUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceAndVerdictTab(
    Map<String, dynamic> d,
    bool isResolved, {
    required double maxCap,
  }) {
    final custEvidence = (d['customer_evidence_urls'] is List)
        ? (d['customer_evidence_urls'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final bizEvidence = (d['business_evidence_urls'] is List)
        ? (d['business_evidence_urls'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final bizResp = (d['business_response_text'] ?? '').toString();
    final modNote = (d['moderator_note'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer vs Business Claims
          _claimBox(
            title: 'Aduan & Bukti Pelanggan (${d['customer_name'] ?? ''})',
            accent: const Color(0xFFFBBF24),
            body: (d['reason_text'] ?? '-').toString(),
            images: custEvidence,
          ),
          const SizedBox(height: 12),
          _claimBox(
            title: 'Penjelasan & Bukti Balas Kedai (${d['business_name'] ?? ''})',
            accent: const Color(0xFF38BDF8),
            body: bizResp.isNotEmpty
                ? bizResp
                : 'Kedai belum menghantar penjelasan balas rasmi.',
            images: bizEvidence,
          ),
          const SizedBox(height: 18),

          if (isResolved) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KES TELAH DISELESAIKAN (MUKTAMAD)',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    modNote.isNotEmpty ? modNote : 'Selesai.',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Adjudicator Panel ("Penentu")
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLegal01,
                        color: Color(0xFFC084FC),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Panel Penentu Keputusan (Super Admin)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _verdictRadio(
                    'refund_full',
                    'Refund Penuh kepada Pelanggan',
                    'Tolak daripada baki kedai & kredit ke Dompet Ngam pelanggan.',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),
                  _verdictRadio(
                    'refund_partial',
                    'Refund Separa (Kompromi)',
                    'Tetapkan jumlah refund khas kepada pelanggan; baki kekal milik kedai.',
                    const Color(0xFFF59E0B),
                  ),
                  if (_selectedVerdict == 'refund_partial') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _partialAmountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText:
                            'Jumlah Refund Separa (Maks ${_currFmt.format(maxCap)})',
                        prefixText: 'RM ',
                        prefixStyle: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _verdictRadio(
                    'release_business',
                    'Tolak Pertikaian • Lepaskan Dana ke Kedai',
                    'Kedai didapati mematuhi pesanan/servis; tiada refund kepada pelanggan.',
                    const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _verdictNoteCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Catatan Keputusan Rasmi Admin Ngam (Wajib)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText:
                          'Nyatakan alasan berasaskan bukti & rekod chat asal...',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          _isResolving ? null : () => _executeVerdict(d),
                      icon: _isResolving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.gavel_rounded, size: 18),
                      label: Text(
                        _isResolving
                            ? 'Memproses Keputusan...'
                            : 'Muktamadkan Keputusan & Kemaskini Lejar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _claimBox({
    required String title,
    required Color accent,
    required String body,
    required List<String> images,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, height: 1.4),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images
                  .map(
                    (u) => GestureDetector(
                      onTap: () => _openLightbox(u),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(u,
                            width: 78, height: 78, fit: BoxFit.cover),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _verdictRadio(
    String value,
    String title,
    String subtitle,
    Color accent,
  ) {
    final selected = _selectedVerdict == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedVerdict = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.white12,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? accent : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String st) {
    return switch (st) {
      'open' => 'Baru Dibuka',
      'business_responded' => 'Kedai Membalas',
      'escalated' => 'Panggil Mediator',
      'under_review' => 'Dalam Semakan',
      'resolved_refund_full' => 'Refund Penuh',
      'resolved_refund_partial' => 'Refund Separa',
      'resolved_release_business' => 'Dana ke Kedai',
      'withdrawn' => 'Ditarik Balik',
      _ => st,
    };
  }

  Color _statusColor(String st) {
    return switch (st) {
      'open' => const Color(0xFFF59E0B),
      'business_responded' => const Color(0xFF38BDF8),
      'escalated' || 'under_review' => const Color(0xFFA855F7),
      'resolved_refund_full' || 'resolved_refund_partial' => const Color(0xFF10B981),
      'resolved_release_business' => const Color(0xFF3B82F6),
      'withdrawn' => const Color(0xFF94A3B8),
      _ => const Color(0xFFF59E0B),
    };
  }
}
