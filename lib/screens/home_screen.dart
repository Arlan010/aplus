import 'package:flutter/material.dart';
import 'package:project050925/screens/calculator_screen.dart';
import 'package:project050925/screens/grades_diary_screen.dart';
import 'package:project050925/screens/profile_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String username = "Пайдаланушы";
  double gpa = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// 📦 Получаем имя и текущий GPA
  Future<void> _fetchUserData() async {
    try {
      // Получаем имя
      final userUrl = Uri.parse('http://10.0.2.2:3001/user/${widget.email}');
      final userResponse = await http.get(userUrl);

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        username = userData['full_name'] ?? "Пайдаланушы";
      }

      // Получаем GPA
      final gpaUrl = Uri.parse('http://10.0.2.2:3001/grades/gpa/${widget.email}');
      final gpaResponse = await http.get(gpaUrl);

      if (gpaResponse.statusCode == 200) {
        final gpaData = jsonDecode(gpaResponse.body);
        gpa = double.tryParse(gpaData['gpa4'].toString()) ?? 0.0;
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Қате: $e")));
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CalculatorScreen(email: widget.email)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GradesDiaryScreen(email: widget.email)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileScreen(email: widget.email)),
        );
        break;
    }
  }

  Widget _buildMainButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required double scaleW,
    required double scaleH,
  }) {
    return SizedBox(
      width: 275 * scaleW,
      height: 175 * scaleH,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC5FFF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scaleW),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30 * scaleW, color: Colors.black87),
            SizedBox(height: 10 * scaleH),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * scaleW,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 122.5 * scaleH),
        child: SafeArea(
          child: Container(
            color: const Color(0xFFF8F9FE),
            padding: EdgeInsets.only(
              bottom: 20 * scaleH,
              left: 20 * scaleW,
              right: 20 * scaleW,
            ),
            alignment: Alignment.bottomCenter,
            child: isLoading
                ? const CircularProgressIndicator()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Сәлем, $username!",
                          style: TextStyle(
                            fontSize: 20 * scaleW,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10 * scaleW),
                        Text(
                          "Қазіргі GPA: ${gpa.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20 * scaleW,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMainButton(
                      text: "Баға қосу",
                      icon: Icons.add,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  GradesDiaryScreen(email: widget.email)),
                        );
                      },
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 25 * scaleH),
                    _buildMainButton(
                      text: "Емтиханда алу\nкерек бағаны\nесептеу",
                      icon: Icons.calculate,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CalculatorScreen(
                                  initialTab: 1, email: widget.email)),
                        );
                      },
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 25 * scaleH),
                    _buildMainButton(
                      text: "Соңғы алынған\nбаға",
                      icon: Icons.grade,
                      onPressed: () async {
                        try {
                          final url = Uri.parse(
                              'http://10.0.2.2:3001/grades/last/${widget.email}');
                          final response = await http.get(url);

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            if (data['grade'] != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Соңғы баға: ${data['grade']} (${data['subject']}) — ${data['date']}",
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Бағалар табылмады")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Қате орын алды")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Қате: $e")),
                          );
                        }
                      },
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 40 * scaleH),
                  ],
                ),
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
            BottomNavigationBarItem(
                icon: Icon(Icons.calculate), label: "Калькулятор"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Дневник"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}