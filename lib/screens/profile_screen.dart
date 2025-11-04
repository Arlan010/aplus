import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'calculator_screen.dart';
import 'grades_diary_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();

  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3001/user/${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _gpaController.text = data['gpa']?.toString() ?? '3.78';
          _isLoading = false;
        });
      } else {
        throw Exception('Қате: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3001/user/${widget.email}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': _nameController.text,
          'newEmail': _emailController.text,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Сәтті жаңартылды ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Қате')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Құпиясөзді өзгерту"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ескі құпиясөз'),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Жаңа құпиясөз'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Болдырмау"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2DDBD2)),
            child: const Text("Сақтау"),
            onPressed: () async {
              final response = await http.put(
                Uri.parse('http://10.0.2.2:3001/user/${widget.email}/password'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'oldPassword': oldPassController.text,
                  'newPassword': newPassController.text,
                }),
              );

              final result = jsonDecode(response.body);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'Қате')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(email: widget.email),
        ),
      );
        break;
      case 1:
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalculatorScreen(email: widget.email),
        ),
      );
        break;
      case 2:
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GradesDiaryScreen(email: widget.email),
          ),
        );
        break;
    }
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditPressed,
    required double scaleW,
    required double scaleH,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * scaleH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8 * scaleW, bottom: 6 * scaleH),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16 * scaleW,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 55 * scaleH,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(12 * scaleW),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: !isEditing,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * scaleW,
                        vertical: 14 * scaleH,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16 * scaleW,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.check_circle : Icons.edit,
                    color: isEditing
                        ? const Color(0xFF2DDBD2)
                        : const Color(0xFF20409A),
                    size: 25 * scaleW,
                  ),
                  onPressed: onEditPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    const baseW = 412;
    const baseH = 917;
    final scaleW = screenW / baseW;
    final scaleH = screenH / baseH;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 100 * scaleH),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFF8F9FE),
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24 * scaleW),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20 * scaleH),
            CircleAvatar(
              radius: 50 * scaleW,
              backgroundColor: const Color(0xFF2DDBD2),
              child: Icon(Icons.person, size: 60 * scaleW, color: Colors.white),
            ),
            SizedBox(height: 25 * scaleH),
            _buildEditableField(
              label: "Аты-жөніңіз",
              controller: _nameController,
              isEditing: _isEditingName,
              onEditPressed: () {
                setState(() => _isEditingName = !_isEditingName);
              },
              scaleW: scaleW,
              scaleH: scaleH,
            ),
            _buildEditableField(
              label: "Электрондық пошта",
              controller: _emailController,
              isEditing: _isEditingEmail,
              onEditPressed: () {
                setState(() => _isEditingEmail = !_isEditingEmail);
              },
              scaleW: scaleW,
              scaleH: scaleH,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15 * scaleH),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text("Құпиясөзді өзгерту"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20409A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100 * scaleW),
                  ),
                ),
                onPressed: _showChangePasswordDialog,
              ),
            ),
            SizedBox(height: 20 * scaleH),
            SizedBox(
              width: 250 * scaleW,
              height: 55 * scaleH,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DDBD2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100 * scaleW),
                  ),
                ),
                child: Text(
                  "Сақтау",
                  style: TextStyle(
                    fontSize: 20 * scaleW,
                    fontFamily: 'Montserrat',
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 50 * scaleH),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 105 * scaleH,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFF8F9FE),
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF006FFD),
          unselectedItemColor: Colors.grey,
          iconSize: 30 * scaleW,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Басты бет"),
            BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Калькулятор"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Дневник"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}