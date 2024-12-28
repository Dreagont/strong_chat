import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FriendService.dart';

import '../pages/ChangeTheme.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);


    return Scaffold(
      appBar: AppBar(
        title: Text('More Options'),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? Colors.grey[850]
            : Colors.blue,
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
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            SizedBox(height: 30),
            Column(
              children: [
                _buildSection(
                  context: context,
                  title: 'Go to Profile',
                  icon: Icons.person,
                  onTap: () {
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
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Voice Call',
                  icon: Icons.call,
                  onTap: () {
                  },
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Video Call',
                  icon: Icons.videocam,
                  onTap: () {
                  },
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Change Nickname',
                  icon: Icons.edit,
                  onTap: () {
                  },
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Find Message',
                  icon: Icons.search,
                  onTap: () {
                  },
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Delete Chat',
                  icon: Icons.delete,
                  onTap: () {
                  },
                  showDivider: true,
                ),
                _buildSection(
                  context: context,
                  title: 'Block User',
                  icon: Icons.block,
                  onTap: () {
                  },
                  showDivider: false, // Last item does not need a divider
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent, // Transparent to let the parent container's color show through
            width: double.infinity, // Full width
            padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 30, color: Colors.lightBlue),
                    SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_sharp, size: 15, color: Colors.white),
              ],
            ),
          ),
        ),
        if (showDivider) ...[
          SizedBox(height: 5),
          Row(
            children: [
              SizedBox(width: 40), // Adjust this width to match the icon's width plus margin
              Expanded(
                child: Divider(thickness: 1.0, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ],
    );
  }


}
