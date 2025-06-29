import 'package:flutter/material.dart';

class SecurityStatusSection extends StatelessWidget {
  final int anomalyThreatLevel;

  const SecurityStatusSection({Key? key, required this.anomalyThreatLevel}) : super(key: key);

  Color _indicatorColor() =>
      anomalyThreatLevel < 30 ? Colors.green : anomalyThreatLevel < 60 ? Colors.orange : Colors.red;

  String _indicatorText() =>
      anomalyThreatLevel < 30 ? 'SECURE' : anomalyThreatLevel < 60 ? 'CAUTION' : 'THREAT';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: _indicatorColor(), size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Threat Level: ${_indicatorText()}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Anomaly Score: $anomalyThreatLevel/100',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: anomalyThreatLevel / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_indicatorColor()),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSecurityMetric('Last Login', '2 mins ago'),
                    _buildSecurityMetric('Device Trust', 'Verified'),
                    _buildSecurityMetric('2FA Status', 'Active'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
