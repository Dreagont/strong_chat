import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../../UI_Widgets/UserTile.dart';
import '../ChangeTheme.dart';
import '../contacts/UserProfilePage.dart';
import '../../services/AuthService.dart';
import '../../services/FireStoreService.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();
  final FriendService friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark ? Colors.grey[900] : Colors.blue,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: friendService.getFriendRequests(authService.getCurrentUserId()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading friend requests"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friendRequests = snapshot.data ?? [];
          if (friendRequests.isEmpty) {
            return const Center(child: Text("No friend requests"));
          }

          return ListView(
            children: friendRequests.map((request) =>
                buildRequestItem(request, context, themeProvider)
            ).toList(),
          );
        },
      ),
    );
  }

  Widget buildRequestItem(Map<String, dynamic> request, BuildContext context, ThemeProvider themeProvider) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fireStoreService.getUserInfo(request["requesterId"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final userInfo = snapshot.data!;

        return UserTile(
          themeProvider: themeProvider,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  userData: userInfo,
                  relationshipStatus: 'accept',
                ),
              ),
            );
          },
          text: "Friend request from ${userInfo['name']}",
          avatar: userInfo['avatar'],
          showRequestActions: true,
          onAccept: () async {
            await friendService.acceptFriendRequest(request['id']);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request accepted')),
            );
          },
          onDecline: () async {
            await friendService.declineFriendRequest(request['id']);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Friend request declined')),
            );
          },
        );
      },
    );
  }
}