import 'package:capstone/features/auth/components/ban_check.dart';
import 'package:capstone/features/start/screens/start_page.dart';
import 'package:capstone/features/notifications/screens/notification_settings.dart';
import 'package:capstone/features/notifications/screens/notifications.dart';
import 'package:capstone/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseStorage.instance;

  SystemChannels.platform.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'logError') {
      debugPrint('Platform error: ${call.arguments}');
    }
    return null;
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BanCheck(
        child: StartPage(),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF180B2D),
        primaryColor: const Color(0xFF7000FF),
      ),
      routes: {
        '/notifications': (context) => NotificationsPage(),
        '/notification-settings': (context) => NotificationSettingsPage(),
      },
    );
  }
}
