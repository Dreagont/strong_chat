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
  List<Map<String, dynamic>> friends = [];
  Stream<List<Map<String, dynamic>>>? chatStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  void fetchChats() {
    setState(() {
      _isLoading = true;
    });

    chatStream = fireStoreService.getChatsStream(authService.getCurrentUserId());
    chatStream?.listen((newFriends) {
      if (!mounted) return;
      setState(() {
        friends = newFriends
            .where((friend) => friend['isHide'] != true)
            .toList()
          ..sort((a, b) => (b['lastMessTime'] ?? 0).compareTo(a['lastMessTime'] ?? 0));
        _isLoading = false;
      });
    }, onError: (error) {
      print("Error fetching chats: $error");
      setState(() {
        _isLoading = false;
      });
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (friends.isEmpty) {
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
              onPressed: () {
              },
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

    return ListView.builder(
      itemCount: friends.length + 1,
      itemBuilder: (context, index) {
        if (index == friends.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Center(
              child: Column(
                children: [

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
              hideChatOptimistically(context, data['id']);
            } else if (option == ChatOption.editNickname) {
              ChatManager(authService: authService, fireStoreService: fireStoreService).showChangeNicknameDialog(context, data);
            } else if (option == ChatOption.reset) {
              ChatManager(authService: authService, fireStoreService: fireStoreService).resetNickname(context, data['id']);
            } else if (option == ChatOption.toggleBlock) {
              ChatManager(authService: authService, fireStoreService: fireStoreService).toggleBlockUser(context, data['id']);
            }
          },
        );
      },
    );
  }

  void hideChatOptimistically(BuildContext context, String friendId) {
    _updateLocalChatState(friendId);
    fireStoreService
        .hideChatForUser(authService.getCurrentUserId(), friendId)
        .catchError((error) {
      showErrorSnackbar(context, "Failed to hide chat");
      fetchChats();
    });
  }

  void showErrorSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _updateLocalChatState(String friendId) {
    setState(() {
      friends.removeWhere((friend) => friend['id'] == friendId);
    });
  }


}