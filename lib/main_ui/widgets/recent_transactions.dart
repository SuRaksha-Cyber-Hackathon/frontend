import 'package:flutter/material.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentTransactionsSection({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            TextButton(
              onPressed: () {},
              child: Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: transactions.map((transaction) {
              final isCredit = transaction['type'] == 'Credit';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(transaction['description'], style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${transaction['date']} • ${transaction['category']}'),
                trailing: Text(
                  '${isCredit ? '+' : '-'}₹${transaction['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
