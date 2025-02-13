import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/pages/SearchPage.dart';

import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import 'ChangeTheme.dart';
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
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final String currentUserId = widget.id;
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
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          color: themeProvider.themeMode == ThemeMode.dark
              ? Colors.grey[900]
              : Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SafeArea(
            child: Row(
              children: <Widget>[
                SizedBox(width: 10),
                Icon(Icons.search_sharp, color: Colors.white, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _focusNode.unfocus();
                    },
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchPage()),
                        );
                      },
                      style: ButtonStyle(
                        mouseCursor: MaterialStateProperty.all<MouseCursor>(SystemMouseCursors.basic),
                      ),
                      child: Text(
                        "Search",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.white, size: 30),
                  onPressed: _navigateToScanQRCode,
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
