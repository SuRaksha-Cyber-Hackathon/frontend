import 'dart:async';
import 'dart:math';
import 'package:crazy_bankers/main_ui/AddFundsPage.dart';
import 'package:crazy_bankers/main_ui/PayBillsPage.dart';
import 'package:crazy_bankers/main_ui/StatementsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';
import '../models/models.dart';
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

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;



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

    DateTime lastAccel = DateTime.now().subtract(const Duration(milliseconds: 1000));
    DateTime lastGyro = DateTime.now().subtract(const Duration(milliseconds: 1000));

    _accelSub = accelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(lastAccel).inMilliseconds >= 1000) {
        lastAccel = now;
        final sensorEvent = SensorEvent(
          type: 'accelerometer',
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: now,
          contextScreen: 'home',
        );
        CaptureStore().addSensor(sensorEvent);
        print('Accelerometer: ${sensorEvent.toMap()}');
      }
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(lastGyro).inMilliseconds >= 1000) {
        lastGyro = now;
        final sensorEvent = SensorEvent(
          type: 'gyroscope',
          x: event.x,
          y: event.y,
          z: event.z,
          timestamp: now,
          contextScreen: 'home',
        );
        CaptureStore().addSensor(sensorEvent);
        print('Gyroscope: ${sensorEvent.toMap()}');
      }
    });
  }



  @override
  void dispose() {
    _keyboardFocus.dispose();
    _accelSub?.cancel();
    _gyroSub?.cancel();
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
}
