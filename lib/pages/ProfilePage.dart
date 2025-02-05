import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/pages/contacts/UserProfilePage.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/services/StorageService.dart';
import 'package:strong_chat/services/notification_service.dart';
import 'ChangeTheme.dart';
import '../auth/LoginPage.dart';
import 'ChangeTheme.dart';
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
  String _work = '';
  String _dob = '';
  String _address = '';
  String _phone = '';

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
        _work = userInfo['work'] as String? ?? 'unknown';
        _dob = userInfo['dob'] as String? ?? 'unknown';
        _address = userInfo['address'] as String? ?? 'unknown';
        _phone = userInfo['phone'] as String? ?? 'unknown';
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
      await LocalNotificationService().logout();
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
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: Theme.of(context).primaryColor),
                  SizedBox(width: 10),
                  Text('Change Password'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      prefixIcon: Icon(Icons.lock_outline),
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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_open),
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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Password must be 8-20 characters',
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
                    if (newPasswordController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password must be at least 8 characters')),
                      );
                      return;
                    }

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
    final TextEditingController nameController = TextEditingController(
      text: _userName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_rounded, color: Theme.of(context).primaryColor),
              SizedBox(width: 10),
              Text('Edit Name'),
            ],
          ),
          content: TextField(
            controller: nameController,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Enter new name',
              counterText: '',
              prefixIcon: Icon(Icons.text_fields),
              helperText: 'Name must be between 2-30 characters',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final trimmedName = nameController.text.trim();
                if (trimmedName.length >= 2) {
                  Navigator.of(context).pop(trimmedName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Name must be at least 2 characters long'),
                    ),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != _userName) {
      showLoadingDialog(context);
      try {
        await _fireStoreService.updateUserName(
            _authService.getCurrentUserId(),
            newName
        );

        setState(() {
          _userName = newName;
        });

        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Name updated successfully')),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToMyQRCodePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyQRCodePage(
              userId: _authService.getCurrentUserId(),
              userName: _userName,
              avatarUrl: _avatarUrl,
            ),
      ),
    );
  }

  void _navigateToThemePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ThemeSettingsScreen()
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0.0, 0, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  final userId = _authService.getCurrentUserId();
                  final userData = await  _fireStoreService.getUserInfo(userId);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) =>
                  //         UserProfilePage(userData:  userData!)
                  //   ),
                  // );
                },
                child: Container(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.grey[850]
                      : Colors.white, // Slightly lighter black background
                  width: double.infinity, // Full width
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : AssetImage(
                                'assets/loading.png') as ImageProvider,
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _userName,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                          Text(
                            _userEmail,
                            style: TextStyle(fontSize: 18, color: Colors
                                .grey[600]),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.grey[850]
                    : Colors.white,
                width: double.infinity, // Full width
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                      _buildSection(
                          context,
                          title: 'Change Password',
                          icon: Icons.lock_reset,
                          onTap: () => _changePassword(context),
                          showDivider: true
                      ),
                      _buildSection(context, title: 'Addition Information',
                          icon
                          :Icons.person,
                          onTap: () => editInfo(context),
                          showDivider: true
                      ),
                      _buildSection(
                          context,
                          title: 'My QR Code',
                          icon: Icons.qr_code,
                          onTap: () => _navigateToMyQRCodePage(context),
                          showDivider: true
                      ),
                      _buildSection(
                          context,
                          title: 'Theme',
                          icon: Icons.change_circle_outlined,
                          onTap: () => _navigateToThemePage(context),
                          showDivider: true
                      ),
                      _buildSection(
                          context,
                          title: 'Logout',
                          icon: Icons.logout,
                          onTap: () => _logout(context),
                          showDivider: false
                      )
                    ]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap, required bool showDivider }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 30, color: Colors.lightBlue),
                    SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 22),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_sharp, size: 15),
              ],
            ),
          ),
        ),
        if (showDivider) ...[
          SizedBox(height: 5),
          Row(
            children: [
              SizedBox(width: 40),
              // Adjust this width to match the icon's width plus margin
              Expanded(
                child: Divider(thickness: 1.0, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ],
    );
  }

  void editInfo(BuildContext context) async {
    final TextEditingController workController = TextEditingController(text: _work);
    final TextEditingController addressController = TextEditingController(text: _address);
    final TextEditingController phoneController = TextEditingController(text: _phone);
    DateTime? selectedDate = _dob.isNotEmpty && _dob != 'unknown'
        ? DateFormat('dd/MM/yy').parse(_dob)
        : null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  SizedBox(width: 10),
                  Text('Edit Information'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: workController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Work',
                        prefixIcon: Icon(Icons.work),
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(
                            text: selectedDate != null
                                ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                : '',
                          ),
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.calendar_today),
                            hintText: 'Select your date of birth',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (phoneController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone number must be 8-15 digits.')),
                      );
                      return;
                    }
                    final newInfo = {
                      'work': workController.text.trim(),
                      'dob': selectedDate != null
                          ? DateFormat('dd/MM/yy').format(selectedDate!)
                          : _dob,
                      'address': addressController.text.trim(),
                      'phone': phoneController.text.trim(),
                    };
                    Navigator.of(context).pop(newInfo);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      showLoadingDialog(context);
      try {
        await _fireStoreService.updateUserInfo(
          _authService.getCurrentUserId(),
          result,
        );

        setState(() {
          _work = result['work'] ?? _work;
          _dob = result['dob'] ?? _dob;
          _address = result['address'] ?? _address;
          _phone = result['phone'] ?? _phone;
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Information updated successfully')),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating information: ${e.toString()}')),
        );
      }
    }
  }
}
