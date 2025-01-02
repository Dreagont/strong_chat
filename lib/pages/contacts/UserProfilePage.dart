import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FriendService.dart';
import '../../chat/ChatPage.dart';
import '../../services/FireStoreService.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String relationshipStatus;

  UserProfilePage({
    Key? key,
    required this.userData,
    required this.relationshipStatus,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FriendService friendService = FriendService();
  late String relationshipStatus;
  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    relationshipStatus = widget.relationshipStatus;
  }

  void handleFriendAction(BuildContext context) async {
    final friendId = widget.userData['id'];
    if (relationshipStatus == 'add') {
      await friendService.addFriend(friendId);
      Navigator.pop(context, true);

      setState(() {
        relationshipStatus = 'cancel';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent')),
      );
    } else if (relationshipStatus == 'cancel') {
      await friendService.cancelFriendRequest(friendId);
      Navigator.pop(context, true);

      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request cancelled')),
      );
    } else if (relationshipStatus == 'remove') {
      await friendService.removeFriend(friendId);

      Navigator.pop(context, true);
    } else if (relationshipStatus == 'accept') {
      await friendService.acceptFriendRequest(friendId);
      Navigator.pop(context, true);
      setState(() {
        relationshipStatus = 'remove';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted')),
      );
    } else if (relationshipStatus == 'decline') {
      await friendService.declineFriendRequest(friendId);
      Navigator.pop(context, true);
      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request declined')),
      );
    }
  }

  void fetchNickname() async {
    String? nickname = await chatService.getNickname(authService.getCurrentUserId(), widget.userData["id"]);
    if (nickname != null) {
      print("Nickname: $nickname");
    } else {
      print("Nickname not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userData["name"])),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.userData["avatar"] ?? ''),
                      child: widget.userData["avatar"] == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.userData["name"],
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userData["email"],
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FutureBuilder<String?>(
                          future: chatService.getNickname(
                            authService.getCurrentUserId(),
                            widget.userData["id"],
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ElevatedButton(
                                onPressed: null,
                                child: Text("Loading..."),
                              );
                            }

                            final nickname = snapshot.data;
                            return ElevatedButton(
                              onPressed: nickname != null
                                  ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      friendData: widget.userData,
                                      nickname: nickname,
                                    ),
                                  ),
                                );
                              }
                                  : (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      friendData: widget.userData,
                                      nickname: widget.userData['name'],
                                    ),
                                  ),
                                );
                              },
                              child: Text("Chat"),
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => handleFriendAction(context),
                          child: Text(
                            relationshipStatus == 'add'
                                ? 'Add Friend'
                                : relationshipStatus == 'cancel'
                                ? 'Cancel Request'
                                : relationshipStatus == 'remove'
                                ? 'Remove Friend'
                                : relationshipStatus == 'accept'
                                ? 'Accept Request'
                                : 'Decline Request',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Work: ${widget.userData["work"] ?? "unknown"}',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date of Birth: ${widget.userData["dob"] ?? "unknown"}',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Address: ${widget.userData["address"] ?? "unknown"}',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phone: ${widget.userData["phone"] ?? "unknown"}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
