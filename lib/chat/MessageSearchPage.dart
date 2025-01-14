import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageSearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic> friendData;
  final String userName;
  final String userAvatar;

  const MessageSearchPage({
    Key? key,
    required this.messages,
    required this.friendData,
    required this.userName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _hasSearched = false;

  void _searchMessages(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMessages = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _filteredMessages = widget.messages
          .where((msg) =>
      msg['messType'] == 'text' &&
          msg['message'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    }

    return 'Invalid date';
  }

  String _getMessageSenderName(String senderId) {
    if (senderId == widget.friendData['uid']) {
      return widget.friendData['name'];
    }
    return widget.userName;
  }

  String _getMessageSenderAvatar(String senderId) {
    if (senderId == widget.friendData['uid']) {
      return widget.friendData['avatar'];
    }
    return widget.userAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search text messages...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _searchMessages(_searchController.text);
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: !_hasSearched
                ? const Center(
              child: Text('Enter text and press search to find messages'),
            )
                : _filteredMessages.isEmpty
                ? const Center(
              child: Text('No messages found'),
            )
                : ListView.builder(
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final message = _filteredMessages[index];
                final senderId = message['senderId'];
                final senderName = _getMessageSenderName(senderId);
                final senderAvatar = _getMessageSenderAvatar(senderId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: senderAvatar.isNotEmpty
                        ? NetworkImage(senderAvatar)
                        : null,
                    child: senderAvatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(senderName, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(message['message'] ?? ''),
                  trailing: Text(
                    _formatTimestamp(message['timeStamp']),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}