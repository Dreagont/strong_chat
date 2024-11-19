import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/auth/AuthGate.dart';
import 'package:strong_chat/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: 'https://xbdjaqpderywkwryeraf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZGphcXBkZXJ5d2t3cnllcmFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIwMDEyNTcsImV4cCI6MjA0NzU3NzI1N30.qCmeLT6nwxXJUtVbvLo9OintSlt875cT8en7hNjI3Ao',
  );

  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  AwesomeNotifications().initialize(
    "resource://drawable/img", // Ensure this icon exists in res/drawable
    [
      NotificationChannel(
        channelKey: 'chat_notifications',
        channelName: 'Chat Notifications',
        channelDescription: 'Notification channel for chat messages',
        //defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  runApp(MyApp());
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AwesomeNotifications().createNotificationFromJsonData(message.data);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Debug Print to Ensure Message is Received
      print('Foreground message received: ${message.data}');
      AwesomeNotifications().createNotificationFromJsonData(message.data);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked! Data: ${message.data}');
      // Handle the message click here
    });

    // Handle initial message when app is opened
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Initial message received: ${message.data}');
        // Handle the initial message here
      }
    });

    // Set up Supabase subscription for new messages
    final client = Supabase.instance.client;

    // Subscribe to changes in the messages table
    client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> event) {
      for (var change in event) {
        if (change['type'] == 'INSERT') {
          final newMessage = change['new'];
          print('New message received: ${newMessage['message']} from ${newMessage['sender_name']}');
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              channelKey: 'chat_notifications',
              title: 'New message from ${newMessage['sender_name']}',
              body: newMessage['message'],
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}