import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class Constant {
  static const String BASE_URL =
      'https://fcm.googleapis.com/v1/projects/flutter-final-app-bcd9d/messages:send';
}

class NotificationService {
  /// Retrieve Firebase Access Token from Service Account
  Future<String> getAccessToken() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/flutter-final-app-bcd9d-firebase-adminsdk-2jdb9-a6a2150f43.json');
      final serviceAccount = json.decode(jsonString);
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      return (await authClient.credentials).accessToken.data;
    } catch (e) {
      debugPrint("Error getting access token: $e");
      rethrow;
    }
  }

  /// Send Push Notification
  Future<bool> pushNotification({
    required String title,
    required String body,
    required String token,
  }) async {
    try {
      String accessToken = await getAccessToken();
      Map<String, dynamic> payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      };
      String dataNotifications = jsonEncode(payload);
      var response = await http.post(
        Uri.parse(Constant.BASE_URL),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: dataNotifications,
      );

      debugPrint("FCM Response: ${response.body}");
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Push Notification Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error sending push notification: $e");
      return false;
    }
  }
}

class LocalNotificationService {
  final firebaseFirestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;

  /// Request Notification Permissions
  Future<void> requestPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Notification permission not granted");
    }
  }

  /// Upload FCM Token to Firestore
  Future<void> uploadFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await firebaseFirestore.collection('Users').doc(_currentUser!.uid).update({
          'notificationToken': token,
        });
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint("New FCM Token: $newToken");
        await firebaseFirestore.collection('Users').doc(_currentUser!.uid).update({
          'notificationToken': newToken,
        });
      });
    } catch (e) {
      debugPrint("Error uploading FCM token: $e");
    }
  }

  /// Clear FCM Token on Logout
  Future<void> logout() async {
    try {
      await firebaseFirestore.collection('Users').doc(_currentUser!.uid).update({
        'notificationToken': "",
      });
    } catch (e) {
      debugPrint("Error clearing FCM token: $e");
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialize Local Notifications
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Show Local Notification
  Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel Description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      notificationDetails,
    );
  }
}

/// Usage Example
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localNotificationService = LocalNotificationService();
  final notificationService = NotificationService();

  await localNotificationService.requestPermission();
  await localNotificationService.init();
  await localNotificationService.uploadFcmToken();

  runApp(MyApp(
    notificationService: notificationService,
    localNotificationService: localNotificationService,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final LocalNotificationService localNotificationService;

  const MyApp({
    required this.notificationService,
    required this.localNotificationService,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("FCM Notifications")),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // Example usage
              bool result = await notificationService.pushNotification(
                title: "Test Notification",
                body: "This is a test message",
                token: "<YOUR_DEVICE_TOKEN>",
              );
              debugPrint("Notification Sent: $result");
            },
            child: Text("Send Notification"),
          ),
        ),
      ),
    );
  }
}
