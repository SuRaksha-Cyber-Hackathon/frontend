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
import 'widgets/account_summary.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_transactions.dart';
import 'widgets/spending_analytics.dart';
import 'widgets/security_status.dart';

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
    _animationController = AnimationController(duration: Duration(seconds: 1), vsync: this);
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
      autofocus: true,
      onKey: (event) => DataCapture.handleKeyEvent(
        event,
        'dashboard',
            (kp) => CaptureStore().addKey(kp),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) => DataCapture.onSwipeStart(details),
        onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
        onPanEnd: (details) =>
            DataCapture.onSwipeEnd(details, 'dashboard', (sw) => CaptureStore().addSwipe(sw)),
        onTapDown: (details) => DataCapture.onTapDown(details),
        onTapUp: (details) =>
            DataCapture.onTapUp(details, 'dashboard', (tp) => CaptureStore().addTap(tp)),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.indigo[900],
            title: Text('Banking Dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                          Text(_indicatorText(),
                              style: TextStyle(
                                  color: _indicatorColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  DataCapture.onScrollStart(notification);
                } else if (notification is ScrollUpdateNotification) {
                  DataCapture.onScrollUpdate(notification);
                } else if (notification is ScrollEndNotification) {
                  DataCapture.onScrollEnd(notification, 'dashboard', (se) => CaptureStore().addScroll(se));
                }
                return true;
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccountSummarySection(accounts: _accounts),
                    SizedBox(height: 24),
                    QuickActionsSection(onActionTap: _navigateToPage),
                    SizedBox(height: 24),
                    RecentTransactionsSection(transactions: _recentTransactions),
                    SizedBox(height: 24),
                    SpendingAnalyticsSection(monthlySpending: _monthlySpending),
                    SizedBox(height: 24),
                    SecurityStatusSection(anomalyThreatLevel: _anomalyThreatLevel),
                  ],
                ),
              ),
            ),
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
}
