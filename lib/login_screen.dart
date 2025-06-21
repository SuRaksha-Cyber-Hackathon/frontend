import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart'; // Import your models

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _keyboardListenerFocusNode = FocusNode();

  final List<KeyPressEvent> _keyPressEvents = [];
  final List<SwipeEvent> _swipeEvents = []; // passed empty to HomePage

  final Map<LogicalKeyboardKey, DateTime> _keyDownTimes = {};
  LogicalKeyboardKey? _lastKeyLogicalKey;
  DateTime? _lastKeyReleaseTime;

  static const _commonDigrams = [
    MapEntry('t', 'h'), MapEntry('h', 'e'), MapEntry('i', 'n'),
    MapEntry('e', 'r'), MapEntry('a', 'n'), MapEntry('r', 'e'),
    MapEntry('e', 'd'), MapEntry('o', 'n'), MapEntry('e', 's'),
    MapEntry('s', 't'), MapEntry('e', 'n'), MapEntry('a', 't'),
  ];

  @override
  void initState() {
    super.initState();
    // Request keyboard focus once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardListenerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.logicalKey.debugName == null || event.logicalKey.keyLabel.isEmpty) {
      return;
    }
    final label = event.logicalKey.keyLabel.toLowerCase();
    final code = event.logicalKey.keyId.toString();
    String? field;
    if (_usernameFocusNode.hasFocus) field = 'username';
    if (_passwordFocusNode.hasFocus) field = 'password';

    if (event is RawKeyDownEvent) {
      _keyDownTimes[event.logicalKey] = DateTime.now();
    } else if (event is RawKeyUpEvent) {
      final down = _keyDownTimes[event.logicalKey];
      final up = DateTime.now();
      if (down != null) {
        final ms = up.difference(down).inMilliseconds;
        _addIndividualEvent(code, label, ms, field);
        _checkDigram(label, event.logicalKey, up, field);
        _keyDownTimes.remove(event.logicalKey);
      }
      _lastKeyLogicalKey = event.logicalKey;
      _lastKeyReleaseTime = up;
    }
  }

  void _addIndividualEvent(String code, String label, int ms, String? field) {
    final ev = KeyPressEvent(
      keyCode: code,
      keyLabel: label,
      eventType: 'individual',
      durationMs: ms,
      timestamp: DateTime.now(),
      contextScreen: 'login',
      fieldName: field,
    );
    setState(() => _keyPressEvents.add(ev));
  }

  void _checkDigram(String current, LogicalKeyboardKey currentKey, DateTime upTime, String? field) {
    if (_lastKeyLogicalKey == null || _lastKeyReleaseTime == null) return;
    final lastLabel = _lastKeyLogicalKey!.keyLabel.toLowerCase();
    final ms = upTime.difference(_lastKeyReleaseTime!).inMilliseconds;
    for (var d in _commonDigrams) {
      if (lastLabel == d.key && current == d.value) {
        final ev = KeyPressEvent(
          keyCode: '${_lastKeyLogicalKey!.keyId}-${currentKey.keyId}',
          keyLabel: lastLabel + current,
          eventType: 'digram',
          durationMs: ms,
          timestamp: upTime,
          digramKey1: lastLabel,
          digramKey2: current,
          contextScreen: 'login',
          fieldName: field,
        );
        setState(() => _keyPressEvents.add(ev));
        break;
      }
    }
  }

  void _login() {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'keyPressEvents': _keyPressEvents,
        'swipeEvents': _swipeEvents,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.shade700,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: RawKeyboardListener(
        focusNode: _keyboardListenerFocusNode,
        onKey: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _loginForm(),
        ),
      ),
    );
  }

  Widget _loginForm() => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _title(),
            const SizedBox(height: 40),
            _buildField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              label: 'Username',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              icon: Icons.lock,
              obscure: true,
            ),
            const SizedBox(height: 40),
            _loginButton(),
          ],
        ),
      ),
    ),
  );

  Widget _title() => Text(
    'Welcome to Behavioral Auth Demo',
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
    textAlign: TextAlign.center,
  );

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      onTap: () => _keyboardListenerFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _loginButton() => ElevatedButton(
    onPressed: _login,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
    ),
    child: const Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  );
}
