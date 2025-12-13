class PatientModel {
  final String uid;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final List<String> allergies;
  final List<String> chronicDiseases;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? address;

  PatientModel({
    required this.uid,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodGroup,
    this.height,
    this.weight,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, String uid) {
    return PatientModel(
      uid: uid,
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicDiseases: List<String>.from(map['chronicDiseases'] ?? []),
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
    };
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  PatientModel copyWith({
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicDiseases,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
  }) {
    return PatientModel(
      uid: uid,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      address: address ?? this.address,
    );
  }
}

