import 'package:flutter/material.dart';
import '../UI_Widgets/UserTile.dart';
import '../chat/ChatPage.dart';
import '../chat/contacts/UserProfilePage.dart';
import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import '../services/FriendService.dart';

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
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final userId = authService.getCurrentUserId();
    final friendList = await friendService.getFriends(userId);
    setState(() {
      friends = friendList;
      isLoading = false;
    });
  }

  Future<void> _reloadLists() async {
    setState(() {
      isLoading = true;
    });
    await _loadFriends();
    setState(() {
      isLoading = false;
    });
  }

  Future<String> checkFriendStatus(var friendId) async {
    String relationshipStatus = "";
    final String userId = fireStoreService.authService.getCurrentUserId();

    final bool isFriend = await friendService.checkIfFriends(userId, friendId);
    final bool hasPendingRequest =
    await friendService.checkPendingRequest(userId, friendId);
    final bool hasReceivedRequest =
    await friendService.checkReceivedRequest(userId, friendId);

    if (isFriend) {
      relationshipStatus = 'remove';
    } else if (hasPendingRequest) {
      relationshipStatus = 'cancel';
    } else if (hasReceivedRequest) {
      relationshipStatus = 'accept';
    } else {
      relationshipStatus = 'add';
    }

    return relationshipStatus;
  }

  Future<void> _handleRefresh() async {
    await _reloadLists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: buildUserLists(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildUserLists(BuildContext context) {
    final filteredFriends = friends.where((friend) {
      return searchQuery.isEmpty || friend['name'].toLowerCase().contains(searchQuery);
    }).toList();

    return ListView(
      children: [
        if (filteredFriends.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Friends", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ...filteredFriends.map((friendData) => userListItem(friendData, context)).toList(),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: friendService.getFriendRequests(authService.getCurrentUserId()),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const Center(child: Text("Error loading friend requests"));
            }
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final friendRequests = requestSnapshot.data ?? [];
            final requesterIds = friendRequests.map((request) => request['requesterId']).toSet();

            return Column(
              children: [
                if (friendRequests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Friend Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ...friendRequests.map((request) => friendRequestItem(request, context)).toList(),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fireStoreService.getUsersStream(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasError) {
                      return const Center(child: Text("Error loading users"));
                    }
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Text("Loading..."));
                    }
                    final users = userSnapshot.data ?? [];
                    final currentUserId = authService.getCurrentUserId();

                    final friendIds = friends.map((friend) => friend['id']).toSet();
                    final suggestions = users.where((user) {
                      final isCurrentUser = user['id'] == currentUserId;
                      final isFriend = friendIds.contains(user['id']);
                      final hasSentRequest = requesterIds.contains(user['id']);
                      return !isCurrentUser && !isFriend && !hasSentRequest;
                    }).toList();

                    final filteredSuggestions = suggestions.where((user) {
                      return searchQuery.isEmpty || user['name'].toLowerCase().contains(searchQuery);
                    }).toList();

                    return Column(
                      children: [
                        if (filteredSuggestions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Suggestions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ...filteredSuggestions.map((userData) => userListItem(userData, context)).toList(),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }


  Widget userListItem(Map<String, dynamic> userData, BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserRelationshipData(userData["id"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final data = snapshot.data!;
        final isFriend = data['isFriend'];
        final hasSentRequest = data['hasSentRequest'];
        final relationshipStatus = data['relationshipStatus'];

        return UserTile(
          text: userData["name"],
          avatar: userData["avatar"],
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  userData: userData,
                  relationshipStatus: relationshipStatus,
                ),
              ),
            );
            if (result == true) {
              _reloadLists();
            }
          },
          showSendRequestButton: !isFriend || hasSentRequest,
          hasSentRequest: hasSentRequest,
          onSendRequest: () async {
            await friendService.addFriend(userData['id']);
            await _reloadLists();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request sent')),
            );
          },
          onCancelRequest: () async {
            await friendService.cancelFriendRequest(userData['id']);
            await _reloadLists();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request cancelled')),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchUserRelationshipData(String userId) async {
    final currentUserId = authService.getCurrentUserId();
    final isFriend = await friendService.checkIfFriends(currentUserId, userId);
    final hasReceivedRequest = await friendService.checkReceivedRequest(userId, currentUserId);
    final hasSentRequest = await friendService.checkPendingRequest(currentUserId, userId);
    final relationshipStatus = await checkFriendStatus(userId);

    return {
      'isFriend': isFriend || hasReceivedRequest,
      'hasSentRequest': hasSentRequest,
      'relationshipStatus': relationshipStatus,
    };
  }

  Widget friendRequestItem(Map<String, dynamic> request, BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchRequestDetails(request["requesterId"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Text('Error loading friend request details');
        }

        final userInfo = snapshot.data!;
        final _avatarUrl = userInfo['avatar'] ?? '';
        final _userName = userInfo['name'] ?? 'User Name';
        final status = userInfo['relationshipStatus'];

        return UserTile(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  userData: userInfo,
                  relationshipStatus: status,
                ),
              ),
            );
            if (result == true) {
              _reloadLists();
            }
          },
          text: "Friend request from $_userName",
          avatar: _avatarUrl,
          showRequestActions: true,
          onAccept: () async {
            await friendService.acceptFriendRequest(request['id']);
            await _reloadLists();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request accepted')),
            );
          },
          onDecline: () async {
            await friendService.declineFriendRequest(request['id']);
            await _reloadLists();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request declined')),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchRequestDetails(String requesterId) async {
    final userInfo = await fireStoreService.getUserInfo(requesterId);
    if (userInfo == null) throw Exception('User not found');
    final relationshipStatus = await checkFriendStatus(userInfo["id"]);
    return {
      ...userInfo,
      'relationshipStatus': relationshipStatus,
    };
  }

}
