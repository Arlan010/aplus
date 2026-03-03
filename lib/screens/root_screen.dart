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

  final _pages = const [
    HomeScreen(),
    CalculatorScreen(),
    GradesDiaryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF8F9FE),
        currentIndex: _index,
        selectedItemColor: const Color(0xFF006FFD),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
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
