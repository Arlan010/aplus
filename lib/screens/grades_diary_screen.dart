import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GradesDiaryScreen extends StatefulWidget {
  const GradesDiaryScreen({super.key});

  @override
  State<GradesDiaryScreen> createState() => _GradesDiaryScreenState();
}

class _GradesDiaryScreenState extends State<GradesDiaryScreen> {
  final supabase = Supabase.instance.client;

  String gradingSystem = '100';
  bool isLoading = true;

  Map<String, Map<String, dynamic>> subjects = {};

  @override
  void initState() {
    super.initState();
    _fetchUserAndGrades();
  }

  Future<void> _fetchUserAndGrades() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Сессия жоқ. Қайта кіріңіз.');

      final profile = await supabase
          .from('profiles')
          .select('grading_view')
          .eq('id', user.id)
          .maybeSingle();

      gradingSystem = (profile?['grading_view'] ?? '100').toString();

      final subjectsRows = await supabase
          .from('subjects')
          .select('id, name')
          .eq('user_id', user.id)
          .order('name');

      final Map<String, Map<String, dynamic>> loaded = {};
      for (final s in (subjectsRows as List)) {
        loaded[s['name'].toString()] = {
          'id': s['id'],
          'grades': <Map<String, dynamic>>[],
        };
      }

      final gradesRows = await supabase
          .from('grades')
          .select('id, subject_id, date, percent, type')
          .eq('user_id', user.id)
          .order('date');

      for (final g in (gradesRows as List)) {
        final subjectId = g['subject_id'];
        final entry = loaded.entries.firstWhere(
          (e) => e.value['id'] == subjectId,
          orElse: () => const MapEntry('', {}),
        );

        if (entry.key.isNotEmpty) {
          (entry.value['grades'] as List<Map<String, dynamic>>).add({
            'id': g['id'],
            'date': g['date'].toString(),
            'percent': (g['percent'] as num).toDouble(),
            'type': (g['type'] ?? 'regular').toString(),
          });
        }
      }

      if (!mounted) return;
      setState(() {
        subjects = loaded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Қате: $e')));
    }
  }

  double _avg(List<Map<String, dynamic>> gs) {
    if (gs.isEmpty) return 0;
    double sum = 0;
    for (final g in gs) {
      sum += (g['percent'] as double);
    }
    return sum / gs.length;
  }

  String _toDisplayGrade(double percent) {
    if (gradingSystem == '5') {
      if (percent >= 90) return '5';
      if (percent >= 75) return '4';
      if (percent >= 60) return '3';
      return '2';
    }
    return percent.toStringAsFixed(1);
  }

  Future<void> _addSubjectDialog(double scaleW, double scaleH) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Жаңа пән қосу'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Пән атауы'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                await supabase.from('subjects').insert({
                  'user_id': user.id,
                  'name': name,
                });

                if (!mounted) return;
                navigator.pop();
                await _fetchUserAndGrades();
              } on PostgrestException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Қате: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DDBD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleW),
              ),
            ),
            child: const Text('Қосу', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(String subjectName) async {
    final subjectId = subjects[subjectName]?['id'];
    if (subjectId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Пәнді жою'),
        content: Text('"$subjectName" пәнін шынымен жойғыңыз келе ме?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await supabase.from('subjects').delete().eq('id', subjectId);
    await _fetchUserAndGrades();
  }

  Future<void> _addGrade(String subjectName) async {
    final dateController = TextEditingController();
    final gradeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String selectedType = 'regular';
    final types = ['regular', 'СОР', 'СОЧ', 'Рубежка', 'Сессия'];

    final subjectId = subjects[subjectName]?['id'];
    if (subjectId == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$subjectName пәніне баға қосу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => selectedType = val ?? 'regular',
              decoration: const InputDecoration(labelText: 'Баға түрі'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Күні (YYYY-MM-DD)'),
            ),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: gradingSystem == '5' ? 'Баға (2-5)' : 'Баға (0-100)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                final dateText = dateController.text.trim();
                if (dateText.isEmpty) {
                  throw Exception('Күнді енгізіңіз (YYYY-MM-DD)');
                }

                final v = double.tryParse(gradeController.text.trim());
                if (v == null) throw Exception('Баға дұрыс емес');

                double percent;
                if (gradingSystem == '5') {
                  final intV = v.round();
                  if (intV < 2 || intV > 5) {
                    throw Exception('5 балдық жүйеде 2-5 аралығы');
                  }
                  percent = intV == 5
                      ? 95
                      : intV == 4
                      ? 80
                      : intV == 3
                      ? 65
                      : 50;
                } else {
                  if (v < 0 || v > 100) {
                    throw Exception('100 балдық жүйеде 0-100 аралығы');
                  }
                  percent = v;
                }

                await supabase.from('grades').insert({
                  'user_id': user.id,
                  'subject_id': subjectId,
                  'date': dateText,
                  'percent': percent,
                  'type': selectedType,
                });

                if (!mounted) return;
                navigator.pop();
                await _fetchUserAndGrades();
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Қате: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DDBD2),
            ),
            child: const Text('Қосу', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _editOrDeleteGrade(
    String subjectName,
    Map<String, dynamic> g,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final gradeController = TextEditingController(
      text: _toDisplayGrade(g['percent'] as double),
    );
    final dateController = TextEditingController(text: g['date'].toString());
    String selectedType = (g['type'] ?? 'regular').toString();
    final types = ['regular', 'СОР', 'СОЧ', 'Рубежка', 'Сессия'];

    final gradeId = g['id'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Бағаны өзгерту немесе жою'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => selectedType = val ?? 'regular',
              decoration: const InputDecoration(labelText: 'Баға түрі'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Күні (YYYY-MM-DD)'),
            ),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Баға'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final dateText = dateController.text.trim();
                if (dateText.isEmpty) throw Exception('Күн бос');

                final v = double.tryParse(gradeController.text.trim());
                if (v == null) throw Exception('Баға дұрыс емес');

                double percent;
                if (gradingSystem == '5') {
                  final intV = v.round();
                  if (intV < 2 || intV > 5) {
                    throw Exception('5 балдық жүйеде 2-5 аралығы');
                  }
                  percent = intV == 5
                      ? 95
                      : intV == 4
                      ? 80
                      : intV == 3
                      ? 65
                      : 50;
                } else {
                  if (v < 0 || v > 100) {
                    throw Exception('0-100 аралығы');
                  }
                  percent = v;
                }

                await supabase
                    .from('grades')
                    .update({
                      'date': dateText,
                      'percent': percent,
                      'type': selectedType,
                    })
                    .eq('id', gradeId);

                if (!mounted) return;
                navigator.pop();
                await _fetchUserAndGrades();
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Қате: $e')));
              }
            },
            child: const Text('Өзгерту'),
          ),
          TextButton(
            onPressed: () async {
              await supabase.from('grades').delete().eq('id', gradeId);
              if (!mounted) return;
              navigator.pop();
              await _fetchUserAndGrades();
            },
            child: const Text('Жою', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTable(
    String name,
    Map<String, dynamic> subject,
    double scaleW,
    double scaleH,
  ) {
    final List<Map<String, dynamic>> gs = List<Map<String, dynamic>>.from(
      subject['grades'] as List,
    );

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
                name,
                style: TextStyle(
                  fontSize: 20 * scaleW,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSubject(name),
                  ),
                  IconButton(
                    onPressed: () => _addGrade(name),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF2DDBD2),
                    ),
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
                  children: const [
                    SizedBox(
                      width: 80,
                      height: 35,
                      child: Center(child: Text('Дата')),
                    ),
                    SizedBox(
                      width: 80,
                      height: 35,
                      child: Center(child: Text('Баға')),
                    ),
                  ],
                ),
                Row(
                  children: gs.map((entry) {
                    return Column(
                      children: [
                        SizedBox(
                          width: 90 * scaleW,
                          height: 35 * scaleH,
                          child: Center(child: Text(entry['date'].toString())),
                        ),
                        SizedBox(
                          width: 90 * scaleW,
                          height: 35 * scaleH,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => _editOrDeleteGrade(name, entry),
                              child: Text(
                                _toDisplayGrade(entry['percent'] as double),
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8 * scaleH),
            child: Text(
              'Орташа баға: ${_avg(gs).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16 * scaleW,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
          centerTitle: true,
          title: Padding(
            padding: EdgeInsets.only(top: 40 * scaleH),
            child: Text(
              'Баға жүйесі: $gradingSystem',
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
                  ...subjects.entries.map(
                    (e) => _buildSubjectTable(e.key, e.value, scaleW, scaleH),
                  ),
                  SizedBox(height: 10 * scaleH),
                  TextButton(
                    onPressed: () => _addSubjectDialog(scaleW, scaleH),
                    child: Text(
                      '+ Пән қосу',
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
    );
  }
}
