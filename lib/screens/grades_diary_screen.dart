import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  String gradingSystem = "100";
  bool isLoading = true;

  Map<String, List<Map<String, dynamic>>> grades = {};

  @override
  void initState() {
    super.initState();
    _fetchUserAndGrades();
  }

  Future<void> _fetchUserAndGrades() async {
    try {
      final userUrl = Uri.parse('http://10.0.2.2:3001/user/${widget.email}');
      final userResponse = await http.get(userUrl);

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        gradingSystem = userData['gradingSystem'] ?? "100";
      }

      final gradesUrl = Uri.parse('http://10.0.2.2:3001/grades/${widget.email}');
      final gradesResponse = await http.get(gradesUrl);

      if (gradesResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(gradesResponse.body);
        Map<String, List<Map<String, dynamic>>> loaded = {};

        for (var subject in data) {
          final subjectName = subject['subject'];
          final subjectGrades = List<Map<String, dynamic>>.from(subject['grades']);
          loaded[subjectName] = subjectGrades;
        }

        setState(() {
          grades = loaded;
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

  Future<void> _addSubjectDialog(double scaleW, double scaleH) async {
    final TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Жаңа пән қосу"),
        content: TextField(
          controller: subjectController,
          decoration: const InputDecoration(hintText: "Пән атауы"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Болдырмау"),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              if (subject.isEmpty) return;

              final url = Uri.parse('http://10.0.2.2:3001/grades/add-subject');
              final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'email': widget.email, 'subject': subject}),
              );

              if (response.statusCode == 200) {
                setState(() {
                  grades[subject] = [];
                });
                Navigator.pop(context);
              } else {
                final err = jsonDecode(response.body)['message'];
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
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
  String selectedType = "regular";
  final types = ["regular", "СОР", "СОЧ", "Рубежка", "Сессия"];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("$subject пәніне баға қосу"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedType,
            items: types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => selectedType = val ?? "regular",
            decoration: const InputDecoration(labelText: "Баға түрі"),
          ),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(
              labelText: "Күні (мысалы: 21.10.2025)",
            ),
          ),
          TextField(
            controller: gradeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: gradingSystem == "5" ? "Баға (1-5)" : "Баға (0-100)",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Болдырмау"),
        ),
        ElevatedButton(
          onPressed: () async {
            final date = dateController.text.trim();
            final gradeText = gradeController.text.trim();
            double? grade = double.tryParse(gradeText);

            if (date.isEmpty || grade == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Деректер дұрыс емес форматта")),
              );
              return;
            }

            final url = Uri.parse('http://10.0.2.2:3001/grades/add-grade');
            final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': widget.email,
                'subject': subject,
                'date': date,
                'grade': grade,
                'type': selectedType,
              }),
            );

            if (response.statusCode == 200) {
              _fetchUserAndGrades();
              Navigator.pop(context);
            } else {
              final err = jsonDecode(response.body)['message'];
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DDBD2),
          ),
          child: const Text("Қосу", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}

void _editOrDeleteGrade(String subject, Map<String, dynamic> gradeData) {
  final TextEditingController gradeController =
      TextEditingController(text: gradeData["grade"].toString());
  final TextEditingController dateController =
      TextEditingController(text: gradeData["date"]);
  String selectedType = gradeData["type"] ?? "regular";
  final types = ["regular", "СОР", "СОЧ", "Рубежка", "Сессия"];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Бағаны өзгерту немесе жою"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedType,
            items: types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => selectedType = val ?? "regular",
            decoration: const InputDecoration(labelText: "Баға түрі"),
          ),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(labelText: "Күні"),
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
          onPressed: () async {
            final url = Uri.parse('http://10.0.2.2:3001/grades/update-grade');
            await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': widget.email,
                'subject': subject,
                'oldDate': gradeData["date"],
                'newDate': dateController.text.trim(),
                'newGrade': double.tryParse(gradeController.text) ?? 0,
                'newType': selectedType,
              }),
            );
            Navigator.pop(context);
            _fetchUserAndGrades();
          },
          child: const Text("Өзгерту"),
        ),
        TextButton(
          onPressed: () async {
            final url = Uri.parse('http://10.0.2.2:3001/grades/delete-grade');
            await http.delete(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': widget.email,
                'subject': subject,
                'date': gradeData["date"],
              }),
            );
            Navigator.pop(context);
            _fetchUserAndGrades();
          },
          child: const Text("Жою", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

  Widget _buildSubjectTable(
      String subject, List<Map<String, dynamic>> subjectGrades, double scaleW, double scaleH) {
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
      style: TextStyle(fontSize: 20 * scaleW, fontWeight: FontWeight.w700),
    ),
    Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Пәнді жою"),
                content: Text("Сенімдісің бе \"$subject\" пәнін жойғың келеді ме?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Жоқ")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Иә")),
                ],
              ),
            );

            if (confirm != true) return;

            final url = Uri.parse('http://10.0.2.2:3001/grades/delete-subject');
            final response = await http.delete(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': widget.email, 'subject': subject}),
            );
            if (response.statusCode == 200) _fetchUserAndGrades();
          },
        ),
        IconButton(
          onPressed: () => _addGrade(subject),
          icon: const Icon(Icons.add_circle, color: Color(0xFF2DDBD2)),
            ),
          ],
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
                          child: Text(entry["date"].toString()),
                        ),
                        Container(
                          width: 80 * scaleW,
                          height: 35 * scaleH,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () => _editOrDeleteGrade(subject, entry),
                            child: Text(entry["grade"].toString(),
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          FutureBuilder(
            future: http.get(Uri.parse(
              'http://10.0.2.2:3001/grades/subject-average/${widget.email}/$subject')),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 20);
              }
              if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                final data = jsonDecode(snapshot.data!.body);
                return Padding(
                  padding: EdgeInsets.only(top: 8 * scaleH),
                  child: Text(
                    "Орташа баға: ${data['average']}",
                    style: TextStyle(
                      fontSize: 16 * scaleW,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  ),
                );
              }
              return const SizedBox.shrink();
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
          MaterialPageRoute(builder: (context) => HomeScreen(email: widget.email)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalculatorScreen(email: widget.email)),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(email: widget.email)),
        );
        break;
    }
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
          centerTitle: true,
          title: Padding(
            padding: EdgeInsets.only(top: 40 * scaleH),
            child: Text(
              "Баға жүйесі: $gradingSystem",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 18 * scaleW,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16 * scaleW),
              child: Column(
                children: [
                  ...grades.entries.map((entry) =>
                      _buildSubjectTable(entry.key, entry.value, scaleW, scaleH)),
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
            BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Калькулятор"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Дневник"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}