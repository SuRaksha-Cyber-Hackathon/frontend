import '../../models/models.dart';

List<List<double>> extractSensorFeatureWindows({
  required List<SensorEvent> sensorEvents,
  required List<TapEvent> tapEvents,
  required List<SwipeEvent> swipeEvents,
  required List<KeyPressEvent> keyEvents,
  int winSize = 10,
  int stepSize = 5,
}) {
  final acc = sensorEvents.where((e) => e.type == 'accelerometer').toList();
  final gyro = sensorEvents.where((e) => e.type == 'gyroscope').toList();

  final paired = <MapEntry<DateTime, List<double>>>[];
  int j = 0;
  for (final a in acc) {
    while (j < gyro.length &&
        gyro[j].timestamp
            .isBefore(a.timestamp.subtract(const Duration(milliseconds: 500)))) {
      j++;
    }
    if (j >= gyro.length) break;

    final g = gyro[j];
    final delta = a.timestamp.difference(g.timestamp).inMilliseconds.abs();
    if (delta <= 500) {
      paired.add(
        MapEntry(
          a.timestamp,
          [a.x, a.y, a.z, g.x, g.y, g.z],
        ),
      );
    }
  }

  if (paired.length < winSize) return [];

  paired.sort((u, v) => u.key.compareTo(v.key));
  final times = paired.map((e) => e.key).toList();
  final feats = paired.map((e) => e.value).toList();

  final tapTs = tapEvents.map((e) => e.timestamp).toList();
  final swipeTs = swipeEvents.map((e) => e.timestamp).toList();
  // Only count "keydown" events as an actual key press
  final keyTs = keyEvents
      .where((e) => e.eventType.toLowerCase() == 'keydown')
      .map((e) => e.timestamp)
      .toList();

  final windows = <List<double>>[];
  for (int i = 0; i + winSize <= feats.length; i += stepSize) {
    final sliceFeats = feats.sublist(i, i + winSize);
    final windowTimes = times.sublist(i, i + winSize);
    final start = windowTimes.first;
    final end = windowTimes.last;

    final tapCount =
        tapTs.where((t) => !t.isBefore(start) && !t.isAfter(end)).length;
    final swipeCount =
        swipeTs.where((t) => !t.isBefore(start) && !t.isAfter(end)).length;
    final keyCount =
        keyTs.where((t) => !t.isBefore(start) && !t.isAfter(end)).length;

    final flat = <double>[];
    for (final feat in sliceFeats) {
      flat.addAll(feat);
    }
    flat.addAll([
      tapCount.toDouble(),
      swipeCount.toDouble(),
      keyCount.toDouble(),
    ]);

    windows.add(flat);
  }

  return windows;
}
