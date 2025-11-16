import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'routes.dart';
import 'providers/app_provider.dart';
import 'l10n/app_localizations.dart'; // ترجمة التطبيق

// 🔔 معالجة الإشعارات في الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background message: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase Init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



  // 🔔 FCM Permission & Token
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await messaging.getToken();
  print("FCM Token: $token");

  // 🚀 Run App
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: 'Hospital Appointment',
      debugShowCheckedModeBanner: false,

      // 🎨 الثيم
      theme: AppTheme.theme,
      darkTheme: ThemeData.dark(),
      themeMode: app.themeMode,

      // 🌐 اللغة الحالية
      locale: app.locale,

      // 🌐 دعم الترجمة
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // 🔄 تغيير الاتجاه تلقائيًا (عربي يمين – إنجليزي يسار)
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },

      // 🚦 المسارات
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.map,
    );
  }
}
