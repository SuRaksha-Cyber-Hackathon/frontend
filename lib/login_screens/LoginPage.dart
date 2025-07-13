import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
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

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
    if (widget.lockUntil != null) {
      _updateLockState();
      _lockTimer = Timer.periodic(Duration(seconds: 1), (_) {
        _updateLockState();
      });
    }
  }

  void _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    if (rememberedEmail != null) {
      nameController.text = rememberedEmail;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<bool> firebaseLogin(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed.';
      if (e.code == 'user-not-found') msg = 'No user found with this email.';
      else if (e.code == 'wrong-password') msg = 'Incorrect password.';
      else if (e.code == 'invalid-email') msg = 'Invalid email format.';
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return false;
    }
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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'LoginPage',
            (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
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
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String email = nameController.text.trim();
        return AlertDialog(
          title: Text("Reset Password"),
          content: Text("Send reset link to $email?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if(!mounted) return ;
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset email sent")),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send reset email")),
                  );
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }


  Widget _buildLargeScreen(
      bool locked, Size size, SimpleUIController simpleUIController) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            // Removed Lottie animation, replaced with empty container
            height: size.height * 0.3,
            width: double.infinity,
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
      mainAxisAlignment: MainAxisAlignment.center, // Always center vertically
      children: [
        // Removed Lottie animation from small screen
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
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    } else if (!_isValidEmail(value.trim())) {
                      return 'Please enter a valid email';
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
                          } else if (value.length < 6) {
                            return 'At least enter 6 characters';
                          }
                          return null;
                        },
                      ),
                ),
                SizedBox(height: size.height * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                        ),
                        Text("Remember Me"),
                      ],
                    ),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text("Forgot Password?"),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.01),
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
            final email = nameController.text.trim();  // now used as email
            final password = passwordController.text.trim();
            final isValid = await firebaseLogin(email, password);

            if (!mounted) return;
            if (isValid) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('username', email);
              await prefs.setBool('remember_me', _rememberMe);
              if (_rememberMe) {
                await prefs.setString('username', email);
              } else {
                await prefs.remove('username');
              }


              if(!mounted) return ;

              Navigator.pushAndRemoveUntil(
                context,
                CupertinoPageRoute(builder: (ctx) => HomePage(username: email)),
                    (route) => false,
              );
            }

          }
        },
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}