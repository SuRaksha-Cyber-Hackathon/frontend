import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';
import 'AddFundsPage.dart';
import 'PayBillsPage.dart';
import 'StatementsPage.dart';
import 'TransferPage.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _anomalyThreatLevel = 25;
  final FocusNode _keyboardFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dashboard data
  final List<Map<String, dynamic>> _recentTransactions = [
    {'type': 'Credit', 'amount': 5000.00, 'description': 'Salary Credit', 'date': '2025-06-29', 'category': 'Income'},
    {'type': 'Debit', 'amount': 1200.00, 'description': 'Rent Payment', 'date': '2025-06-28', 'category': 'Housing'},
    {'type': 'Debit', 'amount': 450.00, 'description': 'Grocery Shopping', 'date': '2025-06-27', 'category': 'Food'},
    {'type': 'Credit', 'amount': 2500.00, 'description': 'Freelance Payment', 'date': '2025-06-26', 'category': 'Income'},
    {'type': 'Debit', 'amount': 300.00, 'description': 'Utility Bill', 'date': '2025-06-25', 'category': 'Utilities'},
  ];

  final List<Map<String, dynamic>> _monthlySpending = [
    {'month': 'Jan', 'amount': 45000},
    {'month': 'Feb', 'amount': 52000},
    {'month': 'Mar', 'amount': 48000},
    {'month': 'Apr', 'amount': 55000},
    {'month': 'May', 'amount': 47000},
    {'month': 'Jun', 'amount': 51000},
  ];

  final List<Map<String, dynamic>> _accounts = [
    {'name': 'Savings Account', 'number': '****1234', 'balance': 123456.78, 'type': 'Savings'},
    {'name': 'Current Account', 'number': '****5678', 'balance': 45678.90, 'type': 'Current'},
    {'name': 'Fixed Deposit', 'number': '****9012', 'balance': 250000.00, 'type': 'FD'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _simulateAnomalyChange() {
    final isSevere = Random().nextBool();
    HapticFeedback.heavyImpact();

    if (isSevere) {
      setState(() => _anomalyThreatLevel = 80 + Random().nextInt(21));
      final unlockTime = DateTime.now().add(Duration(seconds: 30));
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Security Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800])),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Severe anomaly detected in your account activity.'),
              SizedBox(height: 8),
              Text('• Unusual access pattern detected', style: TextStyle(fontSize: 12)),
              Text('• Multiple failed authentication attempts', style: TextStyle(fontSize: 12)),
              Text('• Suspicious transaction behavior', style: TextStyle(fontSize: 12)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Application will be locked for 30 seconds for security purposes.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage(lockUntil: unlockTime)),
                      (_) => false,
                );
              },
              child: Text('ACKNOWLEDGE'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _anomalyThreatLevel = 30 + Random().nextInt(30));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Anomaly detected. Please re-authenticate.'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(lockUntil: null)),
              (_) => false,
        );
      });
    }
  }

  Color _indicatorColor() =>
      _anomalyThreatLevel < 30 ? Colors.green : _anomalyThreatLevel < 60 ? Colors.orange : Colors.red;

  String _indicatorText() =>
      _anomalyThreatLevel < 30 ? 'SECURE' : _anomalyThreatLevel < 60 ? 'CAUTION' : 'THREAT';

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocus,
      onKey: (event) => DataCapture.handleKeyEvent(event, 'dashboard', (kp) => CaptureStore().addKey(kp)),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.indigo[900],
          title: Text('Banking Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _indicatorColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _indicatorColor(), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: _indicatorColor(), size: 16),
                        SizedBox(width: 4),
                        Text(_indicatorText(), style: TextStyle(color: _indicatorColor(), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _simulateAnomalyChange,
                    tooltip: 'Refresh Security Status',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Summary Cards
                _buildAccountSummarySection(),
                SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsSection(),
                SizedBox(height: 24),

                // Recent Transactions
                _buildRecentTransactionsSection(),
                SizedBox(height: 24),

                // Spending Analytics
                _buildSpendingAnalyticsSection(),
                SizedBox(height: 24),

                // Security Status
                _buildSecurityStatusSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _accounts.length,
            itemBuilder: (context, index) {
              final account = _accounts[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: index == 0 ? [Colors.indigo[600]!, Colors.indigo[800]!] :
                        index == 1 ? [Colors.teal[600]!, Colors.teal[800]!] :
                        [Colors.purple[600]!, Colors.purple[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(account['name'], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(account['type'], style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(account['number'], style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Spacer(),
                        Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('₹ ${account['balance'].toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
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
          _navigateToPage(title);
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

  void _navigateToPage(String title) {
    Widget page;
    switch (title) {
      case 'Transfer':
        page = TransferPage();
        break;
      case 'Pay Bills':
        page = PayBillsPage();
        break;
      case 'Add Funds':
        page = AddFundsPage();
        break;
      case 'Statements':
        page = StatementsPage();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildRecentTransactionsSection() {
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
            children: _recentTransactions.map((transaction) {
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

  Widget _buildSpendingAnalyticsSection() {
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Spending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('₹51,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _monthlySpending.map((data) {
                      final maxAmount = _monthlySpending.map((e) => e['amount']).reduce((a, b) => a > b ? a : b);
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
      ],
    );
  }

  Widget _buildSecurityStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: _indicatorColor(), size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Threat Level: ${_indicatorText()}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Anomaly Score: $_anomalyThreatLevel/100',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _anomalyThreatLevel / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_indicatorColor()),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSecurityMetric('Last Login', '2 mins ago'),
                    _buildSecurityMetric('Device Trust', 'Verified'),
                    _buildSecurityMetric('2FA Status', 'Active'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}