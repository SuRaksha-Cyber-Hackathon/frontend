class KeyPressEvent {
  final int? id;
  final String keyCode;
  final String keyLabel;
  final String eventType;
  final int durationMs;
  final DateTime timestamp;
  final String? digramKey1;
  final String? digramKey2;
  final String contextScreen;
  final String? fieldName;

  KeyPressEvent({
    this.id,
    required this.keyCode,
    required this.keyLabel,
    required this.eventType,
    required this.durationMs,
    required this.timestamp,
    this.digramKey1,
    this.digramKey2,
    required this.contextScreen,
    this.fieldName,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'key_code': keyCode,
    'key_label': keyLabel,
    'event_type': eventType,
    'duration_ms': durationMs,
    'timestamp': timestamp.toIso8601String(),
    'digram_key1': digramKey1,
    'digram_key2': digramKey2,
    'context_screen': contextScreen,
    'field_name': fieldName,
  };

  static KeyPressEvent fromMap(Map<String, dynamic> m) => KeyPressEvent(
    id: m['id'] as int?,
    keyCode: m['key_code'] as String,
    keyLabel: m['key_label'] as String,
    eventType: m['event_type'] as String,
    durationMs: m['duration_ms'] as int,
    timestamp: DateTime.parse(m['timestamp'] as String),
    digramKey1: m['digram_key1'] as String?,
    digramKey2: m['digram_key2'] as String?,
    contextScreen: m['context_screen'] as String,
    fieldName: m['field_name'] as String?,
  );
}

class SwipeEvent {
  final int? id;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double distance;
  final int durationMs;
  final DateTime timestamp;
  final String contextScreen;
  final String direction;

  SwipeEvent({
    this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.distance,
    required this.durationMs,
    required this.timestamp,
    required this.contextScreen,
    required this.direction,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_x': startX,
    'start_y': startY,
    'end_x': endX,
    'end_y': endY,
    'distance': distance,
    'duration_ms': durationMs,
    'timestamp': timestamp.toIso8601String(),
    'context_screen': contextScreen,
    'direction': direction,
  };

  static SwipeEvent fromMap(Map<String, dynamic> m) => SwipeEvent(
    id: m['id'] as int?,
    startX: (m['start_x'] as num).toDouble(),
    startY: (m['start_y'] as num).toDouble(),
    endX: (m['end_x'] as num).toDouble(),
    endY: (m['end_y'] as num).toDouble(),
    distance: (m['distance'] as num).toDouble(),
    durationMs: m['duration_ms'] as int,
    timestamp: DateTime.parse(m['timestamp'] as String),
    contextScreen: m['context_screen'] as String,
    direction: m['direction'] as String,
  );
}

class ScrollEvent {
  final double startOffset;
  final double endOffset;
  final double distance;
  final int durationMs;
  final DateTime timestamp;
  final String contextScreen;
  final String direction;

  ScrollEvent({
    required this.startOffset,
    required this.endOffset,
    required this.distance,
    required this.durationMs,
    required this.timestamp,
    required this.contextScreen,
    required this.direction,
  });

  factory ScrollEvent.fromMap(Map<String, dynamic> map) {
    return ScrollEvent(
      startOffset: map['startOffset']?.toDouble() ?? 0.0,
      endOffset: map['endOffset']?.toDouble() ?? 0.0,
      distance: map['distance']?.toDouble() ?? 0.0,
      durationMs: map['durationMs'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      contextScreen: map['contextScreen'] ?? '',
      direction: map['direction'] ?? '',
    );
  }


  Map<String, dynamic> toMap() => {
    'startOffset': startOffset,
    'endOffset': endOffset,
    'distance': distance,
    'durationMs': durationMs,
    'timestamp': timestamp.toIso8601String(),
    'contextScreen': contextScreen,
    'direction': direction,
  };
}

class TapEvent {
  final int? id;
  final double x;
  final double y;
  final int durationMs;
  final DateTime timestamp;
  final String contextScreen;

  TapEvent({
    this.id,
    required this.x,
    required this.y,
    required this.durationMs,
    required this.timestamp,
    required this.contextScreen,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'x': x,
    'y': y,
    'duration_ms': durationMs,
    'timestamp': timestamp.toIso8601String(),
    'context_screen': contextScreen,
  };

  static TapEvent fromMap(Map<String, dynamic> m) => TapEvent(
    id: m['id'] as int?,
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    durationMs: m['duration_ms'] as int,
    timestamp: DateTime.parse(m['timestamp'] as String),
    contextScreen: m['context_screen'] as String,
  );
}

class SensorEvent {
  final int? id;
  final String type; // 'accelerometer' or 'gyroscope'
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final String contextScreen;

  SensorEvent({
    this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
    required this.contextScreen,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'z': z,
    'timestamp': timestamp.toIso8601String(),
    'context_screen': contextScreen,
  };

  static SensorEvent fromMap(Map<String, dynamic> m) => SensorEvent(
    id: m['id'] as int?,
    type: m['type'] as String,
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    z: (m['z'] as num).toDouble(),
    timestamp: DateTime.parse(m['timestamp'] as String),
    contextScreen: m['context_screen'] as String,
  );
}
