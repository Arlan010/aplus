import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calculator_screen.dart';
import 'profile_screen.dart';

class GradesDiaryScreen extends StatefulWidget {
  final String email;

  const GradesDiaryScreen({super.key, required this.email});

  @override
  State<GradesDiaryScreen> createState() => _GradesDiaryScreenState();
}

class _GradesDiaryScreenState extends State<GradesDiaryScreen> {
  int _selectedIndex = 2;

  Map<String, List<Map<String, String>>> grades = {
    "Математика": [
      {"date": "15.09.2025", "grade": "90"},
      {"date": "20.09.2025", "grade": "85"},
    ],
    "Физика": [
      {"date": "16.09.2025", "grade": "88"},
      {"date": "23.09.2025", "grade": "92"},
    ],
  };

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
        break;
      case 3:
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(email: widget.email),
        ),
      );
        break;
    }
  }

  void _addSubjectDialog(double scaleW, double scaleH) {
    final TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Жаңа пән қосу"),
        content: TextField(
          controller: subjectController,
          decoration: const InputDecoration(
            hintText: "Пән атауы",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Болдырмау"),
          ),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isNotEmpty) {
                setState(() {
                  grades[subjectController.text] = [];
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DDBD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleW),
              ),
            ),
            child: const Text("Қосу", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _addGrade(String subject) {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$subject пәніне баға қосу"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Күні (мысалы: 21.10.2025)"),
            ),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Баға"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Болдырмау"),
          ),
          ElevatedButton(
            onPressed: () {
              if (dateController.text.isNotEmpty &&
                  gradeController.text.isNotEmpty) {
                setState(() {
                  grades[subject]?.add({
                    "date": dateController.text,
                    "grade": gradeController.text
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DDBD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Қосу", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTable(String subject, List<Map<String, String>> subjectGrades,
      double scaleW, double scaleH) {
    return Container(
      margin: EdgeInsets.only(bottom: 20 * scaleH),
      padding: EdgeInsets.all(16 * scaleW),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scaleW),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6 * scaleW,
            offset: Offset(0, 3 * scaleH),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 20 * scaleW,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => _addGrade(subject),
                icon: const Icon(Icons.add_circle, color: Color(0xFF2DDBD2)),
                iconSize: 30 * scaleW,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 80 * scaleW,
                      height: 35 * scaleH,
                      alignment: Alignment.center,
                      color: const Color(0xFFF8F9FE),
                      child: const Text("Дата"),
                    ),
                    Container(
                      width: 80 * scaleW,
                      height: 35 * scaleH,
                      alignment: Alignment.center,
                      color: const Color(0xFFF8F9FE),
                      child: const Text("Баға"),
                    ),
                  ],
                ),
                Row(
                  children: subjectGrades.map((entry) {
                    return Column(
                      children: [
                        Container(
                          width: 80 * scaleW,
                          height: 35 * scaleH,
                          alignment: Alignment.center,
                          child: Text(entry["date"] ?? ""),
                        ),
                        Container(
                          width: 80 * scaleW,
                          height: 35 * scaleH,
                          alignment: Alignment.center,
                          child: Text(entry["grade"] ?? ""),
                        ),
                      ],
                    );
                  }).toList(),
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
        padding: EdgeInsets.all(16 * scaleW),
        child: Column(
          children: [
            ...grades.entries.map((entry) {
              return _buildSubjectTable(
                entry.key,
                entry.value,
                scaleW,
                scaleH,
              );
            }),
            SizedBox(height: 10 * scaleH),
            TextButton(
              onPressed: () => _addSubjectDialog(scaleW, scaleH),
              child: Text(
                "+ Пән қосу",
                style: TextStyle(
                  fontSize: 18 * scaleW,
                  color: const Color(0xFF2DDBD2),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
