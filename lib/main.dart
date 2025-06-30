import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'device_id/DeviceIDManager.dart';
import 'login_screens/RegisterPage.dart';

import 'helpers/data_sender.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final uuid = await DeviceIDManager.getUUID();
  print('UUID is : ${uuid}');
  DataSenderService().initialize(uuid);

  DataSenderService().startForegroundSending();

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
