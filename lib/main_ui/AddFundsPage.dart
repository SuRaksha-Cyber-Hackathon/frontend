// lib/screens/add_funds_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device_id/DeviceIDManager.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../helpers/keypress_data_sender.dart';
import 'PaymentSuccessPage.dart';

class AddFundsPage extends StatefulWidget {
  const AddFundsPage({super.key});

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
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  final FocusNode _keyboardFocus = FocusNode();

  bool _isQuickAmountSelected = false;


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
      'color': Colors.indigo[700],
      'description': 'Pay using your debit card',
      'time': '2–3 min',
      'fee': '₹2',
    },
    'Net Banking': {
      'icon': Icons.account_balance,
      'color': Colors.indigo,
      'description': 'From your bank account',
      'time': '5–10 min',
      'fee': 'Free',
    },
    'Bank Transfer': {
      'icon': Icons.compare_arrows,
      'color': Colors.indigo,
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final primaryColor = Colors.indigo.shade900;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'add_funds',
        (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
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
            details,
            'add_funds',
            (sw) => CaptureStore().addSwipe(sw),
          ),
          onTapDown: (details) => DataCapture.onTapDown(details),
          onTapUp: (details) => DataCapture.onTapUp(
            details,
            'add_funds',
            (te) => CaptureStore().addTap(te),
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification) {
                          DataCapture.onScrollStart(notification);
                        } else if (notification is ScrollUpdateNotification) {
                          DataCapture.onScrollUpdate(notification);
                        } else if (notification is ScrollEndNotification) {
                          DataCapture.onScrollEnd(
                            notification,
                            'add_funds',
                            (se) => CaptureStore().addScroll(se),
                          );
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.indigo.shade100,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fund Account',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add money to your account instantly',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),

                              // Account selection
                              _buildSection(
                                title: 'Destination Account',
                                child: _buildDropdownField(
                                  label: 'Select Account',
                                  value: _selectedAccount,
                                  options: const [
                                    'Savings Account - ****1234',
                                    'Current Account - ****5678',
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedAccount = val!),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Quick amounts
                              _buildSection(
                                title: 'Quick Select',
                                subtitle: 'Choose from common amounts',
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: _quickAmounts.map((amt) {
                                        final isSelected =
                                            _amountController.text ==
                                                amt.toString();
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _amountController
                                                  .text = amt.toString();
                                                _isQuickAmountSelected = true ;
                                                }
                                              );
                                              HapticFeedback.selectionClick();
                                            },
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.indigo.shade50
                                                    : Colors.grey.shade50,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? primaryColor
                                                      : Colors.grey.shade200,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '₹${amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: isSelected
                                                      ? primaryColor
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Amount input
                              _buildSection(
                                title: 'Enter Amount',
                                subtitle: 'Minimum ₹10, Maximum ₹1,00,000',
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(7),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Amount',
                                        hintText: 'Enter amount',
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                        ),
                                        prefixText: '₹ ',
                                        prefixStyle: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: primaryColor,
                                      ),
                                      validator: (val) {
                                        final v = int.tryParse(val ?? '');
                                        if (v == null || v <= 0) {
                                          return 'Please enter a valid amount';
                                        }
                                        if (v < 10) {
                                          return 'Minimum amount is ₹10';
                                        }
                                        if (v > 100000) {
                                          return 'Maximum amount is ₹1,00,000';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Payment methods
                              _buildSection(
                                title: 'Payment Method',
                                subtitle:
                                    'Choose your preferred payment option',
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    ..._paymentMethods.entries.map((entry) {
                                      final key = entry.key;
                                      final info = entry.value;
                                      final selected = _selectedMethod == key;
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(
                                                  () => _selectedMethod = key);
                                              HapticFeedback.selectionClick();
                                            },
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? Colors.indigo.shade50
                                                    : Colors.grey.shade50,
                                                border: Border.all(
                                                  color: selected
                                                      ? primaryColor
                                                      : Colors.grey.shade200,
                                                  width: selected ? 2 : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: selected
                                                          ? primaryColor
                                                          : Colors
                                                              .grey.shade300,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Icon(
                                                      info['icon'],
                                                      color: selected
                                                          ? Colors.white
                                                          : Colors
                                                              .grey.shade600,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          key,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 16,
                                                            color: selected
                                                                ? primaryColor
                                                                : Colors.grey
                                                                    .shade800,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          info['description'],
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Row(
                                                          children: [
                                                            _buildInfoChip(
                                                              icon: Icons
                                                                  .access_time_rounded,
                                                              text:
                                                                  info['time'],
                                                              selected:
                                                                  selected,
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            _buildInfoChip(
                                                              icon: info['fee'] ==
                                                                      'Free'
                                                                  ? Icons
                                                                      .money_off_rounded
                                                                  : Icons
                                                                      .currency_rupee_rounded,
                                                              text: info['fee'],
                                                              selected:
                                                                  selected,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Radio<String>(
                                                    value: key,
                                                    groupValue: _selectedMethod,
                                                    onChanged: (val) =>
                                                        setState(() =>
                                                            _selectedMethod =
                                                                val!),
                                                    activeColor: primaryColor,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Process Payment',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Security note
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.security_rounded,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your transaction is secured with 256-bit SSL encryption',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.indigo.shade900,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        child,
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.indigo.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: selected ? Colors.indigo.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.indigo.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo.shade900, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.indigo.shade700,
        ),
        dropdownColor: Colors.white,
        items: options
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        style: TextStyle(
          color: Colors.indigo.shade900,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'User';

    setState(() {
      _isProcessing = true;
    });

    if (_isQuickAmountSelected) {
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _isProcessing = false;
        _isQuickAmountSelected = false; // reset flag
      });

      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => PaymentSuccessPage(
            recipientName: username,
            amount: amount,
            transactionId: 'TXN123456789',
            paymentMethod: _selectedAccount,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = Curves.easeOutBack;
            final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

            return ScaleTransition(
              scale: curvedAnimation,
              child: child,
            );
          },
        ),
      );

      _amountController.clear();
      return;
    }

    final delay = Duration(milliseconds: 1000 + (1000 * (0.5 + (0.5 * (DateTime.now().millisecond % 1000) / 1000))).toInt());
    await Future.delayed(delay);

    final uuid = await DeviceIDManager.getUUID();
    final authManager = KeypressAuthManager(userId: uuid);
    final isAuthenticated = await authManager.sendKeyPressData(uuid: uuid, context: context);

    setState(() {
      _isProcessing = false;
    });

    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed. Payment cancelled.")),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => PaymentSuccessPage(
          recipientName: username,
          amount: amount,
          transactionId: 'TXN123456789',
          paymentMethod: _selectedAccount,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutBack;
          final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

          return ScaleTransition(
            scale: curvedAnimation,
            child: child,
          );
        },
      ),
    );

    _amountController.clear();
  }
}
