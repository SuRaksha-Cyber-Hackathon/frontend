// transfer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransferPage extends StatefulWidget {
  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedAccount = 'Savings Account - ****1234';
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _recentContacts = [
    {'name': 'John Doe', 'account': '****7890', 'bank': 'HDFC Bank'},
    {'name': 'Sarah Wilson', 'account': '****3456', 'bank': 'ICICI Bank'},
    {'name': 'Mike Johnson', 'account': '****8901', 'bank': 'SBI'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        title: Text('Transfer Money', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFromAccountSection(),
                    SizedBox(height: 24),
                    _buildRecentContactsSection(),
                    SizedBox(height: 24),
                    _buildTransferFormSection(),
                    SizedBox(height: 32),
                    _buildTransferButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFromAccountSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo[600]!, Colors.indigo[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('From Account', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedAccount,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: Colors.indigo[800],
              style: TextStyle(color: Colors.white, fontSize: 16),
              items: [
                'Savings Account - ****1234 (₹1,23,456.78)',
                'Current Account - ****5678 (₹45,678.90)'
              ].map((e) => DropdownMenuItem(
                value: e.split(' (')[0],
                child: Text(e, style: TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedAccount = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 12),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentContacts.length,
            itemBuilder: (context, index) {
              final contact = _recentContacts[index];
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => _accountController.text = contact['account'],
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Text(contact['name'][0], style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 8),
                          Text(contact['name'].split(' ')[0], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(contact['account'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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
    );
  }

  Widget _buildTransferFormSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 20),
            TextFormField(
              controller: _accountController,
              decoration: InputDecoration(
                labelText: 'To Account Number',
                prefixIcon: Icon(Icons.account_balance, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              validator: (v) => v?.isEmpty == true ? 'Account number is required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.currency_rupee, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo, width: 2),
                ),
                suffixText: 'INR',
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
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.note_alt, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              maxLines: 2,
              maxLength: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processTransfer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        child: _isProcessing
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('PROCESSING...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.white),
            SizedBox(width: 8),
            Text('TRANSFER NOW', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _processTransfer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      await Future.delayed(Duration(seconds: 2));

      setState(() => _isProcessing = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Transfer Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ₹${_amountController.text}'),
              Text('To: ${_accountController.text}'),
              Text('Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('DONE', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }
}