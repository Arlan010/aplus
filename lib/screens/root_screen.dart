import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'calculator_screen.dart';
import 'grades_diary_screen.dart';
import 'profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  void _setTab(int i) => setState(() => _index = i);

  late final List<Widget> _pages = [
    HomeScreen(onTabChange: _setTab),
    const CalculatorScreen(),
    const GradesDiaryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF8F9FE),
        selectedItemColor: const Color(0xFF006FFD),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Басты бет"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: "Калькулятор",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Дневник"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
        ],
      ),
    );
  }
}
