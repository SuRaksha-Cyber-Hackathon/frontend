import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/simple_ui_controller.dart';
import '../helpers/data_capture.dart';
import '../helpers/data_sender.dart';
import '../helpers/data_store.dart';
import '../login_screens/LoginPage.dart';

class ProfileSidebar extends StatelessWidget {
  const ProfileSidebar({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');
    await prefs.remove('remembered_email');
    await prefs.remove('remember_me');

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode _keyboardFocus = FocusNode();
    final user = FirebaseAuth.instance.currentUser;

    return RawKeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKey: (event) => DataCapture.handleKeyEvent(
        event,
        'profile',  // changed from 'dashboard' to 'profile'
            (kp) => CaptureStore().addKey(kp),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) => DataCapture.onSwipeStart(details),
        onPanUpdate: (details) => DataCapture.onSwipeUpdate(details),
        onPanEnd: (details) => DataCapture.onSwipeEnd(
          details,
          'profile',  // changed from 'dashboard' to 'profile'
              (sw) => CaptureStore().addSwipe(sw),
        ),
        onTapDown: (details) => DataCapture.onTapDown(details),
        onTapUp: (details) => DataCapture.onTapUp(
          details,
          'profile',  // changed from 'dashboard' to 'profile'
              (tp) => CaptureStore().addTap(tp),
        ),
        child: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile row: Icon + username & email stacked vertically
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Larger circular icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.indigo.shade700,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Username and email stacked vertically
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: GoogleFonts.ubuntu(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user?.email ?? '',
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              DataSenderService().uuid ?? 'UUID not available',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Menu options - flat list, no boxes
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: "Account Information",
                    onTap: () {
                      // Add navigation or functionality here
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    onTap: () {},
                  ),

                  const Spacer(),

                  // Logout button - simple flat with indigo text and border
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.indigo.shade400, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _logout(context),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.indigo.shade700, size: 28),
          title: Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              size: 18, color: Colors.indigo.shade400),
          onTap: onTap,
          horizontalTitleGap: 0,
        ),
        Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }
}
