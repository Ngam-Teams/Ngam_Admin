// =============================================================================
// BusinessActionMenu
// Popup dropdown for Super Admin actions: Suspend / Upgrade / Impersonate.
// Calls ApiService on selection and feeds back a result callback.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../data/api_service.dart';
import '../../models/business_summary_model.dart';

class BusinessActionMenu extends StatelessWidget {
  final BusinessSummaryModel business;
  final ApiService apiService;
  final VoidCallback onActionComplete;

  const BusinessActionMenu({
    super.key,
    required this.business,
    required this.apiService,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_BusinessAction>(
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVerticalCircle01, color: Colors.white70, size: 18, strokeWidth: 2.1),
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (_) => [
        if (!business.isSuspended)
          _menuItem(
            _BusinessAction.suspend,
            'Suspend Account',
            HugeIcons.strokeRoundedCancel01,
            Colors.redAccent,
          ),
        if (business.isSuspended)
          _menuItem(
            _BusinessAction.reactivate,
            'Reactivate Account',
            HugeIcons.strokeRoundedTick01,
            Colors.greenAccent,
          ),
        _menuItem(
          _BusinessAction.upgradePro,
          'Upgrade → Pro',
          HugeIcons.strokeRoundedDiamond,
          Colors.amber,
        ),
        _menuItem(
          _BusinessAction.upgradeEnterprise,
          'Upgrade → Enterprise',
          HugeIcons.strokeRoundedDiamond,
          Colors.purpleAccent,
        ),
        _menuItem(
          _BusinessAction.impersonate,
          'Impersonate Business',
          HugeIcons.strokeRoundedUserGroup,
          Colors.cyanAccent,
        ),
      ],
    );
  }

  PopupMenuItem<_BusinessAction> _menuItem(
    _BusinessAction value,
    String label,
    dynamic icon,
    Color color,
  ) {
    return PopupMenuItem<_BusinessAction>(
      value: value,
      child: Row(
        children: [
          HugeIcon(icon: icon, color: color, size: 18, strokeWidth: 2.1),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _BusinessAction action) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      switch (action) {
        case _BusinessAction.suspend:
          await apiService.suspendBusiness(business.id);
          messenger.showSnackBar(
            SnackBar(
              content: Text('${business.businessName} suspended.'),
              backgroundColor: Colors.redAccent,
            ),
          );

        case _BusinessAction.reactivate:
          await apiService.upgradeBusiness(business.id, business.subscriptionTier);
          messenger.showSnackBar(
            SnackBar(
              content: Text('${business.businessName} reactivated.'),
              backgroundColor: Colors.greenAccent,
            ),
          );

        case _BusinessAction.upgradePro:
          await apiService.upgradeBusiness(business.id, 'pro');
          messenger.showSnackBar(
            SnackBar(content: Text('${business.businessName} upgraded to Pro.')),
          );

        case _BusinessAction.upgradeEnterprise:
          await apiService.upgradeBusiness(business.id, 'enterprise');
          messenger.showSnackBar(
            SnackBar(content: Text('${business.businessName} upgraded to Enterprise.')),
          );

        case _BusinessAction.impersonate:
          final session = await apiService.getBusinessSession(business.id);
          if (!context.mounted) return;
          _showImpersonationDialog(context, session);
          return; // don't trigger onActionComplete for read-only impersonation
      }

      onActionComplete();
    } on ConsoleApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showImpersonationDialog(BuildContext context, Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Impersonation Session',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are now viewing as:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              session['business_name'] ?? session['id'],
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Business ID: ${session['id']}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

enum _BusinessAction {
  suspend,
  reactivate,
  upgradePro,
  upgradeEnterprise,
  impersonate,
}
