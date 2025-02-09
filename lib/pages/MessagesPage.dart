import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/pages/PagesUtils/ChatManager.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'PagesUtils/MessagesPageHelper.dart';
import 'ChangeTheme.dart';

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();
  final Map<String, Map<String, dynamic>> _friendsMap = {};
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    _initializeChatStream();
  }

  void _initializeChatStream() {
    final userId = authService.getCurrentUserId();
    fireStoreService.getChatsStream(userId).listen((newFriends) {
      if (!mounted) return;

      for (var friend in newFriends) {
        if (friend['isHide'] != true) {
          final oldData = _friendsMap[friend['id']];
          if (oldData != null && oldData['lastMessTime'] != friend['lastMessTime']) {
            // Only update the specific chat that changed
            setState(() {
              _friendsMap[friend['id']] = friend;
            });
          } else if (oldData == null) {
            // New chat added
            setState(() {
              _friendsMap[friend['id']] = friend;
            });
          }
        } else if (_friendsMap.containsKey(friend['id'])) {
          // Remove hidden chat
          setState(() {
            _friendsMap.remove(friend['id']);
          });
        }
      }
    }, onError: (error) {
      print("Error fetching chats: $error");
    });
  }

  List<Map<String, dynamic>> get _sortedFriends {
    return _friendsMap.values.toList()
      ..sort((a, b) => (b['lastMessTime'] ?? 0).compareTo(a['lastMessTime'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.grey[200],
      body: _buildCustomScrollView(themeProvider),
    );
  }

  Widget _buildCustomScrollView(ThemeProvider theme) {
    final friends = _sortedFriends;

    if (friends.isEmpty) {
      return FutureBuilder(
        future: Future.delayed(Duration(seconds: 5), () => true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child:
                CircularProgressIndicator()
            );
          } else {
            return _buildEmptyState();
          }
        },
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == friends.length) {
                return const SizedBox(height: 30);
              }
              return _buildFriendListItem(friends[index], theme);
            },
            childCount: friends.length + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("No Chat Found"),
          const SizedBox(height: 30),
          Text(
            'Easy to find and chat with your friends',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
            ),
            onPressed: () {},
            child: const Text(
              'Add more friend',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.white
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFriendListItem(Map<String, dynamic> friendData, ThemeProvider theme) {
    final String currentUserId = authService.getCurrentUserId();
    final String friendId = friendData["id"];

    return KeyedSubtree(
      key: ValueKey(friendId),
      child: StreamBuilder<String?>(
        stream: fireStoreService.getNicknameStream(currentUserId, friendId),
        builder: (context, nicknameSnapshot) {
          if (nicknameSnapshot.hasError) {
            return Text('Error: ${nicknameSnapshot.error}');
          }

          final nickname = nicknameSnapshot.data ?? friendData["name"];

          return createChatTile(
            theme: theme,
            context: context,
            friendData: friendData,
            currentUserId: currentUserId,
            fireStoreService: fireStoreService,
            nickname: nickname,
            onOptionsSelected: _handleOptionsSelected,
          );
        },
      ),
    );
  }

  void _handleOptionsSelected(ChatOption option, Map<String, dynamic> data) {
    final chatManager = ChatManager(
        authService: authService,
        fireStoreService: fireStoreService
    );
    switch (option) {
      case ChatOption.hide:
        _hideChatOptimistically(data['id']);
        break;
      case ChatOption.editNickname:
        chatManager.showChangeNicknameDialog(context, data);
        break;
      case ChatOption.reset:
        chatManager.resetNickname(context, data['id']);
        break;
      case ChatOption.toggleBlock:
        chatManager.toggleBlockUser(context, data['id']);
        break;
      case ChatOption.toggleNotification:
        chatManager.toggleNotification(context, data['id']);
        break;
    }
  }

  void _hideChatOptimistically(String friendId) {
    setState(() {
      _friendsMap.remove(friendId);
    });

    fireStoreService
        .hideChatForUser(authService.getCurrentUserId(), friendId)
        .catchError((error) {
      _showErrorSnackbar("Failed to hide chat");
      _initializeChatStream();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }
}