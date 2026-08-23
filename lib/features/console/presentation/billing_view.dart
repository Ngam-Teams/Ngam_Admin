import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/stat_card.dart';

class BillingView extends StatelessWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final cards = [
                const StatCard(
                  label: 'Net Platform Profit',
                  value: 'RM 1,450', // Based on % of transactions
                  subtitle: '↑ 14% vs last month',
                  icon: HugeIcons.strokeRoundedChartIncrease,
                  accentColor: Color(0xFF44CF6C),
                ),
                const StatCard(
                  label: 'Active Shops',
                  value: '84',
                  subtitle: 'Free to join & use',
                  icon: HugeIcons.strokeRoundedStore01,
                  accentColor: Color(0xFF6C63FF),
                ),
                const StatCard(
                  label: 'Waived Fees (Grace Period)',
                  value: 'RM 240',
                  subtitle: 'Investment in new shops',
                  icon: HugeIcons.strokeRoundedGift,
                  accentColor: Color(0xFF4ECDC4),
                ),
              ];

              if (isDesktop) {
                return Row(
                  children: cards
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: e.key == 0 ? 20 : 0),
                              child: e.value,
                            ),
                          ))
                      .toList(),
                );
              } else {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards.map((c) => SizedBox(width: double.infinity, child: c)).toList(),
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // Platform Settings & Stripe Status Cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSettingsCard()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildBillplzStatusCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSettingsCard(),
                    const SizedBox(height: 24),
                    _buildBillplzStatusCard(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // Recent Transactions Table
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _generateTestInvoice(context),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedZap, color: Colors.black, size: 18),
                label: const Text('Generate Fake Unpaid Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransactionsTable(context),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.orangeAccent, size: 28, strokeWidth: 2),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A2A2E), Color(0xFF202024)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '2.0%',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FEE',
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Global Platform Fee',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'The baseline transaction cut applied to all shops. Tweaking this instantly updates the live pricing model.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tweak Percentage', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillplzStatusCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203A43).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, color: Colors.white, size: 32, strokeWidth: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                          SizedBox(width: 6),
                          Text('Connected', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Billplz Integration',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Active and syncing. Webhooks are healthy and listening for FPX payments.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(
                      children: [
                        Text('View Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTestInvoice(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      // Get up to 5 active businesses to attach invoices to
      var businesses = await supabase.from('businesses').select('id, business_name, business_email').limit(5);
      
      // Fallback to super_admin view if RLS blocks the direct query
      if (businesses.isEmpty) {
        businesses = await supabase.from('admin_tenant_view').select('id, business_name, business_email').limit(5);
      }

      // If the database is completely empty, insert a few mock businesses!
      if (businesses.isEmpty) {
        final mocks = [
          {'business_name': 'Mock App Shop', 'business_email': 'mock1@example.com', 'owner_user_id': supabase.auth.currentUser?.id},
          {'business_name': 'Wayne Enterprises', 'business_email': 'bruce@example.com', 'owner_user_id': supabase.auth.currentUser?.id},
          {'business_name': 'Stark Industries', 'business_email': 'tony@example.com', 'owner_user_id': supabase.auth.currentUser?.id},
        ];
        businesses = await supabase.from('businesses').insert(mocks).select('id, business_name, business_email');
      }

      // We use upsert because there is a UNIQUE constraint on (business_id, billing_month)
      for (var i = 0; i < businesses.length; i++) {
        final b = businesses[i];
        final amount = 50.00 + (i * 25.50); // Mix up the amounts
        await supabase.from('billing_invoices').upsert({
          'business_id': b['id'],
          'billing_month': DateTime.now().toIso8601String().split('T')[0],
          'amount_due': amount,
          'status': 'unpaid',
          'is_waived': false,
          'transaction_volume': 150 + (i * 45),
        }, onConflict: 'business_id, billing_month');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fake invoices generated for multiple stores!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating invoice: $e')));
      }
    }
  }

  Future<void> _handlePayInvoice(BuildContext context, Map<String, dynamic> invoice) async {
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating payment link...')));

      // First fetch the business email/name
      final businessRes = await Supabase.instance.client
          .from('businesses')
          .select('business_name, business_email')
          .eq('id', invoice['business_id'])
          .maybeSingle();

      final response = await Supabase.instance.client.functions.invoke(
        'billplz-manager',
        body: {
          'action': 'generate',
          'invoice_id': invoice['id'],
          'amount_due': invoice['amount_due'],
          'business_email': businessRes?['business_email'] ?? 'test@example.com',
          'business_name': businessRes?['business_name'] ?? 'Test Business',
        },
      );

      final data = response.data;
      if (data['payment_url'] != null) {
        final url = Uri.parse(data['payment_url'] as String);
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTransactionsTable(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('billing_invoices')
          .stream(primaryKey: ['id'])
          .order('billing_month', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading invoices: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = snapshot.data ?? [];
        
        if (invoices.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No invoices found. Click the "Generate" button above.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          );
        }

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
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: DataTable(
                    columnSpacing: 48,
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
                      DataColumn(label: Text('Date', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Business ID', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Volume', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Action', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                    ],
                    rows: invoices.map((inv) {
                      final isWaived = inv['is_waived'] == true;
                      final status = (inv['status'] as String).toLowerCase();
                      
                      Widget amountWidget;
                      if (isWaived) {
                        amountWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'RM ${inv['amount_due']}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const Text(
                              'Free (Waived)',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      } else {
                        amountWidget = Text('RM ${inv['amount_due']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
                      }

                      Widget actionWidget;
                      if (status == 'unpaid' && !isWaived) {
                        actionWidget = ElevatedButton(
                          onPressed: () => _handlePayInvoice(context, inv),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w600)),
                        );
                      } else {
                        actionWidget = IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedDownload01, color: Colors.white54, size: 18, strokeWidth: 2.1),
                          onPressed: () {},
                          tooltip: 'Download Receipt',
                        );
                      }

                      return DataRow(cells: [
                        DataCell(Text(inv['billing_month'].toString().split(' ')[0], style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))),
                        DataCell(Text('${inv['business_id'].toString().substring(0, 8)}...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                        DataCell(Text('${inv['transaction_volume']} Tx', style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))),
                        DataCell(amountWidget),
                        DataCell(_buildStatusBadge(status)),
                        DataCell(actionWidget),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.greenAccent;
        break;
      case 'waived':
        color = Colors.greenAccent;
        break;
      case 'unpaid':
        color = Colors.amber;
        break;
      default:
        color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
