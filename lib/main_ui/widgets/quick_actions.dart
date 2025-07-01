import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickActionsSection extends StatelessWidget {
  final Function(String) onActionTap;

  const QuickActionsSection({Key? key, required this.onActionTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildAction(Icons.send_rounded, 'Transfer', 'Send money to accounts')),
            const SizedBox(width: 20),
            Expanded(child: _buildAction(Icons.receipt_long_rounded, 'Pay Bills', 'Utility & service payments')),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildAction(Icons.add_circle_outline_rounded, 'Add Funds', 'Deposit to account')),
            const SizedBox(width: 20),
            Expanded(child: _buildAction(Icons.description_outlined, 'Statements', 'Download statements')),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onActionTap(title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF4F46E5),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.3,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}