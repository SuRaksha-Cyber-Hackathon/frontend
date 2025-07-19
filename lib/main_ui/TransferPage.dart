import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device_id/DeviceIDManager.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';
import '../helpers/data_transmitters/keypress_data_sender.dart';

class TransferPage extends StatefulWidget {
  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final FocusNode _keyboardFocus = FocusNode();

  String _selectedAccount = 'Savings Account - ****1234';
  bool _isProcessing = false;

  final FocusNode _noteFocusNode = FocusNode();


  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _recentContacts = [
    {'name': 'John Doe', 'account': '****7890', 'bank': 'HDFC Bank'},
    {'name': 'Sarah Wilson', 'account': '****3456', 'bank': 'ICICI Bank'},
    {'name': 'Mike Johnson', 'account': '****8901', 'bank': 'SBI'},
  ];

  final Color primaryColor = Colors.indigo.shade900;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _keyboardFocus.dispose();
    _accountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          DataCapture.onRawTouchDown(event),
      onPointerUp: (event) =>
          DataCapture.onRawTouchUp(
            event,
            'RegisterPage',
                (te) => CaptureStore().addTap(te),
          ),
      child: RawKeyboardListener(
        focusNode: _keyboardFocus,
        onKey: (event) {
          if (!_noteFocusNode.hasFocus) {
            DataCapture.handleKeyEvent(
              event,
              'transfer_page',
                  (kp) => CaptureStore().addKey(kp),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: GestureDetector(
            onPanStart: (details) => DataCapture.onSwipeStart(details),
            onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
            onPanEnd: (details) =>
                DataCapture.onSwipeEnd(
                  details,
                  'transfer_page',
                      (swipe) => CaptureStore().addSwipe(swipe),
                ),
            onTapDown: DataCapture.onTapDown,
            onTapUp: (details) =>
                DataCapture.onTapUp(
                  details,
                  'transfer_page',
                      (tap) => CaptureStore().addTap(tap),
                ),
            behavior: HitTestBehavior.translucent,
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        DataCapture.onScrollStart(notification);
                      } else if (notification is ScrollUpdateNotification) {
                        DataCapture.onScrollUpdate(notification);
                      } else if (notification is ScrollEndNotification) {
                        DataCapture.onScrollEnd(
                            notification, 'transfer_page', (scrollEvent) =>
                            CaptureStore().addScroll(scrollEvent));
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: 32),
                            _buildFromAccountSection(),
                            SizedBox(height: 28),
                            _buildRecentContactsSection(),
                            SizedBox(height: 28),
                            _buildTransferFormSection(),
                            SizedBox(height: 36),
                            _buildTransferButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                'Transfer Money',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send money to anyone, anywhere',
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
    );
  }

  Widget _buildFromAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From Account',
          style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        SizedBox(height: 12),
        _buildDropdownField(
          label: 'Select Account',
          value: _selectedAccount,
          options: [
            'Savings Account - ****1234',
            'Current Account - ****5678'
          ],
          onChanged: (v) => setState(() => _selectedAccount = v!),
        ),
      ],
    );
  }

  Widget _buildRecentContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Contacts',
          style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        SizedBox(height: 16),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentContacts.length,
            itemBuilder: (context, index) {
              final contact = _recentContacts[index];
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _accountController.text = contact['account'],
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.indigo[50],
                          child: Text(
                            contact['name'][0],
                            style: TextStyle(color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          contact['name'].split(' ')[0],
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contact['account'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransferFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transfer Details', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800])),
        SizedBox(height: 16),
        TextFormField(
          controller: _accountController,
          decoration: InputDecoration(
            labelText: 'To Account Number',
            prefixIcon: Icon(Icons.account_balance, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (v) =>
          v?.isEmpty == true
              ? 'Account number is required'
              : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            suffixText: 'INR',
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v?.isEmpty == true) return 'Amount is required';
            final amount = double.tryParse(v!);
            if (amount == null || amount <= 0) return 'Enter valid amount';
            if (amount > 100000) return 'Maximum limit is ₹1,00,000';
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          focusNode: _noteFocusNode,
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'Note (Optional)',
            prefixIcon: Icon(Icons.note_alt, color: primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          maxLines: 2,
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isProcessing
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('PROCESSING...', style: TextStyle(color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.white),
            SizedBox(width: 8),
            Text('TRANSFER NOW', style: TextStyle(color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
          ],
        ),
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
      margin: const EdgeInsets.only(top: 0),
      // Adjusted margin as it's directly within a section now
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 18),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.indigo.shade700,
        ),
        dropdownColor: Colors.white,
        items: options
            .map((o) =>
            DropdownMenuItem(
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

  void _processTransfer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(seconds: 2));

      final amount = _amountController.text;
      final account = _accountController.text;

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
        builder: (ctx) =>
            AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
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
                    'Transfer Successful',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow(
                            'Amount', '₹$amount'),
                        _buildReceiptRow('To Account', _accountController.text),
                        _buildReceiptRow('Transaction ID', 'TXN${DateTime
                            .now()
                            .millisecondsSinceEpoch}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The transfer has been completed and a confirmation has been sent.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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

      // Clear inputs
      _amountController.clear();
      _accountController.clear();
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
