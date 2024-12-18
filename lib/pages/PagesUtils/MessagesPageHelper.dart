import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import '../../UI_Widgets/ChatTile.dart';
import '../../chat/ChatPage.dart';

enum ChatOption { editNickname, hide, toggleBlock, reset }

Widget createChatTile({
  required BuildContext context,
  required Map<String, dynamic> friendData,
  required String currentUserId,
  required FireStoreService fireStoreService,
  required String nickname,
  required void Function(ChatOption, Map<String, dynamic>) onOptionsSelected,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: fireStoreService.getMessage(currentUserId, friendData['id']),
    builder: (context, messageSnapshot) {
      if (messageSnapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (messageSnapshot.hasError) {
        return Text('Error: ${messageSnapshot.error}');
      }
      if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
        return SizedBox.shrink();
      }

      final lastMessageDoc = messageSnapshot.data!.docs.last;
      final lastMessage = lastMessageDoc['message'];
      final senderId = lastMessageDoc['senderId'];
      final timestamp = (lastMessageDoc['timeStamp'] as Timestamp).toDate();
      final senderPrefix = senderId == currentUserId ? 'Me: ' : '${friendData["name"]}: ';

      return GestureDetector(
        onLongPress: () => _showOptionsBottomSheet(
            context,
            friendData,
            currentUserId,
            onOptionsSelected
        ),
        child: ChatTile(
          messType: lastMessageDoc["messType"],
          name: nickname,
          avatar: friendData["avatar"],
          lastMessage: lastMessage,
          senderPrefix: senderPrefix,
          timestamp: timestamp,
          onTap: () {
            if (friendData['id'] != currentUserId) { // Compare IDs first
              fireStoreService.getMessage(currentUserId, friendData['id'])
                  .first // Get the first snapshot of the stream
                  .then((snapshot) {
                for (DocumentSnapshot doc in snapshot.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Update only if the message is unread and sent by the friend
                  if (data['senderId'] == friendData['id'] && !(data['isRead'] ?? false)) {
                    doc.reference.update({'isRead': true});
                  }
                }
              });
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                    friendName: friendData["name"],
                    friendId: friendData["id"],
                    nickname: nickname
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

void _showOptionsBottomSheet(
    BuildContext context,
    Map<String, dynamic> friendData,
    String currentUserId,
    void Function(ChatOption, Map<String, dynamic>) onOptionsSelected,
    ) {
  Stream<bool> blockedStream = isBlockedHimStream(currentUserId, friendData['id']);

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StreamBuilder<bool>(
        stream: blockedStream,
        builder: (context, blockedSnapshot) {
          bool isBlocked = blockedSnapshot.data ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Change Nickname"),
                onTap: () {
                  Navigator.pop(context);
                  onOptionsSelected(ChatOption.editNickname, friendData);
                },
              ),
              ListTile(
                leading: Icon(Icons.restore),
                title: Text("Reset Nickname"),
                onTap: () {
                  Navigator.pop(context);
                  onOptionsSelected(ChatOption.reset, friendData);
                },
              ),
              ListTile(
                leading: Icon(Icons.hide_source),
                title: Text("Hide Chat"),
                onTap: () {
                  Navigator.pop(context);
                  onOptionsSelected(ChatOption.hide, friendData);
                },
              ),
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.block_flipped : Icons.block,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                title: Text(
                  isBlocked ? "Unblock User" : "Block User",
                  style: TextStyle(
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onOptionsSelected(ChatOption.toggleBlock, friendData);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Stream<bool> isBlockedHimStream(String userId, String friendId) {
  return FirebaseFirestore.instance
      .collection("Users")
      .doc(friendId)
      .collection("chats")
      .where('friendId', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return data['isBlocked'] ?? false;
    } else {
      return false;
    }
  });
}