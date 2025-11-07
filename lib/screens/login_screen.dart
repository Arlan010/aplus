import 'package:flutter/material.dart';
import 'package:project050925/screens/register_screen.dart';
import 'package:project050925/screens/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reset_password_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginSelected = true;
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  Future<void> loginUser() async {
    final url = Uri.parse('http://10.0.2.2:3001/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'password': passController.text.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Кіру сәтті өтті!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            email: data['user']['email'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Қате орын алды')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0xFFF4F4F4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState (() {
                          isLoginSelected = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: isLoginSelected
                            ? const Color(0xFF2DDBD2)
                            : const Color(0xFFF4F4F4),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Кіру',
                        style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montserrat',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen()
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: isLoginSelected
                        ? const Color(0xFFF4F4F4)
                        : const Color(0xFF2DDBD2),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Тіркелу',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montserrat',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox (height: 40),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Электрондық пошта',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Электрондық пошта',
            hintStyle: const TextStyle(fontFamily: 'Montserrat'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),

        const SizedBox(height: 20),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Құпиясөз',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Құпиясөз',
            hintStyle: const TextStyle(fontFamily: 'Montserrat'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                  ? Icons.visibility
                  : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 15),

        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ResetPasswordEmailScreen(),
              ),
            );
        },
          child: const Text(
            'Құпиясөзді ұмыттыңыз ба?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              fontFamily: 'Montserrat',
              color: Color(0xFF20409A),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DDBD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: loginUser,
            child: const Text(
              'Кіру',
              style: TextStyle(
                fontSize: 20,
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
);
}
}