import 'package:flutter/foundation.dart';
import 'package:strong_chat/services/FriendService.dart';
import 'package:strong_chat/services/FireStoreService.dart';

class ProfileState extends ChangeNotifier {
  final FireStoreService fireStoreService;
  final FriendService friendService;

  ProfileState(this.fireStoreService, this.friendService);

  Map<String, dynamic>? userData;
  String relationshipStatus = 'add';

  Future<void> loadUserData(Map<String, dynamic> data) async {
    userData = data;
    await _checkFriendStatus();
    notifyListeners();
  }

  Future<void> _checkFriendStatus() async {
    if (userData == null) return;

    final String userId = fireStoreService.authService.getCurrentUserId();
    final friendId = userData!['id'];

    final bool isFriend = await friendService.checkIfFriends(userId, friendId);
    final bool hasPendingRequest = await friendService.checkPendingRequest(userId, friendId);
    final bool hasReceivedRequest = await friendService.checkReceivedRequest(userId, friendId);

    relationshipStatus = isFriend
        ? 'remove'
        : hasPendingRequest
        ? 'cancel'
        : hasReceivedRequest
        ? 'accept'
        : 'add';
    notifyListeners();
  }

  Future<void> handleFriendAction() async {
    if (userData == null) return;

    final friendId = userData!['id'];
    if (relationshipStatus == 'add') {
      await friendService.addFriend(friendId);
      relationshipStatus = 'cancel';
    } else if (relationshipStatus == 'cancel') {
      await friendService.cancelFriendRequest(friendId);
      relationshipStatus = 'add';
    } else if (relationshipStatus == 'remove') {
      await friendService.removeFriend(friendId);
    } else if (relationshipStatus == 'accept') {
      await friendService.acceptFriendRequest(friendId);
      relationshipStatus = 'remove';
    } else if (relationshipStatus == 'decline') {
      await friendService.declineFriendRequest(friendId);
      relationshipStatus = 'add';
    }
    notifyListeners();
  }
}
