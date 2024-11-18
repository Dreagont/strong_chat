import 'package:flutter/material.dart';
import '../pages/HomePage.dart';
import '../services/AuthService.dart';
import 'RegisterPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Logging in..."),
          ],
        ),
      ),
    );

    await Future.delayed(Duration(seconds: 1));

    final user = await _authService.loginUserWithEmailAndPassword(email, password);

    Navigator.pop(context);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(id: user.uid)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed')));
    }
  }

  void _quickLogin(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    _login();
  }

  void _forgotPassword() async {
    final emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Forgot Password'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
              child: Text('Send Reset Link'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Sending reset link..."),
            ],
          ),
        ),
      );

      try {
        await _authService.sendPasswordResetEmail(result);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $result')),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _quickLogin('hehe@gmail.com', '123456'),
                  child: Text('Quick Login hehe'),
                ),
                ElevatedButton(
                  onPressed: () => _quickLogin('huynhannguyen222@gmail.com', '123456'),
                  child: Text('Quick Login nguyen222'),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('Register'),
            ),
            TextButton(
              onPressed: _forgotPassword,
              child: Text('Forgot Password'),
            ),
          ],
        ),
      ),
    );
  }
}
