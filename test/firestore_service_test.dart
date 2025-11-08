import 'package:flutter_test/flutter_test.dart';
import 'package:hos_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  //  الجزء الأول: اختبارات الدوال المساعدة
  group('FS helper functions', () {
    test('dayStart returns start of the day at midnight', () {
      final d = DateTime(2025, 11, 2, 15, 30, 45);
      final result = FSTestAccess.dayStart(d);
      expect(result, DateTime(2025, 11, 2, 0, 0, 0));
    });

    test('weekStart returns Monday of that week', () {
      final sunday = DateTime(2025, 11, 2); // Sunday
      final monday = FSTestAccess.weekStart(sunday);
      expect(monday.weekday, 1); // Monday
    });

    test('ts converts DateTime to Timestamp', () {
      final now = DateTime(2025, 11, 2, 10, 0);
      final ts = FSTestAccess.ts(now);
      expect(ts, isA<Timestamp>());
      expect(ts.toDate().year, 2025);
    });
  });

  //  الجزء الثاني: منطق OTP
  group('FS.verifyOtp logic (mocked)', () {
    test('returns false if OTP expired', () async {
      final email = 'test@example.com';
      final code = '1234';

      final expiresAt = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1)));

      bool verifyOtpMock(String email, String code, Map<String, dynamic> data) {
        final ts = data['expiresAt'];
        final expiresAt = ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString());
        final ok = data['code'] == code && (expiresAt?.isAfter(DateTime.now()) ?? false);
        return ok;
      }

      final fakeData = {'code': '1234', 'expiresAt': expiresAt};
      final result = verifyOtpMock(email, code, fakeData);
      expect(result, false);
    });

    test('returns true if OTP valid and not expired', () async {
      final email = 'test@example.com';
      final code = '9999';

      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5)));

      bool verifyOtpMock(String email, String code, Map<String, dynamic> data) {
        final ts = data['expiresAt'];
        final expiresAt = ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString());
        final ok = data['code'] == code && (expiresAt?.isAfter(DateTime.now()) ?? false);
        return ok;
      }

      final fakeData = {'code': '9999', 'expiresAt': expiresAt};
      final result = verifyOtpMock(email, code, fakeData);
      expect(result, true);
    });
  });

  //  الجزء الثالث: اختبار منطق الإضافة والحذف (محاكاة)
  group('Mocked Add/Delete functions', () {
    test('addHospitalMock adds new hospital data to list', () {
      // قائمة تمثل قاعدة بيانات صغيرة مؤقتة
      final hospitals = <Map<String, dynamic>>[];

      void addHospitalMock(String id, String name, String email) {
        hospitals.add({'id': id, 'name': name, 'email': email, 'status': 'pending'});
      }

      // نضيف مستشفى
      addHospitalMock('h1', 'Mock Hospital', 'mock@hos.com');

      // التحقق
      expect(hospitals.length, 1);
      expect(hospitals.first['status'], 'pending');
      expect(hospitals.first['name'], contains('Mock'));
    });

    test('deleteDoctorMock removes doctor from list', () {
      // قائمة تمثل المستخدمين
      final users = [
        {'id': 'd1', 'role': 'doctor'},
        {'id': 'p1', 'role': 'patient'},
      ];

      void deleteDoctorMock(String doctorId) {
        users.removeWhere((u) => u['id'] == doctorId);
      }

      // نحذف الدكتور
      deleteDoctorMock('d1');

      // التحقق
      expect(users.length, 1);
      expect(users.any((u) => u['id'] == 'd1'), false);
    });
  });
}
