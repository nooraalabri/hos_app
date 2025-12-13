class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phoneNumber;
  final String? email;
  final String? website;
  final List<String> facilities;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phoneNumber,
    this.email,
    this.website,
    this.facilities = const [],
    this.latitude,
    this.longitude,
    this.isActive = true,
    required this.createdAt,
  });

  factory HospitalModel.fromMap(Map<String, dynamic> map, String id) {
    return HospitalModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      website: map['website'],
      facilities: List<String>.from(map['facilities'] ?? []),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'facilities': facilities,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get fullAddress => '$address, $city, $state $zipCode';
}

