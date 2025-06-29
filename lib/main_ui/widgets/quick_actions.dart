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
        Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.send, 'Transfer', 'Send money to accounts', Colors.blue)),
            SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.payment, 'Pay Bills', 'Utility & service payments', Colors.green)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.add_circle, 'Add Funds', 'Deposit to account', Colors.orange)),
            SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.history, 'Statements', 'Download statements', Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onActionTap(title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
