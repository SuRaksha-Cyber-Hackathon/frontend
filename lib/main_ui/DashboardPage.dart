import 'dart:math';
import 'package:flutter/material.dart';

import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';

import 'widgets/account_summary.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_transactions.dart';
import 'widgets/spending_analytics.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FocusNode _keyboardFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Dashboard data
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'type': 'Credit',
      'amount': 5000.00,
      'description': 'Salary Credit',
      'date': '2025-06-29',
      'category': 'Income'
    },
    {
      'type': 'Debit',
      'amount': 1200.00,
      'description': 'Rent Payment',
      'date': '2025-06-28',
      'category': 'Housing'
    },
    {
      'type': 'Debit',
      'amount': 450.00,
      'description': 'Grocery Shopping',
      'date': '2025-06-27',
      'category': 'Food'
    },
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
    {
      'name': 'Savings Account',
      'number': '****1234',
      'balance': 123456.78,
      'type': 'Savings'
    },
    {
      'name': 'Current Account',
      'number': '****5678',
      'balance': 45678.90,
      'type': 'Current'
    },
    {
      'name': 'Fixed Deposit',
      'number': '****9012',
      'balance': 250000.00,
      'type': 'FD'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'dashboard',
            (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
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
            onPanEnd: (details) => DataCapture.onSwipeEnd(
                details, 'dashboard', (sw) => CaptureStore().addSwipe(sw)),
            onTapDown: (details) => DataCapture.onTapDown(details),
            onTapUp: (details) => DataCapture.onTapUp(
                details, 'dashboard', (tp) => CaptureStore().addTap(tp)),
            child: Scaffold(
              backgroundColor: Colors.grey[50],
              body: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      DataCapture.onScrollStart(notification);
                    } else if (notification is ScrollUpdateNotification) {
                      DataCapture.onScrollUpdate(notification);
                    } else if (notification is ScrollEndNotification) {
                      DataCapture.onScrollEnd(notification, 'dashboard',
                              (se) => CaptureStore().addScroll(se));
                    }
                    return true;
                  },
                  child: SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        AccountSummarySection(
                          accounts: _accounts,
                        ),
                        const SizedBox(height: 24),
                        QuickActionsSection(onActionTap: _navigateToPage),
                        const SizedBox(height: 24),
                        RecentTransactionsSection(
                            transactions: _recentTransactions),
                        const SizedBox(height: 24),
                        SpendingAnalyticsSection(
                            monthlySpending: _monthlySpending),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
      ),
    );
  }

  void _navigateToPage(String title) {
    int? index;
    switch (title) {
      case 'Transfer':
        index = 1;
        break;
      case 'Add Funds':
        index = 2;
        break;
      case 'Pay Bills':
        index = 3;
        break;
      case 'Statements':
        index = 4;
        break;
      default:
        return;
    }

    if (index != null && widget.onNavigate != null) {
      widget.onNavigate!(index); // Delegate tab switch to HomePage
    }
  }

}