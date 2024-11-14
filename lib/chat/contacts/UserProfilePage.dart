import 'package:flutter/material.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../../services/FireStoreService.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FireStoreService fireStoreService = FireStoreService();
  final FriendService friendService = FriendService();
  String relationshipStatus = 'add';

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
  }

  void _checkFriendStatus() async {
    final String userId = fireStoreService.authService.getCurrentUserId();
    final friendId = widget.userData['id'];

    final bool isFriend = await friendService.checkIfFriends(userId, friendId);
    final bool hasPendingRequest = await friendService.checkPendingRequest(userId, friendId);
    final bool hasReceivedRequest = await friendService.checkReceivedRequest(userId, friendId);

    setState(() {
      if (isFriend) {
        relationshipStatus = 'remove';
      } else if (hasPendingRequest) {
        relationshipStatus = 'cancel';
      } else if (hasReceivedRequest) {
        relationshipStatus = 'accept';
      } else {
        relationshipStatus = 'add';
      }
    });
  }

  void handleFriendAction(BuildContext context) async {
    final friendId = widget.userData['id'];
    if (relationshipStatus == 'add') {
      await friendService.addFriend(friendId);
      setState(() {
        relationshipStatus = 'cancel';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent')),
      );
    } else if (relationshipStatus == 'cancel') {
      await friendService.cancelFriendRequest(friendId);
      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request cancelled')),
      );
    } else if (relationshipStatus == 'remove') {
      await friendService.removeFriend(friendId);
      Navigator.pop(context, true);
    } else if (relationshipStatus == 'accept') {
      await friendService.acceptFriendRequest(friendId);
      Navigator.pop(context, true);
      setState(() {
        relationshipStatus = 'remove';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted')),
      );
    } else if (relationshipStatus == 'decline') {
      await friendService.declineFriendRequest(friendId);
      Navigator.pop(context, true);
      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request declined')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userData["name"])),
      body: Column(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.userData["avatar"] ?? ''),
                    child: widget.userData["avatar"] == null ? Icon(Icons.person, size: 50) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userData["name"],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Add chat logic here
                        },
                        child: Text("Chat"),
                      ),
                      ElevatedButton(
                        onPressed: () => handleFriendAction(context),
                        child: Text(
                          relationshipStatus == 'add'
                              ? 'Add Friend'
                              : relationshipStatus == 'cancel'
                              ? 'Cancel Request'
                              : relationshipStatus == 'remove'
                              ? 'Remove Friend'
                              : relationshipStatus == 'accept'
                              ? 'Accept Request'
                              : 'Decline Request',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
