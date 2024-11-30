import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/StorageService.dart';
import '../auth/LoginPage.dart';
import 'PagesUtils/MyQRCodePage.dart';

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final String userId = _authService.getCurrentUserId();
    final userInfo = await _fireStoreService.getUserInfo(userId);

    if (userInfo != null) {
      setState(() {
        _avatarUrl = userInfo['avatar'] as String?;
        _userName = userInfo['name'] as String? ?? 'User Name';
        _userEmail = userInfo['email'] as String? ?? 'user@example.com';
      });
    }
  }

  void _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _authService.signout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  void _changePassword(BuildContext context) async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    bool isOldPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isOldPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isOldPasswordVisible = !isOldPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isOldPasswordVisible,
                  ),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isNewPasswordVisible,
                  ),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isConfirmPasswordVisible,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (newPasswordController.text ==
                        confirmPasswordController.text) {
                      Navigator.of(context).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Passwords do not match')),
                      );
                    }
                  },
                  child: Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      showLoadingDialog(context);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final cred = EmailAuthProvider.credential(
            email: _userEmail,
            password: oldPasswordController.text,
          );

          await user.reauthenticateWithCredential(cred);

          await user.updatePassword(newPasswordController.text);

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password changed successfully')),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
    await storageService.uploadAvatar(
        _authService.getCurrentUserId(), 'avatars');
    Navigator.of(context).pop();
    _loadUserData();
    setState(() {});
  }

  void _editName() async {
    final TextEditingController nameController =
        TextEditingController(text: _userName);

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(nameController.text.trim()),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != _userName) {
      setState(() {
        _userName = newName;
      });
      await _fireStoreService.updateUserName(
          _authService.getCurrentUserId(), newName);
    }
  }

  void _navigateToMyQRCodePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyQRCodePage(
          userId: _authService.getCurrentUserId(),
          userName: _userName,
          avatarUrl: _avatarUrl,
        ),
      ),
    );
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
                        : AssetImage('assets/loading.png') as ImageProvider,
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
                label: Text('Change Password'),
                onPressed: () => _changePassword(context),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.qr_code),
                label: Text('My QR Code'),
                onPressed: () => _navigateToMyQRCodePage(context),
              ),
              SizedBox(height: 30),
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
