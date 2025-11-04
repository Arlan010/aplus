import 'package:flutter/material.dart';
import 'grades_diary_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final int initialTab;
  final String email;

  const CalculatorScreen({super.key, this.initialTab = 0, required this.email});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int _selectedIndex = 1;
  int _currentTab = 0;
  double gpa = 3.75;

  final TextEditingController desiredGradeController = TextEditingController();

  String selectedExamType = 'Рубежка';
  String selectedSubject = 'Математика';
  String calculatedExamGrade = '-';

  final List<String> examTypes = ['Рубежка', 'Сессия', 'СОР', 'СОЧ'];
  final List<String> subjects = ['Математика', 'Физика', 'Информатика'];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
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
        break;
      case 2:
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GradesDiaryScreen(email: widget.email),
        ),
      );
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

  void _calculateGPA() {
    setState(() {
      gpa = 3.92;
    });
  }

  void _calculateExamGrade() {
    setState(() {
      calculatedExamGrade = '85';
    });
  }

  Widget _buildSwitchButton({
    required String text,
    required bool active,
    required VoidCallback onTap,
    required double scaleW,
    required double scaleH,
  }) {
    return SizedBox(
      width: 175 * scaleW,
      height: 40 * scaleH,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              active ? const Color(0xFF006FFD) : const Color(0xFFF0F0F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100 * scaleW),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17.5 * scaleW,
            fontWeight: FontWeight.w400,
            color: active ? Colors.white : Colors.black,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildGpaCalculator(double scaleW, double scaleH) {
    final subjects = {
      'Математика': 95,
      'Физика': 88,
      'Информатика': 92,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 30 * scaleH),

        Column(
          children: subjects.entries.map((entry) {
            return Container(
              width: 327 * scaleW,
              height: 48 * scaleH,
              margin: EdgeInsets.only(bottom: 12 * scaleH),
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleW),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12 * scaleW),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 16 * scaleW,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 16 * scaleW,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 20 * scaleH),

        TextButton(
          onPressed: () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GradesDiaryScreen(email: widget.email),
              ),
            );
          },
          child: Text(
            "Бағаларды өзгерту",
            style: TextStyle(
              fontSize: 20 * scaleW,
              color: const Color(0xFF20409A),
              fontWeight: FontWeight.w400,
              fontFamily: 'Montserrat',
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        SizedBox(height: 20 * scaleH),

        Text(
          "Орташа GPA: ${gpa.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 20 * scaleW,
            fontWeight: FontWeight.w400,
            fontFamily: 'Montserrat',
          ),
        ),

        SizedBox(height: 20 * scaleH),

        SizedBox(
          width: 163.5 * scaleW,
          height: 48 * scaleH,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100 * scaleW),
              ),
            ),
            onPressed: _calculateGPA,
            child: Text(
              "Есептеу",
              style: TextStyle(
                fontSize: 20 * scaleW,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamCalculator(double scaleW, double scaleH) {
    return Column(
      children: [
        SizedBox(height: 30 * scaleH),

        SizedBox(
          width: 327 * scaleW,
          height: 48 * scaleH,
          child: TextField(
            controller: desiredGradeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Қалаған баға",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scaleW),
              ),
            ),
          ),
        ),

        SizedBox(height: 20 * scaleH),

        SizedBox(
          width: 327 * scaleW,
          height: 48 * scaleH,
          child: DropdownButtonFormField<String>(
            value: selectedExamType,
            decoration: InputDecoration(
              labelText: "Емтихан түрі",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scaleW),
              ),
            ),
            items: examTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => selectedExamType = value!);
            },
          ),
        ),

        SizedBox(height: 20 * scaleH),

        SizedBox(
          width: 327 * scaleW,
          height: 48 * scaleH,
          child: DropdownButtonFormField<String>(
            value: selectedSubject,
            decoration: InputDecoration(
              labelText: "Пән",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scaleW),
              ),
            ),
            items: subjects
                .map((sub) => DropdownMenuItem(
                      value: sub,
                      child: Text(sub),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => selectedSubject = value!);
            },
          ),
        ),

        SizedBox(height: 25 * scaleH),

        TextButton(
          onPressed: () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GradesDiaryScreen(email: widget.email),
              ),
            );
          },
          child: Text(
            "Бағаларды өзгерту",
            style: TextStyle(
              fontSize: 20 * scaleW,
              color: const Color(0xFF20409A),
              decoration: TextDecoration.underline,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        SizedBox(height: 20 * scaleH),

        Text(
          "Емтиханда $calculatedExamGrade балл жинау керек",
          style: TextStyle(
            fontSize: 20 * scaleW,
            fontWeight: FontWeight.w400,
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 20 * scaleH),

        SizedBox(
          width: 163.5 * scaleW,
          height: 48 * scaleH,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100 * scaleW),
              ),
            ),
            onPressed: _calculateExamGrade,
            child: Text(
              "Есептеу",
              style: TextStyle(
                fontSize: 20 * scaleW,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ],
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
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
              top: 45 * scaleH,
              bottom: 10 * scaleH,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSwitchButton(
                  text: "Орташа GPA",
                  active: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                  scaleW: scaleW,
                  scaleH: scaleH,
                ),
                SizedBox(width: 10 * scaleW),
                _buildSwitchButton(
                  text: "Емтихан",
                  active: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                  scaleW: scaleW,
                  scaleH: scaleH,
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16 * scaleW),
            child: _currentTab == 0
                ? _buildGpaCalculator(scaleW, scaleH)
                : _buildExamCalculator(scaleW, scaleH),
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
            BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Калькулятор"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Дневник"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}
