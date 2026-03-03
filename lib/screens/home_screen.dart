import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calculator_screen.dart';
import 'grades_diary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  String username = "Пайдаланушы";
  double gpa4 = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Сессия жоқ. Қайта кіріңіз.');

      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      username = (profile?['full_name'] ?? 'Пайдаланушы').toString();

      final grades = await supabase
          .from('grades')
          .select('percent')
          .eq('user_id', user.id);

      double sum = 0;
      int cnt = 0;
      for (final g in (grades as List)) {
        sum += (g['percent'] as num).toDouble();
        cnt++;
      }
      final gpa100 = cnt == 0 ? 0.0 : sum / cnt;
      gpa4 = (gpa100 / 100.0) * 4.0;

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Қате: $e")));
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

  Future<void> _showLastGradeSnack() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final last = await supabase
          .from('grades')
          .select('date, percent, subject_id')
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (last == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Бағалар табылмады")));
        return;
      }

      final subjectId = last['subject_id'];
      final percent = (last['percent'] as num).toDouble();
      final date = last['date'].toString();

      final subj = await supabase
          .from('subjects')
          .select('name')
          .eq('id', subjectId)
          .maybeSingle();
      final subjectName = (subj?['name'] ?? 'Пән').toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Соңғы баға: ${percent.toStringAsFixed(2)}% ($subjectName) — $date",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Қате: $e")));
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
                          ),
                        ),
                        SizedBox(width: 10 * scaleW),
                        Text(
                          "Қазіргі GPA: ${gpa4.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20 * scaleW,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Montserrat',
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GradesDiaryScreen(),
                        ),
                      ),
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 25 * scaleH),
                    _buildMainButton(
                      text: "Емтиханда алу\nкерек бағаны\nесептеу",
                      icon: Icons.calculate,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalculatorScreen(initialTab: 1),
                        ),
                      ),
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 25 * scaleH),
                    _buildMainButton(
                      text: "Соңғы алынған\nбаға",
                      icon: Icons.grade,
                      onPressed: _showLastGradeSnack,
                      scaleW: scaleW,
                      scaleH: scaleH,
                    ),
                    SizedBox(height: 40 * scaleH),
                  ],
                ),
              ),
      ),
    );
  }
}
