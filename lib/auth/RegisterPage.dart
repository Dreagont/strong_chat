import 'package:flutter/material.dart';
import '../services/AuthService.dart';
import 'LoginPage.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
      {
        registrationSuccess = await _authService.createUserWithEmailAndPasswordVerify(email, password, name, work, dob, address, phone) != null;
        if (registrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('A verification email has been sent to your email. Please verify to continue.')),
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
        _dobController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year.toString().substring(2)}";
      });
    }
  }

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;


  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onTap,
    bool? isPassword,
    bool? isConfirmPassword,
    int? maxLength = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        absorbing: onTap != null,
        child: TextField(
          maxLength: maxLength,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword == true
              ? !_isPasswordVisible
              : isConfirmPassword == true
              ? !_isPasswordVisible
              : obscureText,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: (isPassword == true || isConfirmPassword == true)
                ? IconButton(
              icon: Icon(
                ((_isPasswordVisible == true)
                    ? Icons.visibility
                    : Icons.visibility_off),
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  if (isPassword == true) {
                    _isPasswordVisible = !_isPasswordVisible;
                  } else {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  }
                });
              },
            )
                : null,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return _buildMobileLayout();
          } else {
            return _buildWebLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          SizedBox(height: 20),
          Text(
            'Register Page',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            hintText: 'Name',
            icon: Icons.person,
          ),
          SizedBox(height: 10),
          _buildTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 10),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          SizedBox(height: 10),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock,
            isConfirmPassword: true,
          ),
          SizedBox(height: 20),
          ExpansionTile(
            title: Text("Show additional information", style: TextStyle(color: Colors.blueAccent),),
            collapsedIconColor: Colors.blueAccent,
            children: [
              _buildTextField(
                controller: _workController,
                hintText: 'Work',
                icon: Icons.work,
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _dobController,
                hintText: 'Date of Birth',
                icon: Icons.calendar_today,
                onTap: () => _selectDateOfBirth(context),
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _addressController,
                hintText: 'Address',
                icon: Icons.location_on,
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 10
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _register,
            child: Text('Register', style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              textStyle: TextStyle(fontSize: 16),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Already have an account? Login', style: TextStyle(color: Colors.blueAccent),),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: Container(
        width: 500,
        height: 700,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            SizedBox(height: 20),
            Text(
              'Register Page',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              hintText: 'Name',
              icon: Icons.person,
            ),
            SizedBox(height: 10),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            SizedBox(height: 10),
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              icon: Icons.lock,
              isConfirmPassword: true,
            ),
            SizedBox(height: 20),
            ExpansionTile(
              title: Text("Show additional information", style: TextStyle(color: Colors.blueAccent),),
              collapsedIconColor: Colors.blueAccent,
              children: [
                _buildTextField(
                  controller: _workController,
                  hintText: 'Work',
                  icon: Icons.work,
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: _dobController,
                  hintText: 'Date of Birth',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDateOfBirth(context),
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Address',
                  icon: Icons.location_on,
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register', style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Already have an account? Login', style: TextStyle(color: Colors.blueAccent),),
            ),
          ],
        ),
      ),
    );
  }
}
