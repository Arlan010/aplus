import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  bool isLoading = true;
  double gpa100 = 0;
  double gpa4 = 0;
  List<Map<String, dynamic>> subjects = [];

  final TextEditingController desiredGradeController = TextEditingController();
  String selectedSubject = "";
  String calculatedExamGrade = "-";

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _fetchSubjectsAndGPA();
  }

  Future<void> _fetchSubjectsAndGPA() async {
    try {
      setState(() => isLoading = true);

      final gradesUrl = Uri.parse('http://10.0.2.2:3001/grades/${widget.email}');
      final gradesResponse = await http.get(gradesUrl);

      final gpaUrl = Uri.parse('http://10.0.2.2:3001/grades/gpa/${widget.email}');
      final gpaResponse = await http.get(gpaUrl);

      if (gradesResponse.statusCode == 200 && gpaResponse.statusCode == 200) {
        final List<dynamic> gradesData = jsonDecode(gradesResponse.body);
        final gpaData = jsonDecode(gpaResponse.body);

        setState(() {
          subjects = gradesData.map((subj) {
            return {
              "subject": subj["subject"],
              "grades": subj["grades"]
                  .map((g) => {"date": g["date"], "grade": g["grade"]})
                  .toList(),
            };
          }).toList();

          if (subjects.isNotEmpty) {
            selectedSubject = subjects.first["subject"];
          }

          gpa100 = double.tryParse(gpaData["gpa100"].toString()) ?? 0.0;
          gpa4 = double.tryParse(gpaData["gpa4"].toString()) ?? 0.0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  Future<void> _calculateRequiredScore() async {
    final desiredText = desiredGradeController.text;
    if (desiredText.isEmpty || selectedSubject.isEmpty) return;

    try {
      final url = Uri.parse('http://10.0.2.2:3001/grades/required-score');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": widget.email,
          "subject": selectedSubject,
          "targetAverage": double.tryParse(desiredText),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          calculatedExamGrade = data["requiredScore"].toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(email: widget.email)),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GradesDiaryScreen(email: widget.email)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(email: widget.email)),
        );
        break;
    }
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
  return isLoading
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: EdgeInsets.symmetric(vertical: 50 * scaleH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...subjects.map((entry) {
                double avg = 0;
                if (entry["grades"].isNotEmpty) {
                  avg = entry["grades"]
                          .map((g) => g["grade"] as num)
                          .reduce((a, b) => a + b) /
                      entry["grades"].length;
                }

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
                        entry["subject"],
                        style: TextStyle(
                          fontSize: 16 * scaleW,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        avg.toStringAsFixed(1),
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

              SizedBox(height: 25 * scaleH),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GradesDiaryScreen(email: widget.email),
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

              SizedBox(height: 35 * scaleH),

              Text(
                "Орташа GPA (4.0): ${gpa4.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 22 * scaleW,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),

              SizedBox(height: 25 * scaleH),

              SizedBox(
                width: 180 * scaleW,
                height: 50 * scaleH,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100 * scaleW),
                    ),
                  ),
                  onPressed: _fetchSubjectsAndGPA,
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
          ),
        );
}



  Widget _buildExamCalculator(double scaleW, double scaleH) {
  return isLoading
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: EdgeInsets.symmetric(vertical: 60 * scaleH),
          child: Column(
            children: [
              SizedBox(
                width: 327 * scaleW,
                height: 48 * scaleH,
                child: TextField(
                  controller: desiredGradeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Қалаған орташа баға",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleW),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 25 * scaleH),

              SizedBox(
                width: 327 * scaleW,
                height: 48 * scaleH,
                child: DropdownButtonFormField<String>(
                  value: selectedSubject.isNotEmpty ? selectedSubject : null,
                  decoration: InputDecoration(
                    labelText: "Пән",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleW),
                    ),
                  ),
                  items: subjects
                      .map<DropdownMenuItem<String>>((sub) =>
                          DropdownMenuItem<String>(
                            value: sub["subject"] as String,
                            child: Text(sub["subject"] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedSubject = value!);
                  },
                ),
              ),

              SizedBox(height: 30 * scaleH),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GradesDiaryScreen(email: widget.email),
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

              SizedBox(height: 30 * scaleH),

              Text(
                "Емтиханда $calculatedExamGrade балл жинау керек",
                style: TextStyle(
                  fontSize: 20 * scaleW,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30 * scaleH),

              SizedBox(
                width: 180 * scaleW,
                height: 50 * scaleH,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100 * scaleW),
                    ),
                  ),
                  onPressed: _calculateRequiredScore,
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
          flexibleSpace: Padding(
            padding: EdgeInsets.only(top: 45 * scaleH, bottom: 10 * scaleH),
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
