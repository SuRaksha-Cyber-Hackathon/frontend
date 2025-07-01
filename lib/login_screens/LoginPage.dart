import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../controller/simple_ui_controller.dart';
import '../helpers/data_store.dart';
import '../main_ui/HomePage.dart';
import '../helpers/data_capture.dart'; // <-- Import DataCapture

class LoginPage extends StatefulWidget {
  final DateTime? lockUntil;
  const LoginPage({Key? key, this.lockUntil}) : super(key: key);
  static const String id = '/LoginPage';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Timer? _lockTimer;
  int _secondsLeft = 0;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.lockUntil != null) {
      _updateLockState();
      _lockTimer = Timer.periodic(Duration(seconds: 1), (_) {
        _updateLockState();
      });
    }
  }

  Future<bool> validateLogin(String username, String password) async {
    final savedUsername = await secureStorage.read(key: 'username');
    final savedPassword = await secureStorage.read(key: 'password');
    return username == savedUsername && password == savedPassword;
  }

  void _updateLockState() {
    final now = DateTime.now();
    if (widget.lockUntil != null && now.isBefore(widget.lockUntil!)) {
      setState(() {
        _secondsLeft = widget.lockUntil!.difference(now).inSeconds;
      });
    } else {
      _lockTimer?.cancel();
      setState(() {
        _secondsLeft = 0;
      });
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _secondsLeft > 0;
    var size = MediaQuery.of(context).size;
    SimpleUIController simpleUIController = Get.find<SimpleUIController>();

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        DataCapture.handleKeyEvent(
          event,
          'LoginPage',
              (e) {},
          fieldName: null,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) => DataCapture.onSwipeStart(details),
        onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
        onPanEnd: (details) =>
            DataCapture.onSwipeEnd(details, 'LoginPage', (e) {}),
        onTapDown: (details) => DataCapture.onTapDown(details),
        onTapUp: (details) => DataCapture.onTapUp(details, 'LoginPage', (te) => CaptureStore().addTap(te)),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildLargeScreen(locked, size, simpleUIController);
              } else {
                return _buildSmallScreen(locked, size, simpleUIController);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreen(
      bool locked, Size size, SimpleUIController simpleUIController) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: RotatedBox(
            quarterTurns: 3,
            child: Lottie.asset(
              'assets/coin.json',
              height: size.height * 0.3,
              width: double.infinity,
              fit: BoxFit.fill,
            ),
          ),
        ),
        SizedBox(width: size.width * 0.06),
        Expanded(
          flex: 5,
          child: _buildMainBody(locked, size, simpleUIController),
        ),
      ],
    );
  }

  Widget _buildSmallScreen(
      bool locked, Size size, SimpleUIController simpleUIController) {
    return Center(
      child: _buildMainBody(locked, size, simpleUIController),
    );
  }

  Widget _buildMainBody(
      bool locked, Size size, SimpleUIController simpleUIController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
      size.width > 600 ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        size.width > 600
            ? Container()
            : Lottie.asset(
          'wave.json',
          height: size.height * 0.2,
          width: size.width,
          fit: BoxFit.fill,
        ),
        SizedBox(height: size.height * 0.03),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text('Login', style: kLoginTitleStyle(size)),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text('Welcome Back', style: kLoginSubtitleStyle(size)),
        ),
        SizedBox(height: size.height * 0.03),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// Username
                TextFormField(
                  style: kTextFormFieldStyle(),
                  controller: nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Username or Gmail',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    } else if (value.length < 4) {
                      return 'at least enter 4 characters';
                    } else if (value.length > 13) {
                      return 'maximum character is 13';
                    }
                    return null;
                  },
                ),

                SizedBox(height: size.height * 0.02),

                /// Password
                Obx(
                      () => TextFormField(
                    style: kTextFormFieldStyle(),
                    controller: passwordController,
                    obscureText: simpleUIController.isObscure.value,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        icon: Icon(
                          simpleUIController.isObscure.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          simpleUIController.isObscureActive();
                        },
                      ),
                      hintText: 'Password',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      } else if (value.length < 7) {
                        return 'at least enter 6 characters';
                      } else if (value.length > 13) {
                        return 'maximum character is 13';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                SizedBox(height: size.height * 0.02),

                /// Login Button
                loginButton(locked),
                SizedBox(height: size.height * 0.03),

                /// Navigate to Sign Up
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    nameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    _formKey.currentState?.reset();
                    simpleUIController.isObscure.value = true;
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account?',
                      style: kHaveAnAccountStyle(size),
                      children: [
                        TextSpan(
                          text: " Sign up",
                          style: kLoginOrSignUpTextStyle(size),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget loginButton(bool locked) {
    final label = locked ? 'Locked ($_secondsLeft s)' : 'Login';
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
          MaterialStateProperty.all(Colors.deepPurpleAccent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: locked
            ? null
            : () async {
          if (_formKey.currentState!.validate()) {
            final username = nameController.text;
            final password = passwordController.text;

            final isValid = await validateLogin(username, password);

            if (!mounted) return;

            if (isValid) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('username', username);

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                CupertinoPageRoute(
                  builder: (ctx) => HomePage(username: username)),
                    (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                  Text('Invalid credentials. Please try again.'),
                ),
              );
            }
          }
        },
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
