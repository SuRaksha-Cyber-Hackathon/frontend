import 'package:flutter/material.dart';
import '../stats_collectors/keypress_collector.dart';

class LiveKeypressStatusPage extends StatelessWidget {
  const LiveKeypressStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keypress Auth Status")),
      body: AnimatedBuilder(
        animation: LiveKeypressNotifier(),
        builder: (context, _) {
          final live = LiveKeypressNotifier();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoTile("User ID", live.userId),
                _infoTile("Enrolled", live.isEnrolled.toString()),
                _infoTile("Enrollment Count", "${live.enrollmentCount}/${live.requiredEnrollments}"),
                _infoTile("Last Similarity", live.lastSimilarity.toStringAsFixed(3)),
                _infoTile("Last Verified", live.lastVerified == null ? "N/A" : live.lastVerified! ? "✅ Verified" : "❌ Rejected"),
                const SizedBox(height: 16),
                const Text("Event Log", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: ListView.builder(
                      itemCount: live.log.length,
                      itemBuilder: (context, index) {
                        final msg = live.log[index];
                        final color = msg.contains("❌") ? Colors.redAccent : Colors.greenAccent;
                        return Text(msg, style: TextStyle(color: color, fontFamily: 'Courier', fontSize: 13));
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
