import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class OtpVerificationWidget extends StatefulWidget {
  final String email;
  final Function(bool success) onVerificationComplete;

  const OtpVerificationWidget({
    super.key,
    required this.email,
    required this.onVerificationComplete,
  });

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  late List<TextEditingController> otpControllers;
  late List<FocusNode> focusNodes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(6, (_) => TextEditingController());
    focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
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

  Future<void> _verifyOtp(String otp) async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      print('##################### email is $email');
      print('#################### otp is $otp');
      final response = await Dio().post(
        "https://zhmx7x9x-5000.inc1.devtunnels.ms/verify-otp",
        data: {"email": email, "otp": int.tryParse(otp)},
      );

      print("The OTP VERIFICATION RESPONSE IS : $response.data");

      if (response.data['message'] == 'OTP verified successfully') {
        _showSnackBar("✅ OTP verified successfully", Colors.green);
        widget.onVerificationComplete(true);
        Navigator.pop(context); // Only allow closing here
      } else {
        _showSnackBar("❌ Incorrect OTP. Please try again.", Colors.red);
        widget.onVerificationComplete(false);
      }
    } catch (e) {
      _showSnackBar("❌ Error verifying OTP. Please try again.", Colors.red);
      widget.onVerificationComplete(false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    if (index == 5 && value.isNotEmpty) {
      final otp = otpControllers.map((c) => c.text).join();
      if (otp.length == 6) {
        _verifyOtp(otp);
      }
    }
  }

  void _onSubmit() {
    final otp = otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showSnackBar("Please enter a valid 6-digit OTP", Colors.red);
      return;
    }
    _verifyOtp(otp);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.indigo.shade300, width: 1),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, color: Colors.indigo.shade700, size: 40),
            const SizedBox(height: 12),
            Text(
              "OTP Verification Required",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "A server anomaly was detected.\nPlease login again and verify the OTP sent to:",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.indigo.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 18),

            // Single TextField for OTP input (you can parse it internally to split digits)
            TextField(
              controller: otpControllers[0],
              focusNode: focusNodes[0],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) => _onOtpChanged(value, 0),
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 5,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: "Enter 6-digit OTP",
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.indigo.shade300,
                    width: 1.3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.indigo, width: 1.8),
                ),
                filled: true,
                fillColor: Colors.indigo.shade50,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                "Verify OTP",
                style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Helper function to show OTP dialog
Future<bool> showOtpDialog(BuildContext context, String email) async {
  bool otpVerified = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => OtpVerificationWidget(
      email: email,
      onVerificationComplete: (success) {
        otpVerified = success;
      },
    ),
  );

  return otpVerified;
}
