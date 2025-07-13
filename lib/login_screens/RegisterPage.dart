import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';
import '../constants.dart';
import '../controller/simple_ui_controller.dart';
import '../models/models.dart';
import '../helpers/data_capture.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _keyboardListenerFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<KeyPressEvent> _keyPressEvents = [];
  final List<SwipeEvent> _swipeEvents = [];

  SimpleUIController simpleUIController = Get.put(SimpleUIController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardListenerFocusNode);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _showConsentDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Consent for Data Collection',
            style: TextStyle(
              color: Colors.deepPurpleAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text(
                  'By creating an account, you consent to the anonymous collection '
                      'of your behavioral metrics, including swipe, touch, scroll, '
                      'and accelerometer/gyroscope sensor data.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'This data is collected in accordance with government '
                      'privacy standards and is used solely to improve app security.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Decline', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('I Consent', style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'RegisterPage',
            (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
        focusNode: _keyboardListenerFocusNode,
        onKey: (ev) => DataCapture.handleKeyEvent(
          ev,
          'RegisterPage',
              (e) => setState(() => _keyPressEvents.add(e)),
          fieldName: _usernameFocusNode.hasFocus
              ? 'username'
              : _passwordFocusNode.hasFocus
              ? 'password'
              : null,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) => DataCapture.onSwipeStart(details),
          onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
          onPanEnd: (details) =>
              DataCapture.onSwipeEnd(details, 'RegisterPage', (e) {}),
          onTapDown: (details) => DataCapture.onTapDown(details),
          onTapUp: (details) => DataCapture.onTapUp(
            details,
            'RegisterPage',
                (te) => CaptureStore().addTap(te),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                DataCapture.onScrollStart(notification);
              } else if (notification is ScrollUpdateNotification) {
                DataCapture.onScrollUpdate(notification);
              } else if (notification is ScrollEndNotification) {
                DataCapture.onScrollEnd(notification, 'RegisterPage', (se) {});
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: false,
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMainBody(size, simpleUIController, theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMainBody(
      Size size, SimpleUIController simpleUIController, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign Up',
          style: kLoginTitleStyle(size),
        ),
        const SizedBox(height: 10),
        Text(
          'Create Account',
          style: kLoginSubtitleStyle(size),
        ),
        SizedBox(height: size.height * 0.03),
        Form(
          key: _formKey,
          child: Column(
            children: [
              /// Username
              TextFormField(
                style: kTextFormFieldStyle(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  } else if (value.length < 4) {
                    return 'At least enter 4 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: size.height * 0.02),

              /// Email
              TextFormField(
                style: kTextFormFieldStyle(),
                controller: emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_rounded),
                  hintText: 'Email ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter gmail';
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

              Text(
                'Creating an account means you\'re okay with our Terms of Services and our Privacy Policy',
                style: kLoginTermsAndPrivacyStyle(size),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.02),

              /// SignUp Button
              signUpButton(),
              SizedBox(height: size.height * 0.03),

              /// Navigate To Login Screen
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (ctx) => const LoginPage()));
                  nameController.clear();
                  emailController.clear();
                  passwordController.clear();
                  _formKey.currentState?.reset();

                  simpleUIController.isObscure.value = true;
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account?',
                    style: kHaveAnAccountStyle(size),
                    children: [
                      TextSpan(
                        text: " Login",
                        style: kLoginOrSignUpTextStyle(size),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget signUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.deepPurpleAccent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final consentGiven = await _showConsentDialog();
            if (!consentGiven) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You need to consent to proceed.'),
                ),
              );
              return;
            }

            try {
              final UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              );

              await userCredential.user
                  ?.updateDisplayName(nameController.text.trim());
              await userCredential.user?.reload();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (ctx) => const LoginPage(),
                ),
              );
            } on FirebaseAuthException catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message ?? "An unknown error occurred."),
                ),
              );
            }
          }
        },
        child: const Text('Sign Up',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
      ),
    );
  }
}
