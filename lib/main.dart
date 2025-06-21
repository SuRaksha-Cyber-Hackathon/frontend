// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart'; // Import the new login screen file
import 'home_page.dart';    // Import the new home page file

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Behavioral Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Applying Inter font
      ),
      initialRoute: '/', // Set the initial route to the login screen
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
