import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FriendService.dart';

import '../pages/contacts/UserProfilePage.dart';

class ChatMore extends StatefulWidget {
  final Map<String, dynamic> friendData;
  final List<Map<String, dynamic>> allMessages;
  final String nickname;

  const ChatMore({
    Key? key,
    required this.friendData,
    required this.allMessages,
    required this.nickname,
  }) : super(key: key);

  @override
  _ChatMoreState createState() => _ChatMoreState();
}

class _ChatMoreState extends State<ChatMore> {
  bool isFriend = false;
  bool hasSentRequest = false;
  bool hasReceivedRequest = false;

  @override
  void initState() {
    super.initState();
    _initializeRelationshipStatus();
  }

  Future<void> _initializeRelationshipStatus() async {
    final userId = AuthService().getCurrentUserId();
    final friendId = widget.friendData['id'];

    final friendStatus = await Future.wait([
      FriendService().checkIfFriends(userId, friendId),
      FriendService().checkPendingRequest(userId, friendId),
      FriendService().checkReceivedRequest(userId, friendId),
    ]);

    setState(() {
      isFriend = friendStatus[0];
      hasSentRequest = friendStatus[1];
      hasReceivedRequest = friendStatus[2];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('More Options'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.friendData['avatar']),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                widget.nickname,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.person, color: Colors.white),
                    label: Text('Go to Profile',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userData: widget.friendData,
                            relationshipStatus: isFriend
                                ? 'remove'
                                : hasSentRequest
                                    ? 'cancel'
                                    : hasReceivedRequest
                                        ? 'accept'
                                        : 'add',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.call, color: Colors.white),
                    label: Text('Voice Call',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.videocam, color: Colors.white),
                    label: Text('Video Call',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text('Change Nickname',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.search, color: Colors.white),
                    label: Text('Find Message',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text('Delete Chat',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.block, color: Colors.white),
                    label: Text('Block User',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add your functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
