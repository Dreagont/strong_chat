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
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart';

class Constant {
  static const String BASE_URL =
      'https://fcm.googleapis.com/v1/projects/flutter-final-app-bcd9d/messages:send';
}

class NotificationService {
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
      if(kIsWeb){
        document.title = title;
      }
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

  Future<void> requestPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Notification permission not granted");
    }
  }

  Future<void> uploadFcmToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: "BPYx6LRkuqxoL_kPj0-blZpIvRPP6zarU_j8nYfBoZawQPFAnqPgcpdquNiz0bXAugUHdqXYFiNSL2emEgr_xxw",
        );
        if (token != null) {
          debugPrint("Web FCM Token: $token");
          await firebaseFirestore.collection('Users').doc(_currentUser!.uid).update({
            'notificationToken': token,
          });
        }
      } else  {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          debugPrint("Android FCM Token: $token");
          await firebaseFirestore.collection('Users').doc(_currentUser!.uid).update({
            'notificationToken': token,
          });
        }
      }
    } catch (e) {
      debugPrint("Error uploading FCM token: $e");
    }
  }


  Future<void> logout() async {
    try {
      await firebaseFirestore.collection('users').doc(_currentUser!.uid).update({
        'notificationToken': "",
      });
      if (kIsWeb) {
        await FirebaseMessaging.instance.deleteToken(); // Remove the token from localStorage
        print("Web token cleared.");
      } else {
        await FirebaseMessaging.instance.deleteToken();
        print("Android token cleared.");
      }
      print("User logged out.");
    } catch (e) {
      debugPrint("Error clearing FCM token: $e");
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  showNotification(RemoteMessage message) async {
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
