import 'package:flutter/material.dart';
import 'package:strong_chat/chat/StorageService.dart';
import '../auth/AuthService.dart';
import '../auth/LoginPage.dart';
import '../chat/FireStoreService.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FireStoreService _fireStoreService = FireStoreService();
  final StorageService storageService = StorageService();
  String? _avatarUrl;
  String _userName = 'User Name';
  String _userEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    showLoadingDialog(context);
    final String userId = _authService.getCurrentUserId();
    final userInfo = await _fireStoreService.getUserInfo(userId);

    if (userInfo != null) {
      setState(() {
        _avatarUrl = userInfo['avatar'] as String?;
        _userName = userInfo['name'] as String? ?? 'User Name';
        _userEmail = userInfo['email'] as String? ?? 'user@example.com';
      });
    }

    Navigator.of(context).pop();
  }


  void _logout(BuildContext context) async {
    await _authService.signout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  void _forgotPassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset link has been sent to your email')),
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password change feature coming soon')),
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _editProfilePicture() async {
    showLoadingDialog(context);
    await storageService.uploadImage(_authService.getCurrentUserId());
    Navigator.of(context).pop(); // Close the loading dialog
    _loadUserData();
    setState(() {});
  }



  void _editName() {
    // Add logic to edit name
    print("Edit Name tapped");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _editProfilePicture,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 16,
                        child: Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _editName,
                    child: Icon(Icons.edit, size: 20, color: Colors.blue),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _userEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.lock_reset),
                label: Text('Forgot Password'),
                onPressed: () => _forgotPassword(context),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.password),
                label: Text('Change Password'),
                onPressed: () => _changePassword(context),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
