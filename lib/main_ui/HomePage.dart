import 'dart:math';
import 'package:crazy_bankers/main_ui/AddFundsPage.dart';
import 'package:crazy_bankers/main_ui/PayBillsPage.dart';
import 'package:crazy_bankers/main_ui/StatementsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';
import 'DashboardPage.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FocusNode _keyboardFocus = FocusNode();
  int _anomalyThreatLevel = 25;

  static const List<String> _titles = [
    'Dashboard',
    'Add Funds',
    'Pay Bills',
    'Transactions',
  ];

  static final List<Widget> _pages = [
    DashboardScreen(),
    AddFundsPage(),
    PayBillsPage(),
    StatementsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _keyboardFocus.requestFocus());
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocus,
      onKey: (event) => DataCapture.handleKeyEvent(
        event,
        'home',
            (kp) => CaptureStore().addKey(kp),
      ),
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo[800],
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Add Funds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              label: 'Pay Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Transactions',
            ),
          ],
        ),
      ),
    );
  }

  void _simulateAnomalyChange() {
    final isSevere = Random().nextBool();
    if (isSevere) {
      setState(() => _anomalyThreatLevel = 80 + Random().nextInt(21));
      final unlockTime = DateTime.now().add(Duration(seconds: 30));
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('Security Alert', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Severe anomaly detected. App locked for 30 seconds.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(lockUntil: unlockTime),
                  ),
                      (_) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _anomalyThreatLevel = 30 + Random().nextInt(30));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anomaly detected. Please log in again.'),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(lockUntil: null),
          ),
              (_) => false,
        );
      });
    }
  }
}
