import 'package:flutter/material.dart';

class SpendingAnalyticsSection extends StatelessWidget {
  final List<Map<String, dynamic>> monthlySpending;

  const SpendingAnalyticsSection({Key? key, required this.monthlySpending}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxAmount = monthlySpending.map((e) => e['amount']).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Spending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('₹51,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlySpending.map((data) {
                        final height = (data['amount'] / maxAmount) * 100;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 24,
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(data['month'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
