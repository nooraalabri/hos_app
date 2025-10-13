// lib/services/email_api.dart
// اختاري الـ baseUrl المناسب لبيئتك تحت

class EmailApiConfig {
   // للويب (Chrome):
   static String? baseUrl = 'http://localhost:3000';

// للـ Android Emulator (AVD):
// static String? baseUrl = 'http://10.0.2.2:3000';

// لجهاز أندرويد حقيقي على نفس الشبكة (بدّلي IP):
// static String? baseUrl = 'http://192.168.1.7:3000';
}
