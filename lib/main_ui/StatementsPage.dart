import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/data_capture.dart';
import '../helpers/data_store.dart';

class StatementsPage extends StatefulWidget {
  @override
  _StatementsPageState createState() => _StatementsPageState();
}

class _StatementsPageState extends State<StatementsPage> with SingleTickerProviderStateMixin {
  // State variables
  String _selectedAccount = 'Savings Account - ****1234';
  String _selectedPeriod = 'Last 3 Months';
  final FocusNode _keyboardFocus = FocusNode();

  // Animation controllers and animations
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Data for the statements list
  final List<Map<String, dynamic>> _statements = [
    {'month': 'June 2025', 'type': 'Monthly', 'size': '2.1 MB', 'date': '2025-06-01'},
    {'month': 'May 2025', 'type': 'Monthly', 'size': '1.8 MB', 'date': '2025-05-01'},
    {'month': 'April 2025', 'type': 'Monthly', 'size': '2.3 MB', 'date': '2025-04-01'},
    {'month': 'Q1 2025', 'type': 'Quarterly', 'size': '5.2 MB', 'date': '2025-03-31'},
    {'month': 'March 2025', 'type': 'Monthly', 'size': '2.0 MB', 'date': '2025-03-01'},
    {'month': 'February 2025', 'type': 'Monthly', 'size': '1.7 MB', 'date': '2025-02-01'},
    {'month': 'January 2025', 'type': 'Monthly', 'size': '2.4 MB', 'date': '2025-01-01'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _keyboardFocus.requestFocus());

    // Initialize and start the new slide and fade animation
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
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.indigo.shade900;
    return RawKeyboardListener(
      focusNode: _keyboardFocus,
      onKey: (event) => DataCapture.handleKeyEvent(
        event,
        'statements',
            (kp) => CaptureStore().addKey(kp),
      ),
      child: GestureDetector(
        onPanStart: (details) => DataCapture.onSwipeStart(details),
        onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
        onPanEnd: (details) => DataCapture.onSwipeEnd(details, 'statements', (sw) => CaptureStore().addSwipe(sw)),
        onTapDown: (details) => DataCapture.onTapDown(details),
        onTapUp: (details) => DataCapture.onTapUp(details, 'statements', (te) => CaptureStore().addTap(te)),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                DataCapture.onScrollStart(notification);
              } else if (notification is ScrollUpdateNotification) {
                DataCapture.onScrollUpdate(notification);
              } else if (notification is ScrollEndNotification) {
                DataCapture.onScrollEnd(notification, 'statements', (se) => CaptureStore().addScroll(se));
              }
              return true;
            },
            // Use AnimatedBuilder to apply both slide and fade animations
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Section ---
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
                                  'Account Statements',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'View All Transactions',
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
                      const SizedBox(height: 16),

                      // --- Account & Period Selection ---
                      _buildDropdownField(
                        label: 'Select Account',
                        value: _selectedAccount,
                        options: const ['Savings Account - ****1234', 'Current Account - ****5678'],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedAccount = newValue);
                          }
                        },
                      ),
                      _buildDropdownField(
                        label: 'Select Period',
                        value: _selectedPeriod,
                        options: const ['Last 3 Months', 'Last 6 Months', 'Last Year', 'Custom Range'],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedPeriod = newValue);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // --- Available Statements List ---
                      _sectionHeader('Available Statements', 'Download your monthly or quarterly statements'),
                      const SizedBox(height: 10),
                      ListView.builder(
                        itemCount: _statements.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final s = _statements[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.description_outlined, color: Colors.indigo.shade700, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['month'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.5,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${s['type']} • ${s['size']} • ${s['date']}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.download_for_offline_outlined, color: Colors.indigo.shade800),
                                    tooltip: 'Download ${s['month']}',
                                    onPressed: () => _downloadStatement(s['month']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[900],
            )),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _downloadStatement(String month) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $month statement...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}