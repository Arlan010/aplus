// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'root_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final supabase = Supabase.instance.client;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  String selectedSystem = '100';

  String? validatePassword(String password) {
    if (password.length < 8) return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
    if (!RegExp(r'[A-Z]').hasMatch(password))
      return 'Құпиясөзде кемінде бір бас әріп болуы керек';
    if (!RegExp(r'[a-z]').hasMatch(password))
      return 'Құпиясөзде кемінде бір кіші әріп болуы керек';
    if (!RegExp(r'\d').hasMatch(password))
      return 'Құпиясөзде кемінде бір сан болуы керек';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password))
      return 'Құпиясөзде кемінде бір арнайы таңба болуы керек';
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Қате',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> registerUser() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passController.text;
    final confirmPassword = confirmPassController.text;

    if (fullName.isEmpty) return _showErrorDialog('Аты-жөніңізді енгізіңіз');
    if (email.isEmpty) return _showErrorDialog('Email енгізіңіз');

    if (password != confirmPassword) {
      _showErrorDialog('Құпиясөздер сәйкес келмейді');
      return;
    }

    final validationError = validatePassword(password);
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await supabase.auth.signUp(email: email, password: password);

      final user = res.user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Поштаға растау хаты жіберілді. Email-ді тексеріңіз.',
            ),
          ),
        );
        return;
      }

      await supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'grading_view': selectedSystem,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Тіркелу сәтті өтті')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog('Қате: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
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
              _buildTextField(
                emailController,
                'Электрондық пошта',
                scaleW,
                scaleH,
              ),

              SizedBox(height: 20 * scaleH),

              _buildLabel('Құпиясөз', scaleW),
              SizedBox(height: 6 * scaleH),
              _buildPasswordField(
                controller: passController,
                hintText: 'Құпиясөз',
                obscureText: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
                onToggle: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                scaleW: scaleW,
                scaleH: scaleH,
              ),

              SizedBox(height: 20 * scaleH),

              _buildLabel('Баға жүйесі', scaleW),
              SizedBox(height: 6 * scaleH),
              SizedBox(
                width: 327 * scaleW,
                height: 48 * scaleH,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSystem,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleW),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10 * scaleH,
                      horizontal: 20 * scaleW,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '100',
                      child: Text(
                        '100 баллдық жүйе',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16 * scaleW,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '5',
                      child: Text(
                        '5 баллдық жүйе',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16 * scaleW,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedSystem = value ?? '100'),
                ),
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
                  onPressed: _loading ? null : registerUser,
                  child: Text(
                    _loading ? 'Күтіңіз...' : 'Тіркелу',
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    double scaleW,
    double scaleH,
  ) {
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
          contentPadding: EdgeInsets.symmetric(
            vertical: 15 * scaleH,
            horizontal: 20 * scaleW,
          ),
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
          contentPadding: EdgeInsets.symmetric(
            vertical: 15 * scaleH,
            horizontal: 20 * scaleW,
          ),
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
