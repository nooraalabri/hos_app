import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notify_service.dart';

enum ReportPeriod { weekly, monthly, yearly }

class FS {
  static final _db = FirebaseFirestore.instance;

  // ===== Collections =====
  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get hospitals =>
      _db.collection('hospitals');
  static CollectionReference<Map<String, dynamic>> get otps =>
      _db.collection('otps');
  static CollectionReference<Map<String, dynamic>> get appointments =>
      _db.collection('appointments');
  static CollectionReference<Map<String, dynamic>> get reviews =>
      _db.collection('reviews');
  static CollectionReference<Map<String, dynamic>> get reports =>
      _db.collection('reports');

  // ===== Helpers =====
  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _dayEnd(DateTime d) =>
      _dayStart(d).add(const Duration(days: 1));
  static DateTime _weekStart(DateTime d) =>
      _dayStart(d).subtract(Duration(days: d.weekday - 1));
  static DateTime _weekEnd(DateTime d) =>
      _weekStart(d).add(const Duration(days: 7));
  static Timestamp _ts(DateTime d) => Timestamp.fromDate(d);

  // ===== Users =====
  static Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).set(
      {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ======================== HOSPITALS ====================================

  static Future<void> createHospital({
    required String uid,
    required String name,
    required String email,
    Map<String, dynamic>? data,
  }) async {
    final hospitalData = {
      'name': name,
      'email': email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      ...?data,
    };

    await hospitals.doc(uid).set(hospitalData);

    await users.doc(uid).set(
      {
        'role': 'hospitaladmin',
        'hospitalId': uid,
        'approved': false,
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> updateHospitalLocation(
      String hospitalId, {
        String? address,
        double? lat,
        double? lng,
      }) {
    final data = <String, dynamic>{
      if (address != null && address.isNotEmpty) 'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return hospitals.doc(hospitalId).set(data, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> listHospitals(
      {bool onlyApproved = true}) async {
    Query<Map<String, dynamic>> q = hospitals;
    if (onlyApproved) {
      q = q.where('status', isEqualTo: 'approved');
    } else {
      q = q.orderBy('name');
    }
    final snap = await q.get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // 🔥 مهم: إصلاح جلب hospitalId للإدمن
  static Future<Map<String, dynamic>?> hospitalForAdmin(String adminUid) async {
    final userDoc = await users.doc(adminUid).get();
    if (!userDoc.exists) return null;

    final hid = userDoc.data()?['hospitalId'];
    if (hid == null || hid.toString().isEmpty) return null;

    final hospDoc = await hospitals.doc(hid).get();
    if (!hospDoc.exists) return null;

    return {
      'id': hospDoc.id,
      ...hospDoc.data()!,
    };
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

    final data = snap.data()!;
    final hospitalEmail = (data['email'] ?? '').toString();
    final hospitalName = (data['name'] ?? '').toString();

    await ref.update({
      'status': approve ? 'approved' : 'rejected',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await users.doc(hospitalId).set(
      {'approved': approve},
      SetOptions(merge: true),
    );

    if (hospitalEmail.isNotEmpty) {
      await NotifyService.notifyHospitalDecision(
        toEmail: hospitalEmail,
        hospitalName: hospitalName,
        approved: approve,
      );
    }
  }

  // ======================== DOCTORS ======================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorsStream(
      String hospitalId, {
        bool? approved,
      }) {
    Query<Map<String, dynamic>> q = users
        .where('role', isEqualTo: 'doctor')
        .where('hospitalId', isEqualTo: hospitalId);

    if (approved != null) {
      q = q.where('approved', isEqualTo: approved);
    }

    return q.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingDoctorsStream(
      String hospitalId) =>
      doctorsStream(hospitalId, approved: false);

  static Future<void> decideDoctor({
    required String doctorUid,
    required bool approve,
  }) async {
    final ref = users.doc(doctorUid);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final doctorEmail = (data['email'] ?? '').toString();
    final doctorName = (data['name'] ?? '').toString();
    final hospitalName = (data['hospitalName'] ?? '').toString();

    await ref.set({'approved': approve}, SetOptions(merge: true));

    if (doctorEmail.isNotEmpty) {
      await NotifyService.notifyDoctorDecision(
        toEmail: doctorEmail,
        doctorName: doctorName,
        hospitalName: hospitalName,
        approved: approve,
      );
    }
  }

  static Future<void> deleteDoctor(String doctorUid) async {
    await users.doc(doctorUid).delete();
  }

  // ============================ OTP ======================================

  static Future<void> saveOtp(
      String email,
      String code, {
        Duration ttl = const Duration(minutes: 10),
      }) async {
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

    final expiresAt = ts is Timestamp
        ? ts.toDate()
        : DateTime.tryParse(ts.toString());

    final ok = data['code'] == code &&
        (expiresAt?.isAfter(DateTime.now()) ?? false);

    if (ok) {
      await otps.doc(email).delete();
    }

    return ok;
  }

  // ======================= MEDICAL REPORTS ================================

  static Future<void> addMedicalReport(
      String appointmentId,
      String report,
      String medicines,
      ) async {
    final apptSnap = await appointments.doc(appointmentId).get();
    if (!apptSnap.exists) return;

    final appt = apptSnap.data()!;
    final patientId = (appt['patientId'] ?? '').toString();
    if (patientId.isEmpty) return;

    String doctorName =
    (appt['doctorName'] ?? appt['doctorId'] ?? '').toString();
    String hospitalName = (appt['hospitalName'] ?? '').toString();
    final hospitalId = (appt['hospitalId'] ?? '').toString();

    if (hospitalName.isEmpty && hospitalId.isNotEmpty) {
      final h = await hospitals.doc(hospitalId).get();
      if (h.exists) {
        hospitalName = (h.data()!['name'] ?? '').toString();
      }
    }

    final nowTs = FieldValue.serverTimestamp();
    final batch = _db.batch();

    final apptRef = appointments.doc(appointmentId);
    batch.update(apptRef, {
      'report': report,
      'medicines': medicines,
      'status': 'completed',
      'updatedAt': nowTs,
    });

    final patientApptRef =
    users.doc(patientId).collection('appointments').doc(appointmentId);

    batch.set(
      patientApptRef,
      {
        'report': report,
        'medicines': medicines,
        'status': 'completed',
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'updatedAt': nowTs,
      },
      SetOptions(merge: true),
    );

    final reportData = {
      'appointmentId': appointmentId,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'hospitalId': hospitalId,
      'diagnosis': report,
      'notes': medicines,
      'patientId': patientId,
      'createdAt': nowTs,
    };

    final patientReportRef =
    users.doc(patientId).collection('reports').doc();

    final globalReportRef = reports.doc();

    batch.set(patientReportRef, reportData);
    batch.set(globalReportRef, reportData);

    await batch.commit();
  }

  // ====================== HOSPITAL STATS (FIXED) =========================

  static Future<Map<String, int>> statsForHospital(
      String hospitalId,
      String periodKey,
      ) async {

    final now = DateTime.now();
    late DateTime start;

    switch (periodKey) {
      case 'weekly':
        start = _weekStart(now);
        break;
      case 'monthly':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'yearly':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = _weekStart(now);
    }

    // ===== 1) GET ALL DOCTORS IN THIS HOSPITAL =====
    final doctorSnap = await users
        .where('role', isEqualTo: 'doctor')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    final doctorIds = doctorSnap.docs.map((d) => d.id).toList();

    if (doctorIds.isEmpty) {
      return {'new': 0, 'appointments': 0, 'visits': 0};
    }

    // ===== 2) GET ALL APPOINTMENTS FOR THESE DOCTORS =====
    // NOTE: Firestore allows only 10 elements in whereIn
    List<QueryDocumentSnapshot<Map<String, dynamic>>> apps = [];

    const maxBatch = 10;
    for (int i = 0; i < doctorIds.length; i += maxBatch) {
      final batch = doctorIds.skip(i).take(maxBatch).toList();

      final snap = await appointments
          .where('doctorId', whereIn: batch)
          .get();

      apps.addAll(snap.docs);
    }

    // ===== 3) FILTER BY DATE =====
    final items = apps.where((d) {
      final ts = d['time'];
      if (ts is! Timestamp) return false;
      final date = ts.toDate();
      return date.isAfter(start);
    }).toList();

    // ===== 4) CALCULATIONS =====
    final int appointmentsCount = items.length;
    final int visitsCount =
        items.where((d) => d['status'] == 'completed').length;

    final int uniquePatients = items
        .map((d) => d['patientId'])
        .whereType<String>()
        .toSet()
        .length;

    return {
      'new': uniquePatients,
      'appointments': appointmentsCount,
      'visits': visitsCount,
    };
  }


  // ==================== HEAD ADMIN STATS ================================
  static Future<Map<String, int>> statsForHeadAdmin({
    required ReportPeriod period,
  }) async {
    final now = DateTime.now();
    late DateTime from;

    switch (period) {
      case ReportPeriod.weekly:
        from = now.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        from = DateTime(
          now.year,
          now.month == 1 ? 12 : now.month - 1,
          now.day,
        );
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

    final hospitalsApprovedF =
    _count(hospitals.where('status', isEqualTo: 'approved'));

    final hospitalsPendingF =
    _count(hospitals.where('status', isEqualTo: 'pending'));

    final doctorsApprovedF = _count(
      users
          .where('role', isEqualTo: 'doctor')
          .where('approved', isEqualTo: true),
    );

    final doctorsPendingF = _count(
      users
          .where('role', isEqualTo: 'doctor')
          .where('approved', isEqualTo: false),
    );

    final patientsTotalF =
    _count(users.where('role', isEqualTo: 'patient'));

    final newUsersF = _count(
      users
          .where('createdAt', isGreaterThanOrEqualTo: _ts(from))
          .where('createdAt', isLessThan: _ts(to)),
    );

    final newHospitalsF = _count(
      hospitals
          .where('createdAt', isGreaterThanOrEqualTo: _ts(from))
          .where('createdAt', isLessThan: _ts(to)),
    );

    final apptsF = _count(
      appointments
          .where('createdAt', isGreaterThanOrEqualTo: _ts(from))
          .where('createdAt', isLessThan: _ts(to)),
    );

    final hospitalsSnap =
    await hospitals.where('status', isEqualTo: 'approved').get();

    int totalLinkedPatients = 0;

    for (final h in hospitalsSnap.docs) {
      final id = h.id;

      final pats = await users
          .where('role', isEqualTo: 'patient')
          .where('hospitalId', isEqualTo: id)
          .get();

      totalLinkedPatients += pats.size;
    }

    final r = await Future.wait([
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
      'linkedPatients': totalLinkedPatients,
    };
  }

  // ======================== Reviews & Shifts ==============================

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorReviews(
      String doctorId) {
    return reviews.where('doctorId', isEqualTo: doctorId).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorShiftsDaily(
      String doctorId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collectionGroup('shifts')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTs', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTs', isLessThan: Timestamp.fromDate(end))
        .orderBy('dateTs')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorShiftsWeekly(
      String doctorId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));

    return _db
        .collectionGroup('shifts')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTs', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTs', isLessThan: Timestamp.fromDate(end))
        .orderBy('dateTs')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorShiftsMonthly(
      String doctorId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 30));

    return _db
        .collectionGroup('shifts')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTs', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTs', isLessThan: Timestamp.fromDate(end))
        .orderBy('dateTs')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> hospitalUpcomingShifts(
      String hospitalId) {
    final todayStart = _ts(_dayStart(DateTime.now()));

    return hospitals
        .doc(hospitalId)
        .collection('shifts')
        .where('dateTs', isGreaterThanOrEqualTo: todayStart)
        .orderBy('dateTs')
        .snapshots();
  }

  // ============================ PATIENTS ================================

  static Future<Map<String, dynamic>?> getPatientProfile(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<void> updateChronic(String uid, List<String> chronic) async {
    await users.doc(uid).set(
      {'chronic': chronic},
      SetOptions(merge: true),
    );
  }

  static Future<String> createAppointment(
      String uid,
      Map<String, dynamic> data,
      ) async {
    if (!data.containsKey('shiftId') ||
        data['shiftId'] == null ||
        data['shiftId'].toString().isEmpty) {
      throw Exception('Missing shiftId in appointment data');
    }

    final rootRef = await appointments.add({
      ...data,
      'patientId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await users.doc(uid).collection('appointments').doc(rootRef.id).set(
      {
        ...data,
        'appointmentId': rootRef.id,
        'patientId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    return rootRef.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> patientAppointments(
      String uid) {
    return users
        .doc(uid)
        .collection('appointments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> patientReports(
      String uid) {
    return users
        .doc(uid)
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> patientMedicines(
      String uid, {
        bool activeOnly = false,
      }) {
    Query<Map<String, dynamic>> q =
    users.doc(uid).collection('medicines');

    if (activeOnly) {
      q = q.where('active', isEqualTo: true);
    }

    return q.orderBy('createdAt', descending: true).snapshots();
  }

  // ============================ SEARCH ==================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> searchHospitals(
      String query) {
    return hospitals
        .where('status', isEqualTo: 'approved')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> searchDoctors(
      String query) {
    return users
        .where('role', isEqualTo: 'doctor')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots();
  }
}

// ===== Testing Accessors =====
extension FSTestAccess on FS {
  static DateTime dayStart(DateTime d) => FS._dayStart(d);
  static DateTime weekStart(DateTime d) => FS._weekStart(d);
  static Timestamp ts(DateTime d) => FS._ts(d);
}
