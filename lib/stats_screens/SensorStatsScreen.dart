import 'package:flutter/material.dart';

import '../stats_collectors/sensor_collector.dart';

class LiveStatusPage extends StatelessWidget {
  const LiveStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Auth Dashboard')),
      body: AnimatedBuilder(
        animation: LiveDataNotifier(),
        builder: (context, _) {
          final live = LiveDataNotifier();
          final now = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _livePulse(now),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _infoTile("UUID", live.uuid ?? "Not set"),
                      _infoTile("Enrolled", live.isEnrolled.toString()),
                      _infoTile("Window Count", live.windowCount.toString()),
                      _infoTile("Start Time", live.startTime?.toLocal().toString() ?? "N/A"),
                      _infoTile("Initial Phase", live.isInInitialPhase ? "Yes" : "No"),
                      _infoTile("Last Score", live.lastScore.toStringAsFixed(3)),
                      _infoTile("Last Message", live.lastMessage),

                      // Expanded(
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       color: Colors.black,
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     padding: const EdgeInsets.all(8),
                      //     child: ListView.builder(
                      //       itemCount: live.log.length,
                      //       itemBuilder: (context, index) {
                      //         final message = live.log[index];
                      //         final color = message.contains('Anomaly')
                      //             ? Colors.redAccent
                      //             : Colors.greenAccent;
                      //         return Text(
                      //           message,
                      //           style: TextStyle(
                      //             fontFamily: 'Courier',
                      //             color: color,
                      //             fontSize: 13,
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _livePulse(DateTime now) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TweenAnimationBuilder(
          tween: Tween(begin: 1.0, end: 0.0),
          duration: Duration(seconds: 1),
          builder: (_, value, __) => Opacity(
            opacity: value,
            child: Icon(Icons.circle, color: Colors.green, size: 16),
          ),
          onEnd: () {},
        ),
        const SizedBox(width: 8),
        Text(
          'Live at ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
