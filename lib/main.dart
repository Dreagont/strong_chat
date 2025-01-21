import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/auth/AuthGate.dart';
import 'package:strong_chat/firebase_options.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/notification_service.dart';

import 'package:universal_html/html.dart';

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
    Future.microtask(() => notificationHandler(context));
  }


  void notificationHandler(BuildContext context) {
    FirebaseMessaging.onMessage.listen((event) async {
      print(event.notification!.title);
      LocalNotificationService().showNotification(context,event);
      if (kIsWeb) {
        final title = event.notification!.title!;
        document.title = "$title";
      }
    });
    if (kIsWeb) {
      String? originalTitle = document.title;
      document.addEventListener('visibilitychange', (event) {
        if (document.visibilityState == 'visible') {
          document.title = originalTitle;
        }
      });
    }
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


