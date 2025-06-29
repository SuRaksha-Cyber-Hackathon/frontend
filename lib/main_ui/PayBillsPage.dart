// pay_bills_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PayBillsPage extends StatefulWidget {
  @override
  _PayBillsPageState createState() => _PayBillsPageState();
}

class _PayBillsPageState extends State<PayBillsPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedBillType = 'Electricity';
  String _selectedAccount = 'Savings Account - ****1234';
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, Map<String, dynamic>> _billTypes = {
    'Electricity': {'icon': Icons.electrical_services, 'color': Colors.amber, 'providers': ['MSEB', 'Tata Power', 'BEST']},
    'Water': {'icon': Icons.water_drop, 'color': Colors.blue, 'providers': ['Municipal Corporation', 'Water Board']},
    'Gas': {'icon': Icons.local_gas_station, 'color': Colors.orange, 'providers': ['Indane', 'Bharat Gas', 'HP Gas']},
    'Internet': {'icon': Icons.wifi, 'color': Colors.purple, 'providers': ['Airtel', 'Jio Fiber', 'BSNL']},
    'Mobile': {'icon': Icons.phone_android, 'color': Colors.green, 'providers': ['Airtel', 'Jio', 'Vi', 'BSNL']},
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text('Pay Bills', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBillTypeSelector(),
                SizedBox(height: 24),
                _buildPayFromAccount(),
                SizedBox(height: 24),
                _buildBillDetailsForm(),
                SizedBox(height: 32),
                _buildPayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Bill Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _billTypes.length,
            itemBuilder: (context, index) {
              final billType = _billTypes.keys.elementAt(index);
              final billData = _billTypes[billType]!;
              final isSelected = _selectedBillType == billType;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedBillType = billType);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: isSelected ? billData['color'] : Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            billData['icon'],
                            size: 32,
                            color: isSelected ? Colors.white : billData['color'],
                          ),
                          SizedBox(height: 8),
                          Text(
                            billType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey[800],
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
    );
  }

  Widget _buildPayFromAccount() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[800]!],
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
                Icon(Icons.account_balance, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('Pay From', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
              dropdownColor: Colors.green[800],
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

  Widget _buildBillDetailsForm() {
    final billData = _billTypes[_selectedBillType]!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(billData['icon'], color: billData['color'], size: 24),
                SizedBox(width: 12),
                Text('$_selectedBillType Bill Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            ),
            SizedBox(height: 20),

            // Service Provider Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Service Provider',
                prefixIcon: Icon(Icons.business, color: billData['color']),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: billData['color'], width: 2),
                ),
              ),
              items: (billData['providers'] as List<String>)
                  .map((provider) => DropdownMenuItem(value: provider, child: Text(provider)))
                  .toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _billNumberController,
              decoration: InputDecoration(
                labelText: '${_selectedBillType == 'Mobile' ? 'Mobile Number' : 'Consumer Number'}',
                prefixIcon: Icon(Icons.numbers, color: billData['color']),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: billData['color'], width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty == true ? 'This field is required' : null,
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.currency_rupee, color: billData['color']),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: billData['color'], width: 2),
                ),
                suffixText: 'INR',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v?.isEmpty == true) return 'Amount is required';
                final amount = double.tryParse(v!);
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
            ),

            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: billData['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: billData['color'].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: billData['color'], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your ${_selectedBillType.toLowerCase()} bill will be processed instantly.',
                      style: TextStyle(fontSize: 12, color: billData['color']),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    final billData = _billTypes[_selectedBillType]!;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processBillPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: billData['color'],
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
            Icon(Icons.payment, color: Colors.white),
            SizedBox(width: 8),
            Text('PAY BILL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _processBillPayment() async {
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
              Text('Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill Type: $_selectedBillType'),
              Text('Amount: ₹${_amountController.text}'),
              Text('Bill Number: ${_billNumberController.text}'),
              Text('Reference ID: REF${DateTime.now().millisecondsSinceEpoch}'),
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