import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import 'ContactsPage.dart';
import 'MessagesPage.dart';
import 'ProfilePage.dart';
import 'ScanQRCodePage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_titles[_selectedIndex]} - ${widget.id}'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _navigateToScanQRCode,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}