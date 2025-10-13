import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportPeriod { weekly, monthly, yearly }

class FS {
  static final _db = FirebaseFirestore.instance;

  // ===== Collections =====
  static CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get hospitals => _db.collection('hospitals');
  static CollectionReference<Map<String, dynamic>> get otps => _db.collection('otps');
  static CollectionReference<Map<String, dynamic>> get appointments => _db.collection('appointments');
  static CollectionReference<Map<String, dynamic>> get reviews => _db.collection('reviews');

  // ===== Users =====
  static Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== Hospitals =====
  static Future<void> createHospital({
    required String uid,
    required String name,
    required String email,
  }) async {
    // نخزن المستشفى بنفس uid مال الـ admin
    await hospitals.doc(uid).set({
      'name': name,
      'email': email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // تحديث بيانات المستخدم وربطه بالمستشفى
    await users.doc(uid).set({
      'role': 'hospitaladmin',
      'hospitalId': uid,
      'approved': false,
    }, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> listHospitals({bool onlyApproved = true}) async {
    Query<Map<String, dynamic>> q = hospitals;
    if (onlyApproved) {
      q = q.where('status', isEqualTo: 'approved');
    } else {
      q = q.orderBy('name');
    }

    final snap = await q.get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<Map<String, dynamic>?> hospitalForAdmin(String adminUid) async {
    final doc = await hospitals.doc(adminUid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<void> updateHospitalLocation(
      String hospitalId, {
        String? address,
        String? city,
        String? country,
      }) {
    final data = <String, dynamic>{
      if (address != null && address.isNotEmpty) 'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
      if (country != null && country.isNotEmpty) 'country': country,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return hospitals.doc(hospitalId).set(data, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingHospitalsStream() {
    return hospitals.where('status', isEqualTo: 'pending').snapshots();
  }

  static Future<void> decideHospital({
    required String hospitalId,
    required bool approve,
  }) async {
    final ref = hospitals.doc(hospitalId);
    final snap = await ref.get();
    if (!snap.exists) return;

    await ref.update({
      'status': approve ? 'approved' : 'rejected',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await users.doc(hospitalId).set({'approved': approve}, SetOptions(merge: true));
  }

  // ===== Doctors =====
  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorsStream(
      String hospitalId, {
        bool? approved,
      }) {
    Query<Map<String, dynamic>> q =
    users.where('role', isEqualTo: 'doctor').where('hospitalId', isEqualTo: hospitalId);
    if (approved != null) q = q.where('approved', isEqualTo: approved);
    return q.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingDoctorsStream(String hospitalId) =>
      doctorsStream(hospitalId, approved: false);

  static Future<void> decideDoctor({
    required String doctorUid,
    required bool approve,
  }) async {
    await users.doc(doctorUid).set({'approved': approve}, SetOptions(merge: true));
  }

  static Future<void> deleteDoctor(String doctorUid) async {
    await users.doc(doctorUid).delete();
  }

  // ===== OTP =====
  static Future<void> saveOtp(String email, String code, {Duration ttl = const Duration(minutes: 10)}) async {
    final expiresAt = Timestamp.fromDate(DateTime.now().add(ttl));
    await otps.doc(email).set({
      'code': code,
      'expiresAt': expiresAt,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> verifyOtp(String email, String code) async {
    final doc = await otps.doc(email).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final ts = data['expiresAt'];
    final expiresAt = ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString());

    final ok = data['code'] == code && (expiresAt?.isAfter(DateTime.now()) ?? false);
    if (ok) await otps.doc(email).delete();
    return ok;
  }

  // ===== Reports (Hospital Admin) =====
  static Future<Map<String, int>> statsForHospital(String hospitalId, String period) async {
    final now = DateTime.now();
    late DateTime from;
    switch (period) {
      case 'weekly':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        from = DateTime(now.year, now.month == 1 ? 12 : now.month - 1, now.day);
        break;
      default:
        from = DateTime(now.year - 1, now.month, now.day);
    }

    int newRegs = 0, appts = 0, visits = 0;

    try {
      final u = await users
          .where('role', isEqualTo: 'patient')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();
      newRegs = u.docs.length;
    } catch (_) {}

    try {
      final a = await appointments
          .where('hospitalId', isEqualTo: hospitalId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();
      appts = a.docs.length;
      visits = appts;
    } catch (_) {}

    return {'new': newRegs, 'appointments': appts, 'visits': visits};
  }

  // ===== Reports (Head Admin) =====
  static Future<Map<String, int>> statsForHeadAdmin({required ReportPeriod period}) async {
    final now = DateTime.now();
    late DateTime from;

    switch (period) {
      case ReportPeriod.weekly:
        from = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        from = DateTime(now.year, now.month == 1 ? 12 : now.month - 1, now.day);
        break;
      case ReportPeriod.yearly:
        from = DateTime(now.year - 1, now.month, now.day);
        break;
    }
    final to = now;

    Future<int> _count(Query q) async {
      final s = await q.get();
      return s.size;
    }

    final hospitalsApprovedF = _count(hospitals.where('status', isEqualTo: 'approved'));
    final hospitalsPendingF = _count(hospitals.where('status', isEqualTo: 'pending'));

    final doctorsApprovedF =
    _count(users.where('role', isEqualTo: 'doctor').where('approved', isEqualTo: true));
    final doctorsPendingF =
    _count(users.where('role', isEqualTo: 'doctor').where('approved', isEqualTo: false));

    final patientsTotalF = _count(users.where('role', isEqualTo: 'patient'));

    final newUsersF = _count(
      users.where('createdAt', isGreaterThanOrEqualTo: from).where('createdAt', isLessThan: to),
    );

    final newHospitalsF = _count(
      hospitals.where('createdAt', isGreaterThanOrEqualTo: from).where('createdAt', isLessThan: to),
    );

    final apptsF = _count(
      appointments.where('createdAt', isGreaterThanOrEqualTo: from).where('createdAt', isLessThan: to),
    );

    final r = await Future.wait<int>([
      hospitalsApprovedF,
      hospitalsPendingF,
      doctorsApprovedF,
      doctorsPendingF,
      patientsTotalF,
      newUsersF,
      newHospitalsF,
      apptsF,
    ]);

    return {
      'hospitalsApproved': r[0],
      'hospitalsPending': r[1],
      'doctorsApproved': r[2],
      'doctorsPending': r[3],
      'patientsTotal': r[4],
      'newUsers': r[5],
      'newHospitals': r[6],
      'appointments': r[7],
    };
  }

  // ===== Doctor Features =====

  /// مواعيد الدكتور لليوم
  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorAppointmentsToday(String doctorId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    return appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('time', isGreaterThanOrEqualTo: start)
        .where('time', isLessThan: end)
        .snapshots();
  }

  /// مواعيد الدكتور للأسبوع
  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorAppointmentsWeekly(String doctorId) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('time', isGreaterThanOrEqualTo: startOfWeek)
        .where('time', isLessThan: endOfWeek)
        .snapshots();
  }

  /// إضافة تقرير طبي
  static Future<void> addMedicalReport(String appointmentId, String report, String medicines) async {
    await appointments.doc(appointmentId).update({
      'report': report,
      'medicines': medicines,
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تقييمات المرضى للدكتور
  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorReviews(String doctorId) {
    return reviews.where('doctorId', isEqualTo: doctorId).snapshots();
  }
}
