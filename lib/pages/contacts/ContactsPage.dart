import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../../UI_Widgets/UserTile.dart';
import '../ChangeTheme.dart';
import '../contacts/UserProfilePage.dart';
import '../../services/AuthService.dart';
import '../../services/FireStoreService.dart';
import 'FriendRequestsPage.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();
  final FriendService friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildRequestsButton(context),
          Expanded(child: buildFriendsList(context)),
        ],
      ),
    );
  }

  Widget buildRequestsButton(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendRequests(authService.getCurrentUserId()),
      builder: (context, snapshot) {
        final requestCount = snapshot.data?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendRequestsPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.person_add, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Friend Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (requestCount > 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          requestCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFriendsList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendsStream(authService.getCurrentUserId()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading friends"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(child: Text("No friends yet"));
        }

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Friends (${friends.length})',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...friends
                .map((friendData) => buildFriendListItem(friendData, context))
                .toList(),
          ],
        );
      },
    );
  }

  Widget buildFriendListItem(
      Map<String, dynamic> userData, BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(userData['avatar']),
        radius: 30,
      ),
      title: Text(
        userData['name'],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(
              userData: userData,
              relationshipStatus: 'remove',
            ),
          ),
        );
        if (result == true) {
          setState(() {});
        }
      },
    );
  }
}
