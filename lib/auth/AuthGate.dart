import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/auth/LoginPage.dart';
import 'package:strong_chat/pages/HomePage.dart';

import '../services/notification_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> exemptEmails = [
      'huynhannguyen222@gmail.com',
      'huong@gmail.com',
      'mvm@gmail.com'
    ];

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            String userEmail = snapshot.data!.email ?? '';

            if (snapshot.data!.emailVerified || exemptEmails.contains(userEmail)) {
              LocalNotificationService().uploadFcmToken('in authgate');
              return HomeScreen(id: snapshot.data!.uid);
            } else {
              FirebaseAuth.instance.signOut();
              return LoginPage();
            }
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
