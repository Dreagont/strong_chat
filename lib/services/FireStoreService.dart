import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../classes/MessageClass.dart';
import 'AuthService.dart';
import 'notification_service.dart';

class FireStoreService {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();
  final Set<String> activeListeners = {}; // Track active listeners


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

    if (activeListeners.contains(chatBoxId)) {
      return;
    }

    activeListeners.add(chatBoxId);

    fireStore
        .collection("ChatRoom")
        .doc(chatBoxId)
        .collection("messages")
        .orderBy("timeStamp", descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final messageData = snapshot.docs.first.data();
        final senderId = messageData['senderId'];
        final message = messageData['message'];
        final messageType = messageData['messType'];

        if (senderId != userId) {
          if (!(messageData['isNoti_isDeliver'])) {
            if(messageData['isChecked']){
              final senderName = await getSenderName(senderId);
              final userToken = await getUserToken(userId);

              final isNoti = await NotificationService().pushNotification(
                  title: "New Message From $senderName",
                  body: messageType == 'text' ? message : messageType == 'call' ? 'A Call' : 'Send a file',
                  token: userToken
              );
              if(isNoti){
                print("from listen");
                snapshot.docs.first.reference.update({'isNoti_isDeliver': true});
              }
            }
          }
        }
      }
    });
  }

  Future<String> getUserToken(String userID) async{
    final userDoc = await fireStore.collection("Users").doc(userID).get();
    if (userDoc.exists) {
      return userDoc['notificationToken'];
    }
    return 'Unknown';
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
        .orderBy('lastMessTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chatsList = [];
      for (var doc in snapshot.docs) {
        if (doc["isHide"] == false) {
          final friendData = await getUserInfo(doc['friendId']);
          if (friendData != null) {
            friendData['lastMessTime'] = doc['lastMessTime'];
            chatsList.add(friendData);
          }
        }
      }
      return chatsList;
    });
  }

  Future<void> sendMessage(String friendId, String messageText, String messType,
      String fileName) async {
    final String userId = authService.getCurrentUserId();
    final Timestamp timestamp = Timestamp.now();

    Message message = _createMessage(
        userId, friendId, messageText, messType, fileName, timestamp);

    String chatBoxId = _generateChatBoxId(userId, friendId);

    await _updateUserChatList(userId, friendId);
    await _updateUserChatList(friendId, userId);

    await _saveMessageToChatRoom(chatBoxId, message, friendId, userId);
  }

  Message _createMessage(String senderId, String friendId, String message,
      String messType, String fileName, Timestamp timestamp) {
    return Message(
      senderId: senderId,
      friendId: friendId,
      message: message,
      messType: messType,
      timestamp: timestamp,
      fileName: fileName,
    );
  }

  String _generateChatBoxId(String userId, String friendId) {
    List<String> ids = [userId, friendId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _updateUserChatList(String userId, String friendId) async {
    final String friendName = await fetchUserName(friendId);
    final Timestamp currentTimestamp = Timestamp.now();

    final querySnapshot = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      await fireStore.collection("Users").doc(userId).collection("chats").add({
        'friendId': friendId,
        'friendNickname': friendName,
        'defaultName': friendName,
        'isHide': false,
        'lastMessTime': currentTimestamp,
        'isBlocked': false
      });
    } else {
      await querySnapshot.docs.first.reference.update({
        'isHide': false,
        'lastMessTime': currentTimestamp,
      });
    }
  }

  Future<String> fetchUserName(String userId) async {
    final DocumentSnapshot userSnapshot =
    await fireStore.collection("Users").doc(userId).get();
    return userSnapshot.get('name') ?? 'User';
  }

  Future<String> fetchUserAvatar(String userId) async {
    final DocumentSnapshot userSnapshot =
    await fireStore.collection("Users").doc(userId).get();
    return userSnapshot.get('avatar') ?? 'User';
  }

  Future<void> _saveMessageToChatRoom(String chatBoxId, Message message, String friendId, String userId) async {
    DocumentReference? messageRef;
    try {
      messageRef = await fireStore
          .collection("ChatRoom")
          .doc(chatBoxId)
          .collection("messages")
          .add(message.MessToMap());

      bool isNoti = await isNotificationEnabled(userId, friendId);

      if (isNoti) {
        print('iinbro');
        try {
          final friendToken = await getUserToken(message.friendId);
          final senderName = await fetchUserName(message.senderId);
          final isNotificationSent = await NotificationService().pushNotification(
            title: 'New Message From $senderName',
            body: message.messType == 'text' ? message.message
                : message.messType == 'call' ? 'A Call' : 'Send a file',
            token: friendToken,
          );

          if (isNotificationSent) {
            await messageRef.update({'isNoti_isDeliver': true});
          }
        } catch (e) {
          debugPrint('Error sending notification: $e');
        }

        await messageRef.update({'isChecked': true});
      } else {
        print('out');
      }
    } catch (e) {
      debugPrint('Error saving message to Firestore: $e');
    }
  }

  Stream<bool> isNotificationEnabledStream(String userId, String friendId) {
    final docRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .doc(friendId);

    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (!data.containsKey('notificationEnabled')) {
          docRef.set({'notificationEnabled': false}, SetOptions(merge: true));
          return false;
        }
        return data['notificationEnabled'] ?? false;
      } else {
        docRef.set({'notificationEnabled': true}, SetOptions(merge: true));
        return true;
      }
    });
  }

  Future<bool> isNotificationEnabled(String userId, String friendId) async {
    final docRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(friendId)
        .collection("chats")
        .doc(userId);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      print('it exist');
      final data = snapshot.data() as Map<String, dynamic>;

      if (!data.containsKey('notificationEnabled')) {
        await docRef.set({'notificationEnabled': false}, SetOptions(merge: true));
        return false;
      } else {
        print('contain');
      }

      print('value: ${data['notificationEnabled']}');
      return data['notificationEnabled'];
    } else {
      await docRef.set({'notificationEnabled': true}, SetOptions(merge: true));
      return true;
    }
  }


  Stream<bool> getIsBlockedStream(String userId, String friendId) {
    return fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return data['isBlocked'] ?? false;
      } else {
        return false;
      }
    });
  }

  Stream<bool> isBlockedHimStream(String userId, String friendId) {
    return fireStore
        .collection("Users")
        .doc(friendId)
        .collection("chats")
        .where('friendId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return data['isBlocked'] ?? false;
      } else {
        return false;
      }
    });
  }

  Future<bool> isBlockedHim(String userId, String friendId) async {
    final snapshot = await fireStore
        .collection("Users")
        .doc(friendId)
        .collection("chats")
        .where('friendId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return data['isBlocked'] ?? false;
    } else {
      return false;
    }
  }

  Future<void> blockActionUserForFriend(String userId, String friendId) async {
    try {
      final chatDoc = await fireStore
          .collection("Users")
          .doc(friendId)
          .collection("chats")
          .where('friendId', isEqualTo: userId)
          .get()
          .then((snapshot) => snapshot.docs.first);

      await chatDoc.reference.update({
        'isBlocked': !(chatDoc.data() as Map<String, dynamic>?)?['isBlocked']
      });

    } catch (e) {
      print("Error blocking user for the friend: $e");
    }
  }

  Stream<Map<String, dynamic>?> getUserInfoStream(String userId) {
    return fireStore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }
  Stream<String?> getUserTokenStream(String userId) {
    return fireStore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['notificationToken'] as String?);
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

  Stream<String?> getNicknameStream(String userId, String friendId) {
    return fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['friendNickname'] as String?;
      }
      return null;
    });
  }

  Future<String?> getNickname(String userId, String friendId) async {
    try {
      final querySnapshot = await fireStore
          .collection("Users")
          .doc(userId)
          .collection("chats")
          .where('friendId', isEqualTo: friendId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['friendNickname'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting nickname: $e");
      return null;
    }
  }

  Future<void> editNicknameForFriend(
      String userId, String friendId, String newNickname) async {
    final querySnapshot = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference
          .update({'friendNickname': newNickname});
    }
  }

  Future<void> resetNicknameToDefault(String userId, String friendId) async {
    final querySnapshot = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .where('friendId', isEqualTo: friendId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docRef = querySnapshot.docs.first.reference;

      final docData = querySnapshot.docs.first.data();
      String? defaultName = docData['defaultName'] as String?;

      if (defaultName != null) {
        await docRef.update({'friendNickname': defaultName});
      }
    }
  }

  Future<void> hideChatForUser(String userId, String friendId) async {
    try {
      final querySnapshot = await fireStore
          .collection("Users")
          .doc(userId)
          .collection("chats")
          .where('friendId', isEqualTo: friendId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        await docRef.update({'isHide': true});
      } else {
        print("No document found to update");
      }
    } catch (e) {
      print("Error hiding chat: $e");
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

  Future<String> getLastMessageStatusString(String userId, String friendId) async {
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    try {
      QuerySnapshot messageSnapshot = await fireStore
          .collection("ChatRoom")
          .doc(chatBoxId)
          .collection("messages")
          .orderBy("timeStamp", descending: true)
          .limit(1)
          .get();

      if (messageSnapshot.docs.isNotEmpty) {
        final Map<String, dynamic>? messageData = messageSnapshot.docs.first.data() as Map<String, dynamic>?;

        if (messageData != null) {
          final isNoti = messageData['isNoti_isDeliver'] as bool? ?? false;
          final isRead = messageData['isRead'] as bool? ?? false;

          if (isRead) {
            return 'Seen';
          } else if (isNoti) {
            return 'Received';
          } else {
            return 'Delivered';
          }
        }
      }
      return 'No messages found.';
    } catch (e) {
      print('Error getting last message status: $e');
      return 'Error';
    }
  }

  Future<void> toggleMessageLike(String userId, String friendId, String messageId) async {
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    try {
      DocumentReference messageRef = fireStore
          .collection("ChatRoom")
          .doc(chatBoxId)
          .collection("messages")
          .doc(messageId);

      DocumentSnapshot messageDoc = await messageRef.get();
      Map<String, dynamic> messageData = messageDoc.data() as Map<String, dynamic>? ?? {};

      List<String> likes = List<String>.from(messageData['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await messageRef.set({
        ...messageData,
        'likes': likes
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error toggling message like: $e');
    }
  }

  Future<void> deleteMessage(String userId, String friendId, String messageId) async {
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    try {
      DocumentReference messageRef = fireStore
          .collection("ChatRoom")
          .doc(chatBoxId)
          .collection("messages")
          .doc(messageId);

      DocumentSnapshot messageDoc = await messageRef.get();
      Map<String, dynamic> messageData = messageDoc.data() as Map<String, dynamic>? ?? {};

      List<String> deletedBy = List<String>.from(messageData['deletedBy'] ?? []);

      if (!deletedBy.contains(userId)) {
        deletedBy.add(userId);
        await messageRef.set({
          ...messageData,
          'deletedBy': deletedBy
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Future<bool> undoSentMessage(String userId, String friendId, Timestamp timestamp) async {
    List<String> ids = [userId, friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    try {
      QuerySnapshot messagesSnapshot = await fireStore
          .collection("ChatRoom")
          .doc(chatBoxId)
          .collection("messages")
          .where('timeStamp', isEqualTo: timestamp)
          .where('senderId', isEqualTo: userId)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        DocumentReference messageRef = messagesSnapshot.docs.first.reference;

        await messageRef.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error undoing sent message: $e');
      return false;
    }
  }

  bool isMessageDeletedForUser(Map<String, dynamic> messageData, String userId) {
    List<String> deletedBy = List<String>.from(messageData['deletedBy'] ?? []);
    return deletedBy.contains(userId);
  }

  int getMessageLikesCount(Map<String, dynamic> messageData) {
    List<String> likes = List<String>.from(messageData['likes'] ?? []);
    return likes.length;
  }

  bool hasUserLikedMessage(Map<String, dynamic> messageData, String userId) {
    List<String> likes = List<String>.from(messageData['likes'] ?? []);
    return likes.contains(userId);
  }

  Future<void> updateUserInfo(String userId, Map<String, String> userInfo) async {
    await fireStore.collection('Users').doc(userId).update(userInfo);
  }


}
