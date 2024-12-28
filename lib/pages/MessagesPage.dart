import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<Map<String, dynamic>> friends = [];
  Stream<List<Map<String, dynamic>>>? chatStream;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  void fetchChats() {
    chatStream = fireStoreService.getChatsStream(authService.getCurrentUserId());
    chatStream?.listen((newFriends) {
      if (!mounted) return;
      setState(() {
        friends = newFriends
            .where((friend) => friend['isHide'] != true)
            .toList()
          ..sort((a, b) => (b['lastMessTime'] ?? 0).compareTo(a['lastMessTime'] ?? 0));
      });
    }, onError: (error) {
      print("Error fetching chats: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.grey[200],
      body: userList(themeProvider),
    );
  }

  Widget userList(ThemeProvider theme) {
    if (friends.isEmpty) {
      return const Center(child: Text("Loading......"));
    }
    return ListView.builder(
      itemCount: friends.length + 1,
      itemBuilder: (context, index) {
        if (index == friends.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Easy to find and chat with your friends',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                    ),
                    onPressed: () {

                    },
                    child: Text(
                      'Add more friend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          );
        }
        final friendData = friends[index];
        return friendListItem(friendData, context, theme);
      },
    );
  }

  Widget friendListItem(Map<String, dynamic> friendData, BuildContext context, ThemeProvider theme) {
    final String currentUserId = authService.getCurrentUserId();

    return StreamBuilder<String?>(
      stream: fireStoreService.getNicknameStream(currentUserId, friendData["id"]),
      builder: (context, nicknameSnapshot) {
        if (nicknameSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
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
          onOptionsSelected: (option, data) {
            if (option == ChatOption.hide) {
              _hideChatOptimistically(context, data['id']);
            } else if (option == ChatOption.editNickname) {
              _showChangeNicknameDialog(context, data);
            } else if (option == ChatOption.reset) {
              _resetNickname(context, data['id']);
            } else if (option == ChatOption.toggleBlock) {
              _toggleBlockUser(context, data['id']);
            }
          },
        );
      },
    );
  }

  void _hideChatOptimistically(BuildContext context, String friendId) {
    _updateLocalChatState(friendId);
    fireStoreService.hideChatForUser(authService.getCurrentUserId(), friendId).catchError((error) {
      _showErrorSnackbar(context, "Failed to hide chat");
      fetchChats();
    });
  }

  void _updateLocalChatState(String friendId) {
    setState(() {
      friends.removeWhere((friend) => friend['id'] == friendId);
    });
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _changeNickname(String friendId, String newNickname) async {
    String currentUserId = authService.getCurrentUserId();
    await fireStoreService.editNicknameForFriend(currentUserId, friendId, newNickname);
  }

  Future<void> _resetNickname(BuildContext context, String friendId) async {
    String currentUserId = authService.getCurrentUserId();
    await fireStoreService.resetNicknameToDefault(currentUserId, friendId);
    _showSuccessSnackbar(context, "Nickname reset to default");
  }

  Future<void> _toggleBlockUser(BuildContext context, String friendId) async {
    String currentUserId = authService.getCurrentUserId();
    await fireStoreService.blockActionUserForFriend(currentUserId, friendId);
    _showSuccessSnackbar(context, "Done");
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showChangeNicknameDialog(BuildContext context, Map<String, dynamic> friendData) {
    final nicknameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Change Nickname"),
              IconButton(
                icon: Icon(Icons.restore),
                onPressed: () {
                  Navigator.pop(context);
                  _resetNickname(context, friendData['id']);
                },
                tooltip: "Reset to default nickname",
              ),
            ],
          ),
          content: TextField(
            controller: nicknameController,
            decoration: InputDecoration(
              hintText: "Enter new nickname",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String newNickname = nicknameController.text.trim();
                if (newNickname.isNotEmpty) {
                  _changeNickname(friendData['id'], newNickname);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
