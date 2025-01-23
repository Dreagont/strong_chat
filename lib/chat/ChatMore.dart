import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/FriendService.dart';

import '../pages/ChangeTheme.dart';
import '../pages/PagesUtils/ChatManager.dart';
import '../pages/PagesUtils/MessagesPageHelper.dart';
import '../pages/contacts/UserProfilePage.dart';
import 'ChatPage.dart';
import 'MessageSearchPage.dart';

class ChatMore extends StatefulWidget {
  final Map<String, dynamic> friendData;
  final List<Map<String, dynamic>> allMessages;
  final String userName;
  final String userAvatar;

  const ChatMore({
    Key? key,
    required this.friendData,
    required this.allMessages,
    required this.userName,
    required this.userAvatar,
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
    final userId = AuthService().getCurrentUserId();
    final friendId = widget.friendData['id'];
    Stream<bool> blockedStream = FireStoreService().isBlockedHimStream(userId, friendId);

    return Scaffold(
      appBar: AppBar(
        title: Text('More Options'),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? Colors.grey[850]
            : Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                child: StreamBuilder<String?>(
                  stream: FireStoreService().getNicknameStream(userId, friendId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    final nickname = snapshot.data ?? "No Nickname";
                    return Text(
                      nickname,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  },
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
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildSection(
                    context: context,
                    title: 'Video Call',
                    icon: Icons.videocam,
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildSection(
                    context: context,
                    title: 'Change Nickname',
                    icon: Icons.edit,
                    onTap: () {
                      ChatManager(
                          authService: AuthService(),
                          fireStoreService: FireStoreService())
                          .showChangeNicknameDialog(
                          context, widget.friendData);
                    },
                    showDivider: true,
                  ),
                  _buildSection(
                    context: context,
                    title: 'Find Message',
                    icon: Icons.search,
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => MessageSearchPage(
                      //       messages: widget.allMessages,
                      //       friendData: widget.friendData,
                      //       userName: widget.userName,
                      //       userAvatar: widget.userAvatar,
                      //     ),
                      //   ),
                      // );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            friendData: widget.friendData,
                            isOpenSearch: true,
                          ),
                        ),
                      );
                    },
                    showDivider: true,
                  ),
                  _buildSection(
                    context: context,
                    title: 'Delete Chat',
                    icon: Icons.delete,
                    onTap: () {
                      ChatManager(
                          authService: AuthService(),
                          fireStoreService: FireStoreService())
                          .hideChat(context, friendId);
                    },
                    showDivider: true,
                  ),
                  StreamBuilder<bool>(
                    stream: blockedStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      final isBlocked = snapshot.data ?? false;
                      final text = isBlocked ? "Unblock User" : "Block User";
                      return _buildSection(
                        context: context,
                        title: text,
                        icon: Icons.block,
                        onTap: () {
                          ChatManager(
                              authService: AuthService(),
                              fireStoreService: FireStoreService())
                              .toggleBlockUser(context, friendId);
                        },
                        showDivider: false,
                      );
                    },
                  ),
                ],
              )
            ],
          ),
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
            color: Colors.transparent,
            width: double.infinity,
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
                      style: TextStyle(fontSize: 22),
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
              SizedBox(width: 40),
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
