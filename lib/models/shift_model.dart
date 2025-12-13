class ShiftModel {
  final String id;
  final String doctorId;
  final String hospitalId;
  final String dayOfWeek; // e.g., 'Monday', 'Tuesday'
  final String startTime; // e.g., '09:00'
  final String endTime; // e.g., '17:00'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShiftModel({
    required this.id,
    required this.doctorId,
    required this.hospitalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    return ShiftModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange => '$startTime - $endTime';
}

