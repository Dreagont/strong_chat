import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/auth/AuthGate.dart';
import 'package:strong_chat/firebase_options.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService().requestPermission();
  await LocalNotificationService().init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
  final FireStoreService fireStoreService = FireStoreService();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    notificationHandler();
  }

  void notificationHandler() {
    FirebaseMessaging.onMessage.listen((event) async {
      LocalNotificationService().showNotification(event);
    });
    FirebaseMessaging.onBackgroundMessage((RemoteMessage event) async {
      LocalNotificationService().showNotification(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            home: AuthGate(),
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(
                    color: Colors.white
                ),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                backgroundColor: Colors.blue,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(
                    color: Colors.white
                ),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                backgroundColor: Colors.grey[850],
              ),
            ),
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}


