enum TrafficLightColor { green, yellow, red }

class MeasurementResultModel {
  const MeasurementResultModel({
    required this.color,
    required this.message,
    required this.estimatedTimeToGreen,
  });

  final TrafficLightColor color;
  final String message;
  final Duration? estimatedTimeToGreen;

  factory MeasurementResultModel.fromJson(Map<String, dynamic> json) {
    final colorValue = json['color'] as int?;
    return MeasurementResultModel(
      color: _mapColor(colorValue),
      message: json['message'] as String? ?? '',
      estimatedTimeToGreen: _parseEstimatedTime(
        json['estimatedTimeToGreen'] as String?,
      ),
    );
  }

  static TrafficLightColor _mapColor(int? value) {
    switch (value) {
      case 0:
        return TrafficLightColor.green;
      case 1:
        return TrafficLightColor.yellow;
      case 2:
        return TrafficLightColor.red;
      default:
        return TrafficLightColor.green;
    }
  }

  static Duration? _parseEstimatedTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}

class MeasurementHistoryModel {
  const MeasurementHistoryModel({
    required this.id,
    required this.userId,
    required this.alcoholLevel,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String userId;
  final double alcoholLevel;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  factory MeasurementHistoryModel.fromJson(Map<String, dynamic> json) {
    return MeasurementHistoryModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      alcoholLevel: (json['alcoholLevel'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
