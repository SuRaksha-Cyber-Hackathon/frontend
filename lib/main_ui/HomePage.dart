import 'dart:async';
import 'package:crazy_bankers/main_ui/AddFundsPage.dart';
import 'package:crazy_bankers/main_ui/PayBillsPage.dart';
import 'package:crazy_bankers/main_ui/StatementsPage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';
import '../models/models.dart';
import 'DashboardPage.dart';
import 'ProfilePage.dart';
import 'TransferPage.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FocusNode _keyboardFocus = FocusNode();
  final int _anomalyThreatLevel = 25;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  void _simulateAnomalyChange() async {
    HapticFeedback.heavyImpact();

    bool success = await _sendOtpToEmail();
    if (success) {
      if (!mounted) return;

      // Go to OTP verification screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(otpRequired: true)),
            (_) => false,
      );
    } else {
      // OTP sending failed - show error
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text("OTP Send Failed", style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text("Could not send OTP. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _sendOtpToEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (email == null) {
        print("User email not found!");
        return false;
      }

      final response = await Dio().post(
        "https://zhmx7x9x-5000.inc1.devtunnels.ms/send-otp",
        data: {"email": email},
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("📧 OTP sent to $email");
        }
        return true;
      } else {
        print("❌ Failed to send OTP");
        return false;
      }
    } catch (e) {
      print("❌ Error sending OTP: $e");
      return false;
    }
  }


  Color _indicatorColor() {
    if (_anomalyThreatLevel > 75) return Colors.red;
    if (_anomalyThreatLevel > 50) return Colors.orange;
    return Colors.green;
  }

  late final List<Widget> _pages ;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _keyboardFocus.requestFocus());

    _pages = [
      DashboardScreen(onNavigate: _onItemTapped),
      TransferPage(),
      AddFundsPage(),
      PayBillsPage(),
      StatementsPage(),
    ];

    DateTime lastAccel = DateTime.now().subtract(
        const Duration(milliseconds: 1000));
    DateTime lastGyro = DateTime.now().subtract(
        const Duration(milliseconds: 1000));

    _accelSub = accelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (now
          .difference(lastAccel)
          .inMilliseconds >= 1000) {
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
      if (now
          .difference(lastGyro)
          .inMilliseconds >= 1000) {
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
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'home',
            (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
        focusNode: _keyboardFocus,
        onKey: (event) =>
            DataCapture.handleKeyEvent(
              event,
              'home',
                  (kp) => CaptureStore().addKey(kp),
            ),
        child: Scaffold(
          drawer: const ProfileSidebar(),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false, // disables default hamburger icon

            leading: Builder(
              builder: (context) {
                return IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: 40,
                  icon: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.indigo),
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'Open Profile Sidebar',
                );
              },
            ),

            title: Row(
              children: [
              ],
            ),

            actions: [
              IconButton(
                icon: Icon(Icons.notifications_none_outlined, color: Colors.grey[800]),
                tooltip: 'Notifications',
                onPressed: () {
                  // Notifications screen logic here
                },
              ),
              SizedBox(width: 4),
              InkWell(
                onTap: _simulateAnomalyChange,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(6),
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _indicatorColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _indicatorColor(), width: 1),
                  ),
                  child: Icon(Icons.shield, color: _indicatorColor(), size: 18),
                ),
              ),
            ],
          ),

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
                icon: Icon(Icons.send),
                label: 'Transfer',
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
      ),
    );
  }
}
