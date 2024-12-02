import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import 'contacts/ContactsPage.dart';
import 'MessagesPage.dart';
import 'ProfilePage.dart';
import 'PagesUtils/ScanQRCodePage.dart';

class HomeScreen extends StatefulWidget {
  final String id;
  HomeScreen({required this.id});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    final String currentUserId = widget.id;

    // Request notification permission
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    fireStoreService.listenForNewMessages(currentUserId);
  }

  static const List<String> _titles = <String>[
    'Messages',
    'Contacts',
    'Profile',
  ];

  static final List<Widget> _pages = <Widget>[
    MessagesPage(),
    ContactsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToScanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanQRCodePage()),
    );
  }

  void _addFriend() {
    // Handle add friend action here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SafeArea(
            child: Row(
              children: <Widget>[
                SizedBox(width: 10),
                Icon(Icons.search_sharp, color: Colors.white, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 18),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.white, size: 30),
                  onPressed: _navigateToScanQRCode,
                ),
                if (_selectedIndex == 0)
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.white, size: 30),
                    onPressed: _addFriend,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.message : Icons.message_outlined,
              color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1 ? Icons.contacts : Icons.contacts_outlined,
              color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
            ),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2 ? Icons.person : Icons.person_outline,
              color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }

}
