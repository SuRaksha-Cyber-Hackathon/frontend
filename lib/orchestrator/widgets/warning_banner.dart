import 'dart:async';
import 'package:flutter/material.dart';

class WarningBanner extends StatefulWidget {
  final String message;
  final Duration duration;

  const WarningBanner({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<WarningBanner> createState() => _WarningBannerState();
}

class _WarningBannerState extends State<WarningBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        Overlay.of(context)?.setState(() {}); // Refresh overlay if needed
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          top: _slideAnimation.value,
          left: 0,
          right: 0,
          child: Material(
            elevation: 6,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: 1.0 - _controller.value,
                  backgroundColor: Colors.indigo.shade50,
                  color: Colors.indigo,
                  minHeight: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
