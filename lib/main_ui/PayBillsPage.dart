// pay_bills_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device_id/DeviceIDManager.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../helpers/data_transmitters/keypress_data_sender.dart';

class PayBillsPage extends StatefulWidget {
  @override
  _PayBillsPageState createState() => _PayBillsPageState();
}

class _PayBillsPageState extends State<PayBillsPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedBillType = 'Electricity';
  String _selectedProvider = '';
  String _selectedAccount = 'Savings Account - ****1234';
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final FocusNode _keyboardFocus = FocusNode();

  final Map<String, Map<String, dynamic>> _billTypes = {
    'Electricity': {
      'icon': Icons.electrical_services_rounded,
      'color': Colors.amber,
      'providers': ['MSEB Maharashtra', 'Tata Power Mumbai', 'BEST Mumbai', 'KPTCL Karnataka'],
      'description': 'Pay your electricity bills instantly',
      'numberLabel': 'Consumer Number',
    },
    'Water': {
      'icon': Icons.water_drop_rounded,
      'color': Colors.blue,
      'providers': ['Municipal Corporation', 'Water Board', 'Jal Board Delhi'],
      'description': 'Water utility bill payments',
      'numberLabel': 'Consumer ID',
    },
    'Gas': {
      'icon': Icons.local_gas_station_rounded,
      'color': Colors.orange,
      'providers': ['Indane Gas', 'Bharat Gas', 'HP Gas', 'Reliance Gas'],
      'description': 'LPG cylinder and pipeline gas bills',
      'numberLabel': 'Customer ID',
    },
    'Internet': {
      'icon': Icons.wifi_rounded,
      'color': Colors.purple,
      'providers': ['Airtel Broadband', 'Jio Fiber', 'BSNL Broadband', 'ACT Fibernet'],
      'description': 'Internet and broadband services',
      'numberLabel': 'Customer ID',
    },
    'Mobile': {
      'icon': Icons.phone_android_rounded,
      'color': Colors.green,
      'providers': ['Airtel', 'Jio', 'Vi (Vodafone Idea)', 'BSNL'],
      'description': 'Mobile postpaid bill payments',
      'numberLabel': 'Mobile Number',
    },
    'DTH': {
      'icon': Icons.tv_rounded,
      'color': Colors.red,
      'providers': ['Tata Sky', 'Airtel Digital TV', 'Dish TV', 'Sun Direct'],
      'description': 'DTH and cable TV recharges',
      'numberLabel': 'Subscriber ID',
    },
  };

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

    // Set initial provider
    _selectedProvider = _billTypes[_selectedBillType]!['providers'][0];

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _keyboardFocus.requestFocus());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.indigo.shade900;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) => DataCapture.onRawTouchUp(
        event,
        'pay_bills',
            (te) => CaptureStore().addTap(te),
      ),
      child: RawKeyboardListener(
        focusNode: _keyboardFocus,
        onKey: (event) => DataCapture.handleKeyEvent(
          event,
          'pay_bills',
              (kp) => CaptureStore().addKey(kp),
        ),
        child: GestureDetector(
          onPanStart: (details) => DataCapture.onSwipeStart(details),
          onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
          onPanEnd: (details) => DataCapture.onSwipeEnd(
            details,
            'pay_bills',
                (sw) => CaptureStore().addSwipe(sw),
          ),
          onTapDown: (details) => DataCapture.onTapDown(details),
          onTapUp: (details) => DataCapture.onTapUp(
            details,
            'pay_bills',
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
                            'pay_bills',
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
                                      Icons.receipt_long_rounded,
                                      color: primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bill Payments',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pay utility bills quickly and securely',
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

                              // Bill type selector
                              _buildSection(
                                title: 'Select Bill Type',
                                subtitle: 'Choose the utility service',
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 140,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _billTypes.length,
                                        itemBuilder: (context, index) {
                                          final billType = _billTypes.keys.elementAt(index);
                                          final billData = _billTypes[billType]!;
                                          final isSelected = _selectedBillType == billType;

                                          return Container(
                                            width: 110,
                                            margin: const EdgeInsets.only(right: 12),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedBillType = billType;
                                                    _selectedProvider = billData['providers'][0];
                                                  });
                                                  HapticFeedback.selectionClick();
                                                },
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
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
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? primaryColor
                                                              : Colors.grey.shade300,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Icon(
                                                          billData['icon'],
                                                          size: 28,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors.grey.shade600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Text(
                                                        billType,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSelected
                                                              ? primaryColor
                                                              : Colors.grey.shade700,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Payment account section
                              _buildSection(
                                title: 'Payment Account',
                                subtitle: 'Select account to debit from',
                                child: Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.indigo.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.account_balance_rounded,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Debit From',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: _selectedAccount,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),
                                        ),
                                        dropdownColor: Colors.white,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        items: [
                                          'Savings Account - ****1234',
                                          'Current Account - ****5678',
                                        ]
                                            .map((account) => DropdownMenuItem(
                                          value: account,
                                          child: Text(account),
                                        ))
                                            .toList(),
                                        onChanged: (value) => setState(() => _selectedAccount = value!),
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Bill details form
                              _buildSection(
                                title: '${_selectedBillType} Bill Details',
                                subtitle: _billTypes[_selectedBillType]!['description'],
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),

                                    // Service Provider
                                    DropdownButtonFormField<String>(
                                      value: _selectedProvider,
                                      decoration: InputDecoration(
                                        labelText: 'Service Provider',
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
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.business_rounded,
                                          color: primaryColor,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                      ),
                                      dropdownColor: Colors.white,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: (_billTypes[_selectedBillType]!['providers'] as List<String>)
                                          .map((provider) => DropdownMenuItem(
                                        value: provider,
                                        child: Text(provider),
                                      ))
                                          .toList(),
                                      onChanged: (value) => setState(() => _selectedProvider = value!),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Bill Number / Customer ID
                                    TextFormField(
                                      controller: _billNumberController,
                                      decoration: InputDecoration(
                                        labelText: _billTypes[_selectedBillType]!['numberLabel'],
                                        hintText: 'Enter ${_billTypes[_selectedBillType]!['numberLabel'].toLowerCase()}',
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
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                        prefixIcon: Icon(
                                          _selectedBillType == 'Mobile'
                                              ? Icons.phone_rounded
                                              : Icons.numbers_rounded,
                                          color: primaryColor,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: primaryColor,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                          _selectedBillType == 'Mobile' ? 10 : 15,
                                        ),
                                      ],
                                      validator: (value) {
                                        if (value?.isEmpty == true) {
                                          return 'This field is required';
                                        }
                                        if (_selectedBillType == 'Mobile' && value!.length != 10) {
                                          return 'Mobile number must be 10 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Amount
                                    TextFormField(
                                      controller: _amountController,
                                      decoration: InputDecoration(
                                        labelText: 'Bill Amount',
                                        hintText: 'Enter amount to pay',
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
                                          borderSide: BorderSide(color: primaryColor, width: 2),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.currency_rupee_rounded,
                                          color: primaryColor,
                                        ),
                                        suffixText: 'INR',
                                        suffixStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 20,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: primaryColor,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(7),
                                      ],
                                      validator: (value) {
                                        if (value?.isEmpty == true) {
                                          return 'Amount is required';
                                        }
                                        final amount = double.tryParse(value!);
                                        if (amount == null || amount <= 0) {
                                          return 'Enter a valid amount';
                                        }
                                        if (amount < 10) {
                                          return 'Minimum amount is ₹10';
                                        }
                                        if (amount > 50000) {
                                          return 'Maximum amount is ₹50,000';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Info container
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: Colors.blue.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Your ${_selectedBillType.toLowerCase()} bill will be processed instantly and confirmation will be sent via SMS.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue.shade700,
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
                              const SizedBox(height: 40),

                              // Pay button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _processBillPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                  child: _isProcessing
                                      ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Processing Payment...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                      : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payment_rounded, size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Pay Bill',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Security note
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'All bill payments are secured and processed through RBI approved channels',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
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

  void _processBillPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      try {
        final uuid = await DeviceIDManager.getUUID();
        final authManager = KeypressAuthManager(userId: uuid);
        final isAuthenticated = await authManager.sendKeyPressData(uuid: uuid, context: context);

        if (!isAuthenticated) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication failed. Payment cancelled.")),
          );
          return;
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication error: $e")),
        );
        return;
      }

      setState(() => _isProcessing = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Bill Type', _selectedBillType),
                      _buildReceiptRow('Provider', _selectedProvider),
                      _buildReceiptRow('Transaction ID', 'TXN${DateTime.now().millisecondsSinceEpoch}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A confirmation SMS has been sent to your registered mobile number.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
    );

      // Clear form
      _billNumberController.clear();
      _amountController.clear();
    }
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 14,
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}