import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
                  label: 'Monthly Recurring Revenue',
                  value: '\$12,450',
                  subtitle: '↑ 14% vs last month',
                  icon: HugeIcons.strokeRoundedChartIncrease,
                  accentColor: Color(0xFF44CF6C),
                ),
                const StatCard(
                  label: 'Active Subscriptions',
                  value: '84',
                  subtitle: '↑ 5 new this week',
                  icon: HugeIcons.strokeRoundedUserGroup,
                  accentColor: Color(0xFF6C63FF),
                ),
                const StatCard(
                  label: 'Churn Rate',
                  value: '1.2%',
                  subtitle: 'Healthy (Below 3%)',
                  icon: HugeIcons.strokeRoundedActivity01,
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

          // Stripe Status Card
          _buildStripeStatusCard(),

          const SizedBox(height: 32),

          // Recent Transactions Table
          const Text(
            'Recent Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildTransactionsTable(context),
        ],
      ),
    );
  }

  Widget _buildStripeStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.2), // Stripe Purple
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, color: Color(0xFF635BFF), size: 28, strokeWidth: 2.1),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stripe Integration is Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last synced just now. Webhooks are healthy and receiving events.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 8),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(BuildContext context) {
    final mockTransactions = [
      {'date': '2026-08-18', 'business': 'Acme Corp', 'plan': 'Pro Plan', 'amount': '\$199.00', 'status': 'Paid'},
      {'date': '2026-08-17', 'business': 'Nexus Logic', 'plan': 'Enterprise', 'amount': '\$899.00', 'status': 'Paid'},
      {'date': '2026-08-16', 'business': 'Stark Industries', 'plan': 'Pro Plan', 'amount': '\$199.00', 'status': 'Failed'},
      {'date': '2026-08-15', 'business': 'Wayne Ent.', 'plan': 'Enterprise', 'amount': '\$899.00', 'status': 'Paid'},
      {'date': '2026-08-14', 'business': 'Globex', 'plan': 'Starter', 'amount': '\$49.00', 'status': 'Refunded'},
    ];

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
                  DataColumn(label: Text('Business', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Plan', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Receipt', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
                ],
                rows: mockTransactions.map((tx) {
                  return DataRow(cells: [
                    DataCell(Text(tx['date']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))),
                    DataCell(Text(tx['business']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                    DataCell(Text(tx['plan']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))),
                    DataCell(Text(tx['amount']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataCell(_buildStatusBadge(tx['status']!)),
                    DataCell(
                      IconButton(
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedDownload01, color: Colors.white54, size: 18, strokeWidth: 2.1),
                        onPressed: () {},
                        tooltip: 'Download Receipt',
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Paid':
        color = Colors.greenAccent;
        break;
      case 'Failed':
        color = Colors.redAccent;
        break;
      case 'Refunded':
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
