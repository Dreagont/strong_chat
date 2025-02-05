import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/auth/AuthGate.dart';
import 'package:strong_chat/call/Videocall.dart';
import 'package:strong_chat/firebase_options.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final ValueNotifier<Map<String, dynamic>?> pendingCallPayload =
ValueNotifier(null);

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("1234567890background");
  debugPrint("Background message received. Room ID: ${message.data['roomId']}");
  if (message.notification != null) {
    debugPrint(
        "FCM already displaying the notification, skipping showNotification()");
    return;
  }
  LocalNotificationService().showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService().requestPermission();
  await LocalNotificationService().init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
    pendingCallPayload.addListener(() {
      final payload = pendingCallPayload.value;

      if (payload != null &&
          payload.containsKey('roomId') &&
          payload.containsKey('callerId') &&
          payload.containsKey('calleeId') &&
          payload.containsKey('isVoice')) {
        print("Pending Call Updated: $payload");
        String isVoicetemp = payload['isVoice'];
        bool isVoice = false ;
        if(isVoicetemp == 'true'){
          isVoice = true;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) {
                  return VideoCallPage(
                    number: 2,
                    notificationToken: '',
                    CaleeName: '',
                    CallerName: '',
                    roomId: payload['roomId'] ?? '',
                    callerId: payload['callerId'] ?? '',
                    calleeId: payload['calleeId'] ?? '',
                    isVoice: isVoice ,
                    hangupPerson: false,
                  );
                },
              ),
            ).then((_) {
              pendingCallPayload.value = null;  // 🔥 Set null AFTER navigation
            });
          } else {
            print("Navigator key is NULL, cannot push route");
          }
        });
      } else {
        print("Invalid payload received or missing required fields: $payload");
      }
    });


  }

  void notificationHandler() {
    FirebaseMessaging.onMessage.listen((event) async {
      if(kIsWeb){
        if (event.data.containsKey('roomId')) {
          String roomId = event.data['roomId'];
          String isVoicetemp = event.data['isVoice'];
          bool isVoice = false ;
          if(isVoicetemp == 'true'){
            isVoice = true;
          }
          print("roomID: $roomId");
          showDialog(
            context: navigatorKey.currentState!.context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(event.data['title'] ?? "New Call"),
                content: Text("You have an incoming call. Do you want to join?"),
                actions: [
                  TextButton(
                    onPressed: () async {
                      if (event.data.containsKey('roomId')) {
                        String roomId = event.data['roomId'];
                        FirebaseFirestore db = FirebaseFirestore.instance;
                        var roomRef = db.collection('rooms').doc(roomId);
                        await roomRef.update({'declined': true});
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text("Decline"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VideoCallPage(
                              number: 2,
                              notificationToken: '',
                              CaleeName:'',
                              CallerName: '',
                              roomId: roomId,
                              callerId: event.data['callerId'],
                              calleeId: event.data['calleeId'],
                              isVoice: isVoice,
                              hangupPerson: false,
                            )
                        ),
                      );
                    },
                    child: Text("Accept"),
                  ),
                ],
              );
            },
          );
        } else {
          debugPrint('No roomId found in the notification data');
        }
      }
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
            navigatorKey: navigatorKey,
            home: AuthGate(),
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                backgroundColor: Colors.blue,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(color: Colors.white),
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