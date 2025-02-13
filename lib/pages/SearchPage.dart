import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../UI_Widgets/UserTile.dart';
import 'ChangeTheme.dart';
import 'PagesUtils/ScanQRCodePage.dart';
import 'contacts/UserProfilePage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FocusNode _focusNode = FocusNode();
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();
  final FriendService friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: buildUserLists(context),
    );
  }

  PreferredSize _buildAppBar(ThemeProvider themeProvider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        color: themeProvider.themeMode == ThemeMode.dark ? Colors.grey[900] : Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SafeArea(
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _focusNode.unfocus(),
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _searchController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white, size: 30),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanQRCodePage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserLists(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fireStoreService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No users found"));
        }

        final users = snapshot.data!;
        final currentUserId = authService.getCurrentUserId();

        return ListView(
          children: [
            if (searchQuery.isNotEmpty) buildFriendsSection(context, themeProvider),
            buildSuggestionsSection(context, users, currentUserId, themeProvider),
          ],
        );
      },
    );
  }

  Widget buildFriendsSection(BuildContext context, ThemeProvider themeProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendsStream(authService.getCurrentUserId()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final filteredFriends = snapshot.data!.where((friend) {
          return friend['name'].toString().toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredFriends.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Friends (${filteredFriends.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...filteredFriends.map((friendData) => _buildFriendListItem(friendData)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFriendListItem(Map<String, dynamic> userData) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(userData['avatar']),
        radius: 30,
      ),
      title: Text(
        userData['name'],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        ],
      ),
      onTap: () => _navigateToUserProfile(userData, true, false, false),
    );
  }

  Widget buildSuggestionsSection(
      BuildContext context,
      List<Map<String, dynamic>> users,
      String currentUserId,
      ThemeProvider themeProvider,
      ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendService.getFriendsStream(currentUserId),
      builder: (context, friendSnapshot) {
        if (friendSnapshot.hasError) {
          return const SizedBox.shrink();
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
              return const SizedBox.shrink();
            }
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: null);
            }

            final friendRequests = requestSnapshot.data ?? [];
            final requesterIds = friendRequests.map((request) => request['requesterId']).toSet();

            final suggestions = users.where((user) {
              final isCurrentUser = user['id'] == currentUserId;
              final isFriend = friendIds.contains(user['id']);
              final hasSentRequest = requesterIds.contains(user['id']);
              return !isCurrentUser && !isFriend && !hasSentRequest &&
                  (searchQuery.isEmpty || user['name'].toString().toLowerCase().contains(searchQuery));
            }).toList()..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

            if (suggestions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No suggestions found"),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Suggestions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...suggestions.map((userData) => _buildSuggestionTile(userData, themeProvider)).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> userData, ThemeProvider themeProvider) {
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        friendService.checkIfFriends(authService.getCurrentUserId(), userData["id"]),
        friendService.checkReceivedRequest(userData["id"], authService.getCurrentUserId()),
        friendService.checkPendingRequest(authService.getCurrentUserId(), userData["id"]),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return const Center(child: null);
        }

        final isFriend = snapshot.data![0];
        final hasReceivedRequest = snapshot.data![1];
        final hasSentRequest = snapshot.data![2];

        return UserTile(
          themeProvider: themeProvider,
          text: userData["name"],
          avatar: userData["avatar"],
          onTap: () => _navigateToUserProfile(userData, isFriend, hasSentRequest, hasReceivedRequest),
          showSendRequestButton: !isFriend || hasSentRequest,
          hasSentRequest: hasSentRequest,
          onSendRequest: () => _handleFriendRequest(userData['id'], true),
          onCancelRequest: () => _handleFriendRequest(userData['id'], false),
        );
      },
    );
  }

  Future<void> _navigateToUserProfile(
      Map<String, dynamic> userData,
      bool isFriend,
      bool hasSentRequest,
      bool hasReceivedRequest,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userData: userData,
          relationshipStatus: isFriend ? 'remove' :
          hasSentRequest ? 'cancel' :
          hasReceivedRequest ? 'accept' : 'add',
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _handleFriendRequest(String userId, bool isAdd) async {
    try {
      if (isAdd) {
        await friendService.addFriend(userId);
        _showSnackBar('Friend request sent');
      } else {
        await friendService.cancelFriendRequest(userId);
        _showSnackBar('Friend request cancelled');
      }
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to ${isAdd ? 'send' : 'cancel'} friend request');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}