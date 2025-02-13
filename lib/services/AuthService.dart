import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final auth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPasswordVerify(
      String email, String password, String name, String work, String dob, String address, String phone) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await cred.user?.sendEmailVerification();

      await fireStore.collection("Users").doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'email': cred.user!.email,
        'name': name,
        'work': work,
        'dob': dob,
        'address': address,
        'phone': phone,
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/flutter-final-app-bcd9d.appspot.com/o/default_avatar.jpg?alt=media&token=974ef2cd-c48c-4a15-979e-8350a0c37168'
      });

      return cred.user;
    } catch (e) {
      log("Something went wrong: $e");
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password, String name, String work, String dob, String address, String phone) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await fireStore.collection("Users").doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'email': cred.user!.email,
        'name': name,
        'work': work,
        'dob': dob,
        'address': address,
        'phone': phone,
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/flutter-final-app-bcd9d.appspot.com/o/default_avatar.jpg?alt=media&token=974ef2cd-c48c-4a15-979e-8350a0c37168'
      });

      return cred.user;
    } catch (e) {
      log("Something went wrong: $e");
      return null;
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      List<String> exemptEmails = [
        'huynhannguyen222@gmail.com',
        'huong@gmail.com',
        'mvm@gmail.com'
      ];

      if (cred.user != null &&
          !cred.user!.emailVerified &&
          !exemptEmails.contains(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please verify your email before logging in', style: TextStyle(color: Colors.white),),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      return cred.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      log("Password reset email sent to $email");
    } catch (e) {
      log("Failed to send password reset email: $e");
    }
  }

  Future<void> signout() async {
    try {
      await auth.signOut();
    } catch (e) {
      log("Something went wrong");
    }
  }

  String getCurrentUserId() {
    final user = auth.currentUser;
    if (user != null) {
      return user.uid;
    }
    return '';
  }
}
