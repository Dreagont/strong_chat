import 'package:flutter/material.dart';
import '../pages/HomePage.dart';
import '../services/AuthService.dart';
import 'LoginPage.dart'; // Import your login page

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isEmailVerificationRequired = false;

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();
    final work = _workController.text.trim().isEmpty ? 'unknown' : _workController.text.trim();
    final dob = _dobController.text.trim().isEmpty ? 'unknown' : _dobController.text.trim();
    final address = _addressController.text.trim().isEmpty ? 'unknown' : _addressController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? 'unknown' : _phoneController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phone) && phone != 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone number must be digits')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    bool registrationSuccess = false;
    try {
      if (isEmailVerificationRequired) {
        registrationSuccess = await _authService.createUserWithEmailAndPasswordVerify(email, password, name, work, dob, address, phone) != null;
        if (registrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('A verification email has been sent to your email. Please verify to continue.')),
          );
        }
      } else {
        registrationSuccess = await _authService.createUserWithEmailAndPassword(email, password, name, work, dob, address, phone) != null;
        if (registrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful. Account activated without email verification.')),
          );
        }
      }
    } finally {
      Navigator.of(context).pop();
    }

    if (registrationSuccess) {
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed')));
    }
  }


  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _dobController.text = "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year.toString().substring(2)}"; // dd/mm/yy format
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            // Additional information section with ExpansionTile
            ExpansionTile(
              title: Text("Show additional information"),
              children: [
                TextField(
                  controller: _workController,
                  decoration: InputDecoration(labelText: 'Work'),
                ),
                GestureDetector(
                  onTap: () => _selectDateOfBirth(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'Tap to select date',
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            CheckboxListTile(
              title: Text("Require email verification"),
              value: isEmailVerificationRequired,
              onChanged: (bool? value) {
                setState(() {
                  isEmailVerificationRequired = value ?? false;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
