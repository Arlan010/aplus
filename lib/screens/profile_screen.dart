import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reset_password_email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isLoading = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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

      if (!mounted) return;
      setState(() {
        _nameController.text = (profile?['full_name'] ?? '').toString();
        _emailController.text = (user.email ?? '').toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Қате: $e')));
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Сессия жоқ. Қайта кіріңіз.');

      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();

      await supabase
          .from('profiles')
          .update({'full_name': newName})
          .eq('id', user.id);

      final currentEmail = user.email ?? '';
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        await supabase.auth.updateUser(UserAttributes(email: newEmail));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сәтті жаңартылды ✅')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Қате: $e')));
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    // AuthGate/Welcome экран должен отреагировать на signOut сам
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

  Widget _buildPasswordRow({required double scaleW, required double scaleH}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * scaleH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8 * scaleW, bottom: 6 * scaleH),
            child: Text(
              "Құпиясөз",
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _showChangePasswordDialog(scaleW: scaleW, scaleH: scaleH),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scaleW,
                    vertical: 10 * scaleH,
                  ),
                  foregroundColor: const Color(0xFF20409A),
                ),
                child: Text(
                  "Құпиясөзді өзгерту",
                  style: TextStyle(
                    fontSize: 16 * scaleW,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog({
    required double scaleW,
    required double scaleH,
  }) async {
    final parentContext = context;

    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    Future<void> doSave(
      StateSetter setStateDialog,
      BuildContext dialogContext,
    ) async {
      final user = supabase.auth.currentUser;
      final email = user?.email;

      final oldPass = oldPassController.text.trim();
      final newPass = newPassController.text.trim();

      if (email == null) {
        ScaffoldMessenger.of(
          parentContext,
        ).showSnackBar(const SnackBar(content: Text('Email табылмады')));
        return;
      }

      if (oldPass.isEmpty || newPass.isEmpty) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Барлық өрістерді толтырыңыз')),
        );
        return;
      }

      if (newPass.length < 6) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Жаңа құпиясөз кемінде 6 таңба болуы керек'),
          ),
        );
        return;
      }

      if (dialogContext.mounted) setStateDialog(() => isSaving = true);

      try {
        await supabase.auth.signInWithPassword(email: email, password: oldPass);
        await supabase.auth.updateUser(UserAttributes(password: newPass));

        if (!mounted) return;

        if (dialogContext.mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Құпиясөз сәтті өзгертілді ✅')),
          );
        });
      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          parentContext,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          parentContext,
        ).showSnackBar(SnackBar(content: Text('Қате: $e')));
      } finally {
        if (dialogContext.mounted) setStateDialog(() => isSaving = false);
      }
    }

    await showDialog(
      context: parentContext,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Құпиясөзді өзгерту',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPassController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Ескі құпиясөз',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setStateDialog(() => obscureOld = !obscureOld),
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Жаңа құпиясөз',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setStateDialog(() => obscureNew = !obscureNew),
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                Navigator.of(
                                  dialogContext,
                                  rootNavigator: true,
                                ).pop();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  Navigator.of(parentContext).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ResetPasswordEmailScreen(),
                                    ),
                                  );
                                });
                              },
                        child: const Text(
                          'Құпиясөзді ұмыттыңыз ба?',
                          style: TextStyle(fontFamily: 'Montserrat'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Жабу'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () => doSave(setStateDialog, dialogContext),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сақтау'),
                ),
              ],
            );
          },
        );
      },
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
              onEditPressed: () =>
                  setState(() => _isEditingName = !_isEditingName),
              scaleW: scaleW,
              scaleH: scaleH,
            ),
            _buildEditableField(
              label: "Электрондық пошта",
              controller: _emailController,
              isEditing: _isEditingEmail,
              onEditPressed: () =>
                  setState(() => _isEditingEmail = !_isEditingEmail),
              scaleW: scaleW,
              scaleH: scaleH,
            ),
            _buildPasswordRow(scaleW: scaleW, scaleH: scaleH),
            SizedBox(height: 10 * scaleH),
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
            SizedBox(height: 15 * scaleH),
            SizedBox(
              width: 250 * scaleW,
              height: 55 * scaleH,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100 * scaleW),
                  ),
                ),
                child: Text(
                  "Шығу",
                  style: TextStyle(
                    fontSize: 20 * scaleW,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 50 * scaleH),
          ],
        ),
      ),
    );
  }
}
