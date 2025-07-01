import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/simple_ui_controller.dart';
import 'device_id/DeviceIDManager.dart';
import 'login_screens/RegisterPage.dart';
import 'main_ui/HomePage.dart';
import 'helpers/data_sender.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final uuid = await DeviceIDManager.getUUID();
  DataSenderService().initialize(uuid);
  DataSenderService().startForegroundSending();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final username = prefs.getString('username') ?? '';

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
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? HomePage(username: username) : SignUpView(),
    );
  }
}

