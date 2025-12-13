// lib/services/email_api.dart
import 'package:flutter/foundation.dart';

class EmailApiConfig {
   static String get baseUrl {
      //  إذا كنتِ تشتغلين على Flutter Web (مثل Chrome)
      if (kIsWeb) {
         return 'http://localhost:3000';
      }

      //  إذا كنتِ تشتغلين على Android Emulator
      return 'http://192.168.31.56:3000';

      //  ولو بعدين تشتغلين من جوال حقيقي على نفس الواي فاي
      // بدّلي فوق هذا السطر بـ:
      // return 'http://192.168.1.7:3000';  // ← غيّري IP جهازك
   }
}
