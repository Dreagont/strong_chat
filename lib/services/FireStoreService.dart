import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../classes/MessageClass.dart';
import 'AuthService.dart';

class FireStoreService {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();
  final Set<String> activeListeners = {}; // Track active listeners

  // Send notification using Awesome Notifications
  void _sendNotification({required String title, required String body, required String senderName}) {
    print('Sending notification: $title - $body from $senderName');
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'chat_notifications',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        summary: 'From $senderName', // Adding sender's name in the summary
      ),
    );
  }

  // Listen for new messages in a chat room and trigger notifications
  void listenForNewMessages(String userId) {
    fireStore
        .collection('Users')
        .doc(userId)
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final friendId = doc['friendId'];
        _listenForMessages(userId, friendId);
      }
    });
  }

  void _listenForMessages(String userId, String friendId) {
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    // Check if we already have a listener for this chat box
    if (activeListeners.contains(chatBoxId)) {
      return;
    }

    activeListeners.add(chatBoxId); // Add to active listeners
    print('Setting up listener for chatBoxId: $chatBoxId');

    fireStore
        .collection("ChatRoom")
        .doc(chatBoxId)
        .collection("messages")
        .orderBy("timeStamp", descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final messageData = snapshot.docs.first.data();
        final senderId = messageData['senderId'];
        final message = messageData['message'];

        // Fetch sender's name
        final senderName = await getSenderName(senderId);
        print('New message from $senderName: $message');

        // Trigger notification only if the current user is NOT the sender
        if (senderId != userId) {
          _sendNotification(
            title: 'New message from $senderName',
            body: message,
            senderName: senderName, // Pass sender name to notification
          );
        }
      }
    });
  }

  // Helper method to get sender's name
  Future<String> getSenderName(String senderId) async {
    final userDoc = await fireStore.collection("Users").doc(senderId).get();
    if (userDoc.exists) {
      return userDoc['name'];
    }
    return 'Unknown';
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return fireStore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getChatsStream(String userId) {
    return fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chatsList = [];
      for (var doc in snapshot.docs) {
        final friendData = await getUserInfo(doc['friendId']);
        if (friendData != null) {
          chatsList.add(friendData);
        }
      }
      return chatsList;
    });
  }

  Future<void> sendMessage(
      String friendId, String messageText, String messType, String fileName) async {
    final String userId = authService.getCurrentUserId();
    final Timestamp timestamp = Timestamp.now();
    Message message = Message(
        senderId: userId,
        friendId: friendId,
        message: messageText,
        messType: messType,
        timestamp: timestamp,
        fileName: fileName
    );
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');
    final querySnapshot = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .get();
    if (querySnapshot.docs.isEmpty) {
      await fireStore.collection("Users").doc(userId).collection("chats").add({
        'friendId': friendId,
      });
    }

    final querySnapshot1 = await fireStore
        .collection("Users")
        .doc(friendId)
        .collection("chats")
        .where('friendId', isEqualTo: userId)
        .get();
    if (querySnapshot1.docs.isEmpty) {
      await fireStore.collection("Users").doc(friendId).collection("chats").add({
        'friendId': userId,
      });
    }

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