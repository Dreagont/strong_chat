import 'package:cloud_firestore/cloud_firestore.dart';

import '../classes/MessageClass.dart';
import 'AuthService.dart';

class FireStoreService {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return fireStore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> sendMessage(
      String friendId, String messageText, String messType) async {
    final String userId = authService.getCurrentUserId();
    final Timestamp timestamp = Timestamp.now();

    Message message = Message(
        senderId: userId,
        friendId: friendId,
        message: messageText,
        messType: messType,
        timestamp: timestamp);
    List<String> ids = [userId, friendId];
    ids.sort();

    String chatBoxId = ids.join('_');

    await fireStore
        .collection("ChatRoom")
        .doc(chatBoxId)
        .collection("messages")
        .add(message.MessToMap());
  }

  Stream<Map<String, dynamic>?> getUserInfoStream(String userId) {
    return fireStore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<QuerySnapshot> getMessage(String userId, String friendId) {
    List<String> ids = [userId, friendId];
    ids.sort();

    String chatBoxId = ids.join('_');

    return fireStore
        .collection("ChatRoom")
        .doc(chatBoxId)
        .collection("messages")
        .orderBy("timeStamp", descending: false)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await fireStore.collection("Users").doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      } else {
        print('User does not exist.');
        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      await fireStore
          .collection("Users")
          .doc(userId)
          .update({'avatar': avatarUrl});
    } catch (e) {
      print('Error updating user avatar: $e');
    }
  }

  Future<void> updateUserName(String userId, String newName) async {
    try {
      await fireStore.collection("Users").doc(userId).update({'name': newName});
    } catch (e) {
      print('Error updating user name: $e');
    }
  }
}
