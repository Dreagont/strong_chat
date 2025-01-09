import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../UI_Widgets/InputBox.dart';
import '../../services/AuthService.dart';
import '../../services/FireStoreService.dart';
import '../../services/StorageService.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';

class UserInput extends StatelessWidget {
  final TextEditingController messController;
  final FocusNode focusNode;
  final String friendId;
  final VoidCallback onMessageSent;
  final VoidCallback sendTextMessage;
  final VoidCallback sendImageMessage;
  final VoidCallback sendVideoMessage;
  final VoidCallback sendFileMessage;

  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();
  final StorageService storageService = StorageService();

  UserInput({
    required this.messController,
    required this.focusNode,
    required this.friendId,
    required this.onMessageSent,
    required this.sendTextMessage,
    required this.sendImageMessage,
    required this.sendVideoMessage,
    required this.sendFileMessage,
  });

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (event.isShiftPressed) {
        } else {
          sendTextMessage();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final color = themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.grey;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        color: themeProvider.themeMode == ThemeMode.dark ? Colors.grey[900] : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              color: color,
              icon: Icon(Icons.attach_file),
              onPressed: () => showMediaOptions(context),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: RawKeyboardListener(
                  focusNode: focusNode,
                  onKey: kIsWeb ? _handleKeyEvent : null,
                  child: TextFormField(
                    controller: messController,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Type your message",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              color: color,
              onPressed: sendTextMessage,
              icon: Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaOption(
                context,
                Icons.image,
                'Image',
                sendImageMessage,
              ),
              _buildMediaOption(
                context,
                Icons.video_library,
                'Video',
                sendVideoMessage,
              ),
              _buildMediaOption(
                context,
                Icons.insert_drive_file,
                'File',
                sendFileMessage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
