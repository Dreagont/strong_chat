import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FriendService.dart';
import 'package:strong_chat/services/StorageService.dart';
import '../../chat/ChatPage.dart';
import '../../services/FireStoreService.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? relationshipStatus;
  final bool isCurrentUser;

  UserProfilePage({
    Key? key,
    required this.userData,
    this.relationshipStatus,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FriendService friendService = FriendService();
  late String relationshipStatus;
  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();
  final StorageService storageService = StorageService();

  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    relationshipStatus = widget.relationshipStatus ?? '';
    _nameController.text = widget.userData['name'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isNotEmpty) {
      await chatService.updateUserInfo(
          authService.getCurrentUserId(),
          {'name': _nameController.text.trim()}
      );
      setState(() {
        widget.userData['name'] = _nameController.text.trim();
        _isEditingName = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _updateAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final String? newAvatarUrl = await storageService.uploadAvatar(
          AuthService().getCurrentUserId(),
          'avatars'
      );

      if (newAvatarUrl != null) {
        setState(() {
          widget.userData['avatar'] = newAvatarUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar')),
      );
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }


  void handleFriendAction(BuildContext context) async {
    final friendId = widget.userData['id'];
    if (relationshipStatus == 'add') {
      await friendService.addFriend(friendId);
      setState(() {
        relationshipStatus = 'cancel';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent')),
      );
    } else if (relationshipStatus == 'cancel') {
      await friendService.cancelFriendRequest(friendId);
      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request cancelled')),
      );
    } else if (relationshipStatus == 'remove') {
      await friendService.removeFriend(friendId);
      setState(() {
        relationshipStatus = 'add';
      });
    } else if (relationshipStatus == 'accept') {
      await friendService.acceptFriendRequest(friendId);
      setState(() {
        relationshipStatus = 'remove';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted')),
      );
    } else if (relationshipStatus == 'decline') {
      await friendService.declineFriendRequest(friendId);
      setState(() {
        relationshipStatus = 'add';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request declined')),
      );
    }
  }

  Widget _buildAvatarStack() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: widget.userData["avatar"] != null
              ? NetworkImage(widget.userData["avatar"])
              : null,
          child: _isUploadingAvatar
              ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
              : widget.userData["avatar"] == null
              ? Icon(Icons.person, size: 30)
              : null,
        ),
        if (widget.isCurrentUser && !_isUploadingAvatar)
          Positioned(
            right: -10,
            bottom: -10,
            child: ClipOval(
              child: Container(
                color: Colors.black54,
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 17,
                  ),
                  onPressed: _updateAvatar,
                ),
              ),
            ),
          ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/background.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 24, 0, 0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_outlined),
                    color: Colors.white,
                    iconSize: 22,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatarStack(), // Use the new avatar stack widget
                      const SizedBox(width: 10),
                      if (_isEditingName && widget.isCurrentUser)
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.check, color: Colors.white),
                                onPressed: _updateName,
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              userData["name"],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isCurrentUser)
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isEditingName = true;
                                  });
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(Icons.email, 'Email', userData["email"]),
                  buildInfoRow(Icons.work, 'Work', userData["work"] ?? "unknown"),
                  buildInfoRow(Icons.cake, 'Date of Birth', userData["dob"] ?? "unknown"),
                  buildInfoRow(Icons.home, 'Address', userData["address"] ?? "unknown"),
                  buildInfoRow(Icons.phone, 'Phone', userData["phone"] ?? "unknown"),
                  Divider(color: Colors.grey,),

                  if (!widget.isCurrentUser) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FutureBuilder<String?>(
                          future: chatService.getNickname(
                            authService.getCurrentUserId(),
                            userData["id"],
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ElevatedButton(
                                onPressed: null,
                                child: Text("Loading..."),
                              );
                            }

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      friendData: userData,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Chat",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                          ),
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
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(
                '$label:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}