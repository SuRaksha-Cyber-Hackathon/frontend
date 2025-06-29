// lib/screens/tutorial_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../helpers/data_capture.dart';
import '../models/models.dart';
import 'LoginPage.dart';

class TutorialPage extends StatefulWidget {
  final String username;
  const TutorialPage({Key? key, required this.username}) : super(key: key);
  static const String id = '/TutorialPage';

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  // Prompts for the typing phase of the tutorial
  List<String> get typingPrompts => [
    'Please type: "Transfer ₹500 to ${widget.username}".',
    'Please type: "Show me my account balance".',
    'Please type: "Schedule a payment for rent tomorrow".',
  ];
  // Prompts for the swiping phase of the tutorial
  final List<String> swipePrompts = [
    'Swipe right to view your transactions.',
    'Swipe left to go back to home.',
    'Swipe right to open recent offers.',
  ];

  // 0 = typing, 1 = swiping, 2 = done
  int _phase = 0;
  // Current index for prompts within the current phase
  int _index = 0;
  // Stores the current input from the TextField
  String _currentInput = '';
  // FocusNode for the RawKeyboardListener to capture keyboard events
  final FocusNode _keyboardFocus = FocusNode();
  // Controller for the TextField to programmatically clear its content
  final TextEditingController _textEditingController = TextEditingController();


  // Lists to store captured key press and swipe events
  final List<KeyPressEvent> _keyEvents = [];
  final List<SwipeEvent> _swipeEvents = [];

  // For drawing the swipe path on the screen
  List<Offset> _swipePath = [];

  @override
  void initState() {
    super.initState();
    // Ensure keyboard focus is requested after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _textEditingController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Advances to the next prompt or phase
  void _next() {
    if (_phase == 0) { // Current phase is typing
      if (_index < typingPrompts.length - 1) {
        setState(() {
          _index++; // Move to the next typing prompt
          _currentInput = ''; // Clear current input for the new prompt
          _textEditingController.clear(); // Clear the TextField content
        });
      } else {
        setState(() {
          _phase = 1; // Transition to swiping phase
          _index = 0; // Reset index for swipe prompts
        });
      }
    } else if (_phase == 1) { // Current phase is swiping
      if (_index < swipePrompts.length - 1) {
        setState(() => _index++); // Move to the next swipe prompt
      } else {
        setState(() => _phase = 2); // Transition to done phase
        _onComplete(); // Call completion handler
      }
    }
  }

  // Handles tutorial completion and navigates to the login page
  void _onComplete() {
    // TODO: send _keyEvents & _swipeEvents to profiling service
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => LoginPage()), // Navigate to LoginView
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return RawKeyboardListener(
      focusNode: _keyboardFocus,
      onKey: (ev) {
        // Only capture key events during the typing phase
        if (_phase == 0) {
          DataCapture.handleKeyEvent(
            ev,
            'data_capture', // Event category
                (kp) => setState(() => _keyEvents.add(kp)), // Callback to add key event
            fieldName: 'typing', // Field name for data capture
          );
        }
      },
      child: GestureDetector(
        // Pan gesture for both DataCapture and drawing the swipe path
        onPanStart: (details) {
          if (_phase == 1) {
            DataCapture.onSwipeStart(
              DragStartDetails(globalPosition: details.globalPosition),
            );
            setState(() {
              _swipePath = [details.localPosition]; // Start drawing path from current position
            });
          }
        },
        onPanUpdate: (details) {
          if (_phase == 1) {
            setState(() {
              _swipePath.add(details.localPosition); // Add new point to the swipe path
            });
          }
        },
        onPanEnd: (details) {
          if (_phase == 1) {
            DataCapture.onSwipeEnd(
              details,
              'data_capture',
                  (sw) => setState(() => _swipeEvents.add(sw)), // Callback to add swipe event
            );
            // Clear path after a brief delay so user sees final stroke
            Future.delayed(Duration(milliseconds: 200), () {
              setState(() => _swipePath = []);
            });
          }
        },
        // Tap to unfocus keyboard, if it's open
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false, // Prevents keyboard from resizing the screen
          body: Stack(
            children: [
              // Background Lottie animation at the top right
              Align(
                alignment: Alignment.topRight,
                child: Lottie.asset(
                  'wave.json',
                  height: size.height * 0.2,
                  width: size.width,
                  fit: BoxFit.fill,
                ),
              ),
              // Main content column
              Padding(
                padding: EdgeInsets.only(
                  top: size.height * 0.2 + 48.0, // Adjust top padding to be below Lottie
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title for the tutorial page
                    Text(
                      'Setup Your Profile',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple, // Enhanced color
                      ),
                    ),
                    SizedBox(height: 24), // Increased spacing
                    // Card displaying the current prompt
                    Card(
                      elevation: 12, // Increased elevation for a more prominent look
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)), // Even more rounded corners
                      color: Colors.white, // Ensure explicit white background for the card
                      shadowColor: Colors.deepPurple.withOpacity(0.5), // More prominent shadow
                      child: Padding(
                        padding: const EdgeInsets.all(28.0), // Increased padding
                        child: Column( // Use a Column to center content better
                          children: [
                            Text(
                              'Your Task:', // Added a helper text
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _phase == 0
                                  ? typingPrompts[_index]
                                  : _phase == 1
                                  ? swipePrompts[_index]
                                  : 'All done! 🎉', // Added emoji for "All done!"
                              style: TextStyle(
                                fontSize: 22, // Slightly larger font
                                fontWeight: FontWeight.bold, // Bolder text
                                color: Colors.blueGrey[800], // Darker, more readable text color
                                letterSpacing: 0.5, // Slight letter spacing for better readability
                              ),
                              textAlign: TextAlign.center, // Centered text
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32), // Increased spacing

                    // Conditional rendering based on the current tutorial phase
                    if (_phase == 0) ...[
                      // Text field for typing phase
                      TextField(
                        controller: _textEditingController, // Assign the controller
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Type here…',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          fillColor: Colors.deepPurple.withOpacity(0.05), // Light fill color
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15), // More rounded corners
                            borderSide: BorderSide.none, // No default border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.deepPurple, width: 2), // Highlight on focus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3), width: 1),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        ),
                        onChanged: (s) => setState(() => _currentInput = s),
                      ),
                    ] else if (_phase == 1) ...[
                      // Swipe area for swiping phase
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.deepPurple.withOpacity(0.6), width: 2), // Stylish border
                          borderRadius: BorderRadius.circular(20), // More rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.1),
                              spreadRadius: 3,
                              blurRadius: 7,
                              offset: Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swipe, size: 50, color: Colors.deepPurple), // Swipe icon
                              SizedBox(height: 10),
                              Text(
                                'Perform a horizontal swipe here',
                                style: TextStyle(color: Colors.deepPurple.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '(Tap and drag your finger across)',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // "All done!" message
                      Center(
                        child: Text(
                            'You\'re all set! Ready to dive in? 🎉',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700])),
                      ),
                    ],

                    Spacer(), // Pushes content to the top and button to the bottom

                    // Next/Finish Button
                    if (_phase < 2)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient( // Gradient background for the button
                            colors: [Colors.deepPurple, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Make button background transparent
                            shadowColor: Colors.transparent, // Remove default shadow
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)), // Matched rounded corners
                          ),
                          onPressed:
                          (_phase == 0 && _currentInput.isEmpty) ? null : _next, // Disable if typing and input is empty
                          child: Text(
                            _phase == 0
                                ? 'Next'
                                : _phase == 1
                                ? 'Next Swipe'
                                : 'Back to Login Page',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Custom painter to draw the swipe path on top of everything
              if (_phase == 1 && _swipePath.isNotEmpty)
                IgnorePointer( // Ensures that the painter doesn't block gestures below it
                  child: CustomPaint(
                    size: Size.infinite, // Fills the entire available space
                    painter: _SwipePainter(_swipePath),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a smooth line through the list of points, representing a swipe path.
class _SwipePainter extends CustomPainter {
  final List<Offset> points;
  _SwipePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint properties for the swipe path
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8) // Distinct color for the path
      ..strokeWidth = 6 // Thicker line for better visibility
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round // Rounded caps for line ends
      ..strokeJoin = StrokeJoin.round; // Rounded joins for line segments

    // Only draw if there are at least two points to form a line
    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy); // Start path at the first point
      // Add lines to all subsequent points
      for (var pt in points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint); // Draw the path on the canvas
    }
  }

  @override
  // Repaint only if the list of points has changed
  bool shouldRepaint(covariant _SwipePainter old) =>
      old.points != points;
}
