import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../controller/simple_ui_controller.dart';
import '../helpers/data_store.dart';
import '../main_ui/HomePage.dart';
import '../helpers/data_capture.dart';
import '../orchestrator/BBAOrchestrator.dart';
import 'RegisterPage.dart';
import 'otp_verification_page.dart';

class LoginPage extends StatefulWidget {
  final DateTime? lockUntil;
  final bool otpRequired;

  final bool anomalyCleared;

  const LoginPage({
    super.key,
    this.lockUntil,
    this.otpRequired = false,
    this.anomalyCleared = false,
  });

  static const String id = '/LoginPage';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Timer? _lockTimer;
  int _secondsLeft = 0;
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();

    if (widget.anomalyCleared) {
      print("[LoginPage] Clearing capture store after anomaly recovery.");
      CaptureStore().clear();
      BBAOrchestrator().onLoginSuccess();
    }

    if (widget.lockUntil != null) {
      _updateLockState();
      _lockTimer =
          Timer.periodic(Duration(seconds: 1), (_) => _updateLockState());
      _showLockoutDialog();
    }
  }

  void _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    if (rememberedEmail != null) {
      nameController.text = rememberedEmail;
      setState(() => _rememberMe = true);
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
      setState(() => _secondsLeft = 0);
    }
  }

  Future<void> _showLockoutDialog() async {
    if (!mounted) return;
    await Future.delayed(Duration(milliseconds: 100));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                "Account Locked",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                "Your account has been temporarily locked due to suspicious activity.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),

              // Countdown timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Try again in $_secondsLeft seconds",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // OK button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> firebaseLogin(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'User not found';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password';
        }
      else if (e.code == 'invalid-email') msg = 'Invalid email';
      _showSnackBar(msg, Colors.red);
      return false;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = nameController.text.trim();
    final password = passwordController.text.trim();

    final loginSuccess = await firebaseLogin(email, password);
    if (!mounted || !loginSuccess) return;

    // Handle OTP verification if required
    if (widget.otpRequired) {
      final otpVerified = await showOtpDialog(context, email);
      if (!otpVerified) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', email);
    if (_rememberMe) {
      await prefs.setString('remembered_email', email);
    } else {
      await prefs.remove('remembered_email');
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => HomePage(username: email)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    nameController.dispose();
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
      onPointerDown: (event) => DataCapture.onRawTouchDown(event),
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
          onTapUp: (details) => DataCapture.onTapUp(
              details, 'LoginPage', (te) => CaptureStore().addTap(te)),
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

  // Enhanced forgot password dialog
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String email = nameController.text.trim();
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reset password icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Title
                  Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Description
                  Text(
                    "We'll send a password reset link to:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Email display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      email.isEmpty ? "Please enter email first" : email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: email.isEmpty ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (isLoading || email.isEmpty)
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);
                                    Navigator.pop(context);
                                    _showSnackBar(
                                        "✅ Password reset email sent successfully",
                                        Colors.green);
                                  } catch (e) {
                                    Navigator.pop(context);
                                    _showSnackBar(
                                        "❌ Failed to send reset email",
                                        Colors.red);
                                  }
                                },
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Send Reset Link",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        CupertinoPageRoute(builder: (_) => const SignUpView()),
                        (route) => false,
                      );
                      nameController.clear();
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
        ]);
  }

  Widget loginButton(bool locked) {
    final label = locked ? 'Locked ($_secondsLeft s)' : 'Login';
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.deepPurpleAccent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: locked
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  final email = nameController.text.trim();
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

                    if (widget.otpRequired) {
                      await showOtpDialog(context, email);
                    }

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      CupertinoPageRoute(
                          builder: (ctx) => HomePage(username: email)),
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
