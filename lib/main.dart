import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/simple_ui_controller.dart';
import 'device_id/DeviceIDManager.dart';
import 'firebase_options.dart';
import 'helpers/offline_data_sender.dart';
import 'login_screens/RegisterPage.dart';
import 'main_ui/HomePage.dart';
import 'helpers/data_sender.dart';
import 'models/SiameseModel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final uuid = await DeviceIDManager.getUUID();

  final prefs = await SharedPreferences.getInstance();
  // await prefs.clear() ;

  await SiameseModelService().loadModel();
  await TapAuthenticationManager().loadScores();
  await TapAuthenticationManager().initializeForUser(uuid);

  DataSenderService().initialize(uuid);
  DataSenderService().startForegroundSending();

  final rememberMe = prefs.getBool('remember_me') ?? false;
  final savedUsername = prefs.getString('username') ?? '';
  final user = FirebaseAuth.instance.currentUser;
  final isLoggedIn = rememberMe && user != null;
  final username = isLoggedIn ? (user.email ?? savedUsername) : '';

  Get.put(SimpleUIController());

  runApp(MyApp(isLoggedIn: isLoggedIn, username: username));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String username;

  const MyApp({super.key, required this.isLoggedIn, required this.username});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: TapAuthenticationManager.messengerKey,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? HomePage(username: username) : SignUpView(),
    );
  }
}
