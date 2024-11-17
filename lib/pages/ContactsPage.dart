import 'package:flutter/material.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../UI_Widgets/UserTile.dart';
import '../chat/contacts/UserProfilePage.dart';
import '../services/AuthService.dart';
import '../services/FireStoreService.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();
  final FriendService friendService = FriendService();

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contacts")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: buildUserLists(context)),
        ],
      ),
    );
  }

  Widget buildUserLists(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fireStoreService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        final currentUserId = authService.getCurrentUserId();

        return ListView(
          children: [
            buildFriendsSection(context),
            buildFriendRequestsSection(context),
            buildSuggestionsSection(context, users, currentUserId),
          ],
        );
      },
    );
  }

  Widget buildFriendsSection(BuildContext context) {
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
        final filteredFriends = friends.where((friend) {
          return searchQuery.isEmpty || friend['name'].toLowerCase().contains(searchQuery);
        }).toList();

        return Column(
          children: [
            if (filteredFriends.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Friends", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ...filteredFriends.map((friendData) => userListItem(friendData, context)).toList(),
          ],
        );
      },
    );
  }

  Widget buildFriendRequestsSection(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendRequests(authService.getCurrentUserId()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading friend requests"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friendRequests = snapshot.data ?? [];

        return Column(
          children: [
            if (friendRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Friend Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ...friendRequests.map((request) => friendRequestItem(request, context)).toList(),
          ],
        );
      },
    );
  }

  Widget buildSuggestionsSection(BuildContext context, List<Map<String, dynamic>> users, String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendsStream(currentUserId),
      builder: (context, friendSnapshot) {
        if (friendSnapshot.hasError) {
          return const Center(child: Text("Error loading suggestions"));
        }
        if (friendSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = friendSnapshot.data ?? [];
        final friendIds = friends.map((friend) => friend['id']).toSet();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: friendService.getFriendRequests(currentUserId),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const Center(child: Text("Error loading suggestions"));
            }
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final friendRequests = requestSnapshot.data ?? [];
            final requesterIds = friendRequests.map((request) => request['requesterId']).toSet();

            final suggestions = users.where((user) {
              final isCurrentUser = user['id'] == currentUserId;
              final isFriend = friendIds.contains(user['id']);
              final hasSentRequest = requesterIds.contains(user['id']);
              return !isCurrentUser && !isFriend && !hasSentRequest && (searchQuery.isEmpty || user['name'].toLowerCase().contains(searchQuery));
            }).toList();

            return Column(
              children: [
                if (suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Suggestions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ...suggestions.map((userData) => userListItem(userData, context)).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget userListItem(Map<String, dynamic> userData, BuildContext context) {
    return FutureBuilder<bool>(
      future: friendService.checkIfFriends(authService.getCurrentUserId(), userData["id"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        var isFriend = snapshot.data ?? false;

        return FutureBuilder<bool>(
          future: friendService.checkReceivedRequest(userData["id"], authService.getCurrentUserId()),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (requestSnapshot.hasError) {
              return Text('Error: ${requestSnapshot.error}');
            }

            var hasReceivedRequest = requestSnapshot.data ?? false;

            return FutureBuilder<bool>(
              future: friendService.checkPendingRequest(authService.getCurrentUserId(), userData["id"]),
              builder: (context, pendingSnapshot) {
                if (pendingSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (pendingSnapshot.hasError) {
                  return Text('Error: ${pendingSnapshot.error}');
                }

                var hasSentRequest = pendingSnapshot.data ?? false;
                isFriend = isFriend || hasReceivedRequest;

                return UserTile(
                  text: userData["name"],
                  avatar: userData["avatar"],
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userData: userData,
                          relationshipStatus: isFriend ? 'remove' : hasSentRequest ? 'cancel' : hasReceivedRequest ? 'accept' : 'add',
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                  showSendRequestButton: !isFriend || hasSentRequest,
                  hasSentRequest: hasSentRequest,
                  onSendRequest: () async {
                    await friendService.addFriend(userData['id']);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Friend request sent')),
                    );
                  },
                  onCancelRequest: () async {
                    await friendService.cancelFriendRequest(userData['id']);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Friend request cancelled')),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget friendRequestItem(Map<String, dynamic> request, BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fireStoreService.getUserInfo(request["requesterId"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading user info');
        }

        final userInfo = snapshot.data;
        final _avatarUrl = userInfo?['avatar'] as String? ?? '';
        final _userName = userInfo?['name'] as String? ?? 'User Name';

        return UserTile(
          onTap: () {
            if (userInfo != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userData: userInfo,
                    relationshipStatus: 'accept',
                  ),
                ),
              );
            }
          },
          text: "Friend request from $_userName",
          avatar: _avatarUrl,
          showRequestActions: true,
          onAccept: () async {
            await friendService.acceptFriendRequest(request['id']);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request accepted')),
            );
          },
          onDecline: () async {
            await friendService.declineFriendRequest(request['id']);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request declined')),
            );
          },
        );
      },
    );
  }
}
