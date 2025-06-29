// lib/screens/statements_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatementsPage extends StatefulWidget {
  @override
  _StatementsPageState createState() => _StatementsPageState();
}

class _StatementsPageState extends State<StatementsPage> {
  String _selectedAccount = 'Savings Account - ****1234';
  String _selectedPeriod = 'Last 3 Months';

  final List<Map<String, dynamic>> _statements = [
    {'month': 'June 2025',   'type': 'Monthly',    'size': '2.1 MB', 'date': '2025-06-01'},
    {'month': 'May 2025',    'type': 'Monthly',    'size': '1.8 MB', 'date': '2025-05-01'},
    {'month': 'April 2025',  'type': 'Monthly',    'size': '2.3 MB', 'date': '2025-04-01'},
    {'month': 'Q1 2025',     'type': 'Quarterly',  'size': '5.2 MB', 'date': '2025-03-31'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Statements', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: 'Account',
              value: _selectedAccount,
              options: const [
                'Savings Account - ****1234',
                'Current Account - ****5678',
              ],
              onChanged: (v) => setState(() => _selectedAccount = v!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Period',
              value: _selectedPeriod,
              options: const [
                'Last 3 Months',
                'Last 6 Months',
                'Last Year',
                'Custom Range',
              ],
              onChanged: (v) => setState(() => _selectedPeriod = v!),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _statements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = _statements[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Icon(Icons.description, color: Colors.indigo[700]),
                      ),
                      title: Text(s['month'], style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s['type']} • ${s['size']} • ${s['date']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.download_for_offline_outlined, color: Colors.indigo[800]),
                        tooltip: 'Download ${s['month']}',
                        onPressed: () => _downloadStatement(s['month']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  void _downloadStatement(String month) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $month statement...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
