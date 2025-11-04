import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reset_password_code_screen.dart';

class ResetPasswordEmailScreen extends StatefulWidget {
  const ResetPasswordEmailScreen({super.key});

  @override
  State<ResetPasswordEmailScreen> createState() => _ResetPasswordEmailScreenState();
}

class _ResetPasswordEmailScreenState extends State<ResetPasswordEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendResetCode() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://10.0.2.2:3001/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailController.text.trim()}),
    );

    setState(() => isLoading = false);

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Код жіберілді')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordCodeScreen(email: emailController.text.trim()),
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
      appBar: AppBar(title: const Text('Құпиясөзді қалпына келтіру')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Электрондық поштаңызды енгізіңіз'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : sendResetCode,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Код жіберу'),
            ),
          ],
        ),
      ),
    );
  }
}
