import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_screens/RegisterPage.dart';

// Import your data‐sender service
import 'helpers/data_sender.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kick off the foreground data sender
  // DataSenderService().startForegroundSending();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpView(),
    );
  }
}
