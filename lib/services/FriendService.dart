import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/services/AuthService.dart';

class FriendService {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

  Future<void> addFriend(String friendId) async {
    final String userId = authService.getCurrentUserId();
    try {
      await fireStore
          .collection("Users")
          .doc(friendId)
          .collection("friendRequests")
          .doc(userId)
          .set({
        'requesterId': userId,
        'isAccepted': false,
      });
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    final String userId = authService.getCurrentUserId();
    try {
      await fireStore
          .collection("Users")
          .doc(userId)
          .collection("friendRequests")
          .doc(requesterId)
          .delete();

      await fireStore
          .collection("Users")
          .doc(userId)
          .collection("friends")
          .doc(requesterId)
          .set({
        'friendId': requesterId,
      });

      await fireStore
          .collection("Users")
          .doc(requesterId)
          .collection("friends")
          .doc(userId)
          .set({
        'friendId': userId,
      });
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> declineFriendRequest(String requesterId) async {
    final String userId = authService.getCurrentUserId();
    try {
      await fireStore
          .collection("Users")
          .doc(userId)
          .collection("friendRequests")
          .doc(requesterId)
          .delete();
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getFriendRequests(String userId) {
    return fireStore
        .collection("Users")
        .doc(userId)
        .collection("friendRequests")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final request = doc.data();
        request['id'] = doc.id;
        return request;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final friendsSnapshot = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("friends")
        .get();

    List<Map<String, dynamic>> friends = [];
    for (var doc in friendsSnapshot.docs) {
      final friendData = await getUserInfo(doc.id);
      if (friendData != null) {
        friendData['id'] = doc.id;
        friends.add(friendData);
      }
    }
    return friends;
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

  Future<void> cancelFriendRequest(String friendId) async {
    final String userId = authService.getCurrentUserId();
    try {
      await fireStore
          .collection("Users")
          .doc(friendId)
          .collection("friendRequests")
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error cancelling friend request: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    final String userId = authService.getCurrentUserId();
    try {
      await fireStore
          .collection("Users")
          .doc(userId)
          .collection("friends")
          .doc(friendId)
          .delete();
      await fireStore
          .collection("Users")
          .doc(friendId)
          .collection("friends")
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error removing friend: $e');
    }
  }

  Future<bool> checkIfFriends(String userId, String friendId) async {
    final friendDoc = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("friends")
        .doc(friendId)
        .get();
    return friendDoc.exists;
  }

  Future<bool> checkPendingRequest(String userId, String friendId) async {
    final requestDoc = await fireStore
        .collection("Users")
        .doc(friendId)
        .collection("friendRequests")
        .doc(userId)
        .get();
    return requestDoc.exists;
  }

  Future<bool> checkReceivedRequest(String userId, String requesterId) async {
    final requestDoc = await fireStore
        .collection("Users")
        .doc(userId)
        .collection("friendRequests")
        .doc(requesterId)
        .get();
    return requestDoc.exists;
  }
}
