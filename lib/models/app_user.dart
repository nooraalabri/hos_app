class AppUser {
  final String uid;
  final String email;
  final String role; // 'patient' | 'doctor' | 'hospitaladmin' | 'headadmin'
  final String? name;
  final String? hospitalId;
  final String? specialization;
  final bool approved;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.hospitalId,
    this.specialization,
    bool? approved,
  }) : approved = approved ?? (role == 'patient'); // افتراضي: المريض معتمد

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    final role = (m['role'] ?? 'patient').toString();
    final approved = (m['approved'] ?? (role == 'patient')) == true;
    return AppUser(
      uid: uid,
      email: (m['email'] ?? '').toString(),
      role: role,
      name: m['name']?.toString(),
      hospitalId: m['hospitalId']?.toString(),
      specialization: m['specialization']?.toString(),
      approved: approved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'hospitalId': hospitalId,
      'specialization': specialization,
      'approved': approved,
    };
  }
}
