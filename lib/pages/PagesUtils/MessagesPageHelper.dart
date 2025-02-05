import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import '../../UI_Widgets/ChatTile.dart';
import '../../chat/ChatPage.dart';

enum ChatOption { editNickname, hide, toggleBlock, reset, toggleNotification }
Widget createChatTile({
  required ThemeProvider theme,
  required BuildContext context,
  required Map<String, dynamic> friendData,
  required String currentUserId,
  required FireStoreService fireStoreService,
  required String nickname,
  required void Function(ChatOption, Map<String, dynamic>) onOptionsSelected,
}) {
  final String chatId = '${currentUserId}_${friendData['id']}';

  return StreamBuilder<QuerySnapshot>(
    stream: fireStoreService.getMessage(currentUserId, friendData['id']),
    key: ValueKey(chatId),
    builder: (context, messageSnapshot) {
      if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
        return const SizedBox.shrink();
      }
      final unreadCount = _countUnreadMessages(messageSnapshot.data!.docs, currentUserId, friendData['id']);
      final lastMessageDoc = messageSnapshot.data!.docs.last;
      final lastMessage = lastMessageDoc['message'];
      final senderId = lastMessageDoc['senderId'];
      final timestamp = (lastMessageDoc['timeStamp'] as Timestamp).toDate();
      final senderPrefix = senderId == currentUserId ? 'Me: ' : '${friendData["name"]}: ';

      return RepaintBoundary(
        child: GestureDetector(
          onLongPress: () => _showOptionsBottomSheet(
              context,
              friendData,
              currentUserId,
              onOptionsSelected
          ),
          child: ChatTile(
            key: ValueKey('${chatId}_${timestamp.millisecondsSinceEpoch}'),
            theme: theme,
            messType: lastMessageDoc["messType"],
            name: nickname,
            avatar: friendData["avatar"],
            lastMessage: lastMessage,
            senderPrefix: senderPrefix,
            timestamp: timestamp,
            count: unreadCount,
            onOptionsPressed: () => _showOptionsBottomSheet(
              context,
              friendData,
              currentUserId,
              onOptionsSelected,
            ),
            onTap: () {
              _handleChatTileTap(
                  context,
                  currentUserId,
                  friendData,
                  fireStoreService,
                  messageSnapshot.data!.docs
              );
            },
          ),
        ),
      );
    },
  );
}

int _countUnreadMessages(List<DocumentSnapshot> docs, String currentUserId, String friendId) {
  int count = 0;
  for (DocumentSnapshot doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['senderId'] == friendId && !(data['isRead'] ?? false)) {
      count++;
    }
  }
  return count;
}

void _handleChatTileTap(
    BuildContext context,
    String currentUserId,
    Map<String, dynamic> friendData,
    FireStoreService fireStoreService,
    List<QueryDocumentSnapshot> docs,
    ) {
  if (friendData['id'] != currentUserId) {
    for (DocumentSnapshot doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] == friendData['id'] && !(data['isRead'] ?? false)) {
        doc.reference.update({'isRead': true});
      }
    }
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatPage(
        friendData: friendData,
      ),
    ),
  );
}

void _showOptionsBottomSheet(
    BuildContext context,
    Map<String, dynamic> friendData,
    String currentUserId,
    void Function(ChatOption, Map<String, dynamic>) onOptionsSelected,
    ) {
  Stream<bool> blockedStream = isBlockedHimStream(currentUserId, friendData['id']);
  Stream<bool> notificationStream =   FireStoreService().isNotificationEnabledStream(currentUserId, friendData['id']);

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StreamBuilder<bool>(
        stream: blockedStream,
        builder: (context, blockedSnapshot) {
          bool isBlocked = blockedSnapshot.data ?? false;

          return StreamBuilder<bool>(
            stream: notificationStream,
            builder: (context, notificationSnapshot) {
              bool isNotificationEnabled = notificationSnapshot.data ?? true;

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
                  ListTile(
                    leading: Icon(
                      isNotificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: isNotificationEnabled ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      isNotificationEnabled ? "Disable Notifications" : "Enable Notifications",
                      style: TextStyle(
                        color: isNotificationEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onOptionsSelected(ChatOption.toggleNotification, friendData);
                    },
                  ),
                ],
              );
            },
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




