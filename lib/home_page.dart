import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'models.dart'; // Import your models

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = '';
  String _password = '';

  final TextEditingController _homeTextController = TextEditingController();
  final FocusNode _homeTextFieldFocusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();

  final List<KeyPressEvent> _allKeyPressEvents = [];
  final List<SwipeEvent> _allSwipeEvents = [];
  final Map<LogicalKeyboardKey, DateTime> _keyDownTimes = {};
  LogicalKeyboardKey? _lastKeyLogicalKey;
  DateTime? _lastKeyReleaseTime;

  static const List<MapEntry<String, String>> _commonDigrams = [
    MapEntry('t', 'h'), MapEntry('h', 'e'), MapEntry('i', 'n'),
    MapEntry('e', 'r'), MapEntry('a', 'n'), MapEntry('r', 'e'),
    MapEntry('e', 'd'), MapEntry('o', 'n'), MapEntry('e', 's'),
    MapEntry('s', 't'), MapEntry('e', 'n'), MapEntry('a', 't'),
  ];

  DateTime? _panStartTime;
  Offset? _panStartOffset;
  Offset? _panCurrentOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _username = args['username'] as String;
          _password = args['password'] as String;
          _allKeyPressEvents.addAll(args['keyPressEvents'] as List<KeyPressEvent>);
          _allSwipeEvents.addAll(args['swipeEvents'] as List<SwipeEvent>);
        });
      }
      _keyboardListenerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _homeTextController.dispose();
    _homeTextFieldFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.logicalKey.debugName == null || event.logicalKey.keyLabel.isEmpty) {
      return;
    }

    final keyLabel = event.logicalKey.keyLabel.toLowerCase();
    final keyCode = event.logicalKey.keyId.toString();
    String? fieldName = _homeTextFieldFocusNode.hasFocus ? 'home_text_field' : null;

    if (event is RawKeyDownEvent) {
      _keyDownTimes[event.logicalKey] = DateTime.now();
    } else if (event is RawKeyUpEvent) {
      final downTime = _keyDownTimes[event.logicalKey];
      final upTime = DateTime.now();
      if (downTime != null) {
        final durationMs = upTime.difference(downTime).inMilliseconds;
        final individualEvent = KeyPressEvent(
          keyCode: keyCode,
          keyLabel: keyLabel,
          eventType: 'individual',
          durationMs: durationMs,
          timestamp: upTime,
          contextScreen: 'home',
          fieldName: fieldName,
        );
        setState(() {
          _allKeyPressEvents.insert(0, individualEvent);
          if (_allKeyPressEvents.length > 100) _allKeyPressEvents.removeLast();
        });

        if (_lastKeyLogicalKey != null && _lastKeyReleaseTime != null) {
          final lastLabel = _lastKeyLogicalKey!.keyLabel.toLowerCase();
          final digramDuration = upTime.difference(_lastKeyReleaseTime!).inMilliseconds;
          for (var digram in _commonDigrams) {
            if (lastLabel == digram.key && keyLabel == digram.value) {
              final digramEvent = KeyPressEvent(
                keyCode: '${_lastKeyLogicalKey!.keyId}-${event.logicalKey.keyId}',
                keyLabel: '$lastLabel$keyLabel',
                eventType: 'digram',
                durationMs: digramDuration,
                timestamp: upTime,
                digramKey1: lastLabel,
                digramKey2: keyLabel,
                contextScreen: 'home',
                fieldName: fieldName,
              );
              setState(() {
                _allKeyPressEvents.insert(0, digramEvent);
                if (_allKeyPressEvents.length > 100) _allKeyPressEvents.removeLast();
              });
              break;
            }
          }
        }
        _keyDownTimes.remove(event.logicalKey);
      }
      _lastKeyLogicalKey = event.logicalKey;
      _lastKeyReleaseTime = upTime;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _panStartTime = DateTime.now();
    _panStartOffset = details.globalPosition;
    _panCurrentOffset = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _panCurrentOffset = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panStartTime != null && _panStartOffset != null && _panCurrentOffset != null) {
      final endTime = DateTime.now();
      final durationMs = endTime.difference(_panStartTime!).inMilliseconds;
      final distance = (_panCurrentOffset! - _panStartOffset!).distance;
      final event = SwipeEvent(
        startX: _panStartOffset!.dx,
        startY: _panStartOffset!.dy,
        endX: _panCurrentOffset!.dx,
        endY: _panCurrentOffset!.dy,
        distance: distance,
        durationMs: durationMs,
        timestamp: endTime,
        contextScreen: 'home',
      );
      setState(() {
        _allSwipeEvents.insert(0, event);
        if (_allSwipeEvents.length > 50) _allSwipeEvents.removeLast();
      });
      _panStartTime = null;
      _panStartOffset = null;
      _panCurrentOffset = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.shade700,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _keyboardListenerFocusNode,
        onKey: _handleKeyEvent,
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Login Credentials (Captured):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        Text('Username: $_username', style: const TextStyle(fontSize: 16)),
                        Text('Password: $_password', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: _homeTextController,
                  focusNode: _homeTextFieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Type here to track more key presses...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  style: const TextStyle(fontSize: 18),
                  onTap: () => _keyboardListenerFocusNode.requestFocus(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildKeyPressList(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSwipeList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPressList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All Key Press Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        Expanded(
          child: _allKeyPressEvents.isEmpty
              ? const Center(child: Text('No key press data yet.'))
              : ListView.builder(
            itemCount: _allKeyPressEvents.length,
            itemBuilder: (context, i) {
              final e = _allKeyPressEvents[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                color: e.eventType == 'digram' ? Colors.lightGreen.shade50 : Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.eventType.capitalize()}: ${e.keyLabel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Duration: ${e.durationMs} ms'),
                      if (e.eventType == 'digram') Text('Pair: "${e.digramKey1}" + "${e.digramKey2}"'),
                      Text('Time: ${DateFormat('HH:mm:ss').format(e.timestamp)}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Swipe Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        Expanded(
          child: _allSwipeEvents.isEmpty
              ? const Center(child: Text('No swipe data yet.'))
              : ListView.builder(
            itemCount: _allSwipeEvents.length,
            itemBuilder: (context, i) {
              final s = _allSwipeEvents[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                color: Colors.cyan.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start: (${s.startX.toStringAsFixed(1)}, ${s.startY.toStringAsFixed(1)})'),
                      Text('End: (${s.endX.toStringAsFixed(1)}, ${s.endY.toStringAsFixed(1)})'),
                      Text('Distance: ${s.distance.toStringAsFixed(1)} px'),
                      Text('Duration: ${s.durationMs} ms'),
                      Text('Time: ${DateFormat('HH:mm:ss').format(s.timestamp)}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
