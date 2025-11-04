import 'package:flutter/material.dart';
import 'package:project050925/screens/login_screen.dart';
import 'package:project050925/screens/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Құпиясөзде кемінде бір бас әріп болуы керек';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Құпиясөзде кемінде бір кіші әріп болуы керек';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Құпиясөзде кемінде бір сан болуы керек';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Құпиясөзде кемінде бір арнайы таңба болуы керек';
    }
    return null;
  }

  Future<void> registerUser() async {
    final password = passController.text;
    final confirmPassword = confirmPassController.text;

    if (password != confirmPassword) {
      _showErrorDialog('Құпиясөздер сәйкес келмейді');
      return;
    }

    final validationError = validatePassword(password);
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    final url = Uri.parse('http://localhost:3001/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': nameController.text,
        'email': emailController.text,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тіркелу сәтті өтті')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(email: emailController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: ${response.body}')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Қате',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 412;
    const baseHeight = 917;

    final scaleW = screenWidth / baseWidth;
    final scaleH = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * scaleW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60 * scaleH),

              Container(
                width: 327 * scaleW,
                height: 60 * scaleH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100 * scaleW),
                  color: const Color(0xFFF4F4F4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100 * scaleW),
                            color: const Color(0xFFF4F4F4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Кіру',
                            style: TextStyle(
                              fontSize: 18 * scaleW,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Montserrat',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100 * scaleW),
                          color: const Color(0xFF2DDBD2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Тіркелу',
                          style: TextStyle(
                            fontSize: 18 * scaleW,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40 * scaleH),

              _buildLabel('Аты-жөніңіз', scaleW),
              SizedBox(height: 6 * scaleH),
              _buildTextField(nameController, 'Аты-жөніңіз', scaleW, scaleH),

              SizedBox(height: 20 * scaleH),

              _buildLabel('Электрондық пошта', scaleW),
              SizedBox(height: 6 * scaleH),
              _buildTextField(emailController, 'Электрондық пошта', scaleW, scaleH),

              SizedBox(height: 20 * scaleH),

              _buildLabel('Құпиясөз', scaleW),
              SizedBox(height: 6 * scaleH),
              _buildPasswordField(
                controller: passController,
                hintText: 'Құпиясөз',
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                scaleW: scaleW,
                scaleH: scaleH,
              ),

              SizedBox(height: 20 * scaleH),

              _buildLabel('Құпиясөзді растау', scaleW),
              SizedBox(height: 6 * scaleH),
              _buildPasswordField(
                controller: confirmPassController,
                hintText: 'Құпиясөзді растау',
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                scaleW: scaleW,
                scaleH: scaleH,
              ),

              SizedBox(height: 40 * scaleH),

              SizedBox(
                width: 325 * scaleW,
                height: 60 * scaleH,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DDBD2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100 * scaleW),
                    ),
                  ),
                  onPressed: registerUser,
                  child: Text(
                    'Тіркелу',
                    style: TextStyle(
                      fontSize: 20 * scaleW,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Montserrat',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30 * scaleH),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, double scaleW) {
    return Padding(
      padding: EdgeInsets.only(left: 18 * scaleW),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16 * scaleW,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, double scaleW, double scaleH) {
    return SizedBox(
      width: 327 * scaleW,
      height: 48 * scaleH,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scaleW),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15 * scaleH, horizontal: 20 * scaleW),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    required double scaleW,
    required double scaleH,
  }) {
    return SizedBox(
      width: 327 * scaleW,
      height: 48 * scaleH,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scaleW),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15 * scaleH, horizontal: 20 * scaleW),
          suffixIcon: IconButton(
            iconSize: 25 * scaleW,
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}