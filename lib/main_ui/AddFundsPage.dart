// lib/screens/add_funds_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';

class AddFundsPage extends StatefulWidget {
  @override
  _AddFundsPageState createState() => _AddFundsPageState();
}

class _AddFundsPageState extends State<AddFundsPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedAccount = 'Savings Account - ****1234';
  String _selectedMethod = 'UPI';
  bool _isProcessing = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  final FocusNode _keyboardFocus = FocusNode();

  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'UPI': {
      'icon': Icons.qr_code_scanner,
      'color': Colors.indigo,
      'description': 'Instant transfer via UPI',
      'time': 'Instant',
      'fee': 'Free',
    },
    'Debit Card': {
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'description': 'Pay using your debit card',
      'time': '2–3 min',
      'fee': '₹2',
    },
    'Net Banking': {
      'icon': Icons.account_balance,
      'color': Colors.green,
      'description': 'From your bank account',
      'time': '5–10 min',
      'fee': 'Free',
    },
    'Bank Transfer': {
      'icon': Icons.compare_arrows,
      'color': Colors.orange,
      'description': 'Bank-to-bank transfer',
      'time': '1–2 hrs',
      'fee': '₹5',
    },
  };

  final List<int> _quickAmounts = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _keyboardFocus.requestFocus());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: _keyboardFocus,
        onKey: (event) => DataCapture.handleKeyEvent(
              event,
              'add_funds',
              (kp) => CaptureStore().addKey(kp),
            ),
        child: GestureDetector(
          onPanStart: (details) => DataCapture.onSwipeStart(details),
          onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
          onPanEnd: (details) => DataCapture.onSwipeEnd(
              details, 'add_funds', (sw) => CaptureStore().addSwipe(sw)),
          onTapDown: (details) => DataCapture.onTapDown(details),
          onTapUp: (details) => DataCapture.onTapUp(
              details, 'add_funds', (te) => CaptureStore().addTap(te)),
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              elevation: 1,
              backgroundColor: Colors.orangeAccent,
              centerTitle: true,
              title: const Text('Add Funds',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            body: ScaleTransition(
              scale: _scaleAnimation,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    DataCapture.onScrollStart(notification);
                  } else if (notification is ScrollUpdateNotification) {
                    DataCapture.onScrollUpdate(notification);
                  } else if (notification is ScrollEndNotification) {
                    DataCapture.onScrollEnd(notification, 'statements',
                        (se) => CaptureStore().addScroll(se));
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownField(
                          label: 'Account',
                          value: _selectedAccount,
                          options: const [
                            'Savings Account - ****1234',
                            'Current Account - ****5678',
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedAccount = val!),
                        ),
                        const SizedBox(height: 24),

                        // Quick-amount chips
                        const Text('Quick Amounts',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: _quickAmounts.map((amt) {
                            final isSelected =
                                _amountController.text == amt.toString();
                            return ChoiceChip(
                              label: Text('₹$amt'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() =>
                                    _amountController.text = amt.toString());
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Manual amount entry
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter Amount',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixText: '₹ ',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          validator: (val) {
                            final v = int.tryParse(val ?? '');
                            if (v == null || v <= 0)
                              return 'Please enter a valid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Payment method selection
                        const Text('Payment Method',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Column(
                          children: _paymentMethods.entries.map((entry) {
                            final key = entry.key;
                            final info = entry.value;
                            return RadioListTile<String>(
                              value: key,
                              groupValue: _selectedMethod,
                              onChanged: (val) =>
                                  setState(() => _selectedMethod = val!),
                              title: Text(key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  '${info['description']} · ${info['time']} · Fee ${info['fee']}'),
                              secondary:
                                  Icon(info['icon'], color: info['color']),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        Center(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Add Funds',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 2)); // simulate API
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('₹${_amountController.text} added successfully.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    _amountController.clear();
  }
}
