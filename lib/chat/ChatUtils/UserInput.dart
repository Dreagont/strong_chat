import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import '../../services/FireStoreService.dart';
import '../../services/StorageService.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';

class UserInput extends StatefulWidget {
  final TextEditingController messController;
  final FocusNode focusNode;
  final String friendId;
  final VoidCallback onMessageSent;
  final VoidCallback sendTextMessage;
  final VoidCallback sendImageMessage;
  final VoidCallback sendVideoMessage;
  final VoidCallback sendFileMessage;

  const UserInput({
    Key? key,
    required this.messController,
    required this.focusNode,
    required this.friendId,
    required this.onMessageSent,
    required this.sendTextMessage,
    required this.sendImageMessage,
    required this.sendVideoMessage,
    required this.sendFileMessage,
  }) : super(key: key);

  @override
  State<UserInput> createState() => _UserInputState();
}

class _UserInputState extends State<UserInput> {
  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();
  final StorageService storageService = StorageService();
  final _keyboardListenerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      widget.messController.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      widget.messController.removeListener(_handleControllerChange);
    }
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final text = widget.messController.text;
    if (text.endsWith('\n')) {
      widget.messController.text = text.trimRight();
      _sendMessage();
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter && !event.isShiftPressed) {
        final currentText = widget.messController.text;
        if (currentText.endsWith('\n')) {
          widget.messController.text = currentText.substring(0, currentText.length - 1);
        }
        _sendMessage();
      }
    }
  }

  void _sendMessage() {
    String message = widget.messController.text.trim();
    if (message.isNotEmpty) {
      widget.sendTextMessage();
      widget.messController.clear();
      widget.focusNode.requestFocus();
    }
  }

  bool isEmojiVisible = false;
  final FocusNode _emojiPickerFocus = FocusNode();

  void onEmojiSelected(Category? category, Emoji emoji) {
    widget.messController.text = widget.messController.text + emoji.emoji;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final color = themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.grey;
    final backgroundColor = themeProvider.themeMode == ThemeMode.dark ? Colors.grey[900] : Colors.white;

    return Container(
        color: backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: isEmojiVisible,
              child: SizedBox(
                height: 250,
                child: Focus(
                  focusNode: _emojiPickerFocus,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) => onEmojiSelected(category, emoji),
                    config: Config(
                      height: 256,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor:  themeProvider.themeMode == ThemeMode.dark ? Colors.black : Colors.white,
                      ),
                      checkPlatformCompatibility: false,
                      viewOrderConfig: const ViewOrderConfig(),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig:  CategoryViewConfig(
                        backgroundColor:  themeProvider.themeMode == ThemeMode.dark ? Colors.black : Colors.white,
                      ),
                      bottomActionBarConfig: const BottomActionBarConfig(
                          backgroundColor: Colors.white,
                          enabled: false

                      ),
                      searchViewConfig: const SearchViewConfig(
                          backgroundColor: Colors.white,
                          hintText : 'Search for emoji'

                      )
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    color: color,
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => showMediaOptions(context),
                  ),
                  IconButton(
                    color: color,
                    icon: Icon(isEmojiVisible ? Icons.keyboard : Icons.emoji_emotions),
                    onPressed: () {
                      setState(() {
                        isEmojiVisible = !isEmojiVisible;
                      });
                      if (isEmojiVisible) {
                        FocusScope.of(context).requestFocus(_emojiPickerFocus);
                        widget.focusNode.unfocus();
                      } else {
                        FocusScope.of(context).requestFocus(widget.focusNode);
                      }
                    },
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: RawKeyboardListener(
                        focusNode: _keyboardListenerFocusNode,
                        onKey: kIsWeb ? _handleKeyEvent : null,
                        child: TextFormField(
                          controller: widget.messController,
                          focusNode: widget.focusNode,
                          maxLines: 10,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText: "Type your message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      color: color,
                      onPressed: () {
                        if (mounted) {
                          _sendMessage();
                        }
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
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
                widget.sendImageMessage,
              ),
              _buildMediaOption(
                context,
                Icons.video_library,
                'Video',
                widget.sendVideoMessage,
              ),
              _buildMediaOption(
                context,
                Icons.insert_drive_file,
                'File',
                widget.sendFileMessage,
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