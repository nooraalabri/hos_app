class DoctorModel {
  final String uid;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final String licenseNumber;
  final List<String> hospitalIds;
  final String? about;
  final double consultationFee;
  final double rating;
  final int totalReviews;
  final List<String> availableDays; // e.g., ['Monday', 'Tuesday', 'Wednesday']
  final String? clinicAddress;

  DoctorModel({
    required this.uid,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.licenseNumber,
    required this.hospitalIds,
    this.about,
    required this.consultationFee,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.availableDays,
    this.clinicAddress,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map, String uid) {
    return DoctorModel(
      uid: uid,
      specialization: map['specialization'] ?? '',
      qualification: map['qualification'] ?? '',
      experienceYears: map['experienceYears'] ?? 0,
      licenseNumber: map['licenseNumber'] ?? '',
      hospitalIds: List<String>.from(map['hospitalIds'] ?? []),
      about: map['about'],
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      availableDays: List<String>.from(map['availableDays'] ?? []),
      clinicAddress: map['clinicAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'specialization': specialization,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'licenseNumber': licenseNumber,
      'hospitalIds': hospitalIds,
      'about': about,
      'consultationFee': consultationFee,
      'rating': rating,
      'totalReviews': totalReviews,
      'availableDays': availableDays,
      'clinicAddress': clinicAddress,
    };
  }

  DoctorModel copyWith({
    String? specialization,
    String? qualification,
    int? experienceYears,
    String? licenseNumber,
    List<String>? hospitalIds,
    String? about,
    double? consultationFee,
    double? rating,
    int? totalReviews,
    List<String>? availableDays,
    String? clinicAddress,
  }) {
    return DoctorModel(
      uid: uid,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      experienceYears: experienceYears ?? this.experienceYears,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospitalIds: hospitalIds ?? this.hospitalIds,
      about: about ?? this.about,
      consultationFee: consultationFee ?? this.consultationFee,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      availableDays: availableDays ?? this.availableDays,
      clinicAddress: clinicAddress ?? this.clinicAddress,
    );
  }
}

