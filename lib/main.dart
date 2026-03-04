import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/root_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yeblbluigodxqcxuwxgv.supabase.co',
    anonKey: 'sb_publishable__kkPO32kwzu9hSitEnC9RA_nih_v1yj',
  );

  runApp(const StudentCalculatorApp());
}

class StudentCalculatorApp extends StatelessWidget {
  const StudentCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplus',
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return session == null
            ? const WelcomeScreen()
            : const ProfileBootstrapScreen();
      },
    );
  }
}

class ProfileBootstrapScreen extends StatefulWidget {
  const ProfileBootstrapScreen({super.key});

  @override
  State<ProfileBootstrapScreen> createState() => _ProfileBootstrapScreenState();
}

class _ProfileBootstrapScreenState extends State<ProfileBootstrapScreen> {
  final _supabase = Supabase.instance.client;
  late final Future<void> _bootstrapFuture = _ensureProfile();

  Future<void> _ensureProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile != null) {
      return;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': (metadata['full_name'] ?? '').toString(),
      'grading_view': (metadata['grading_view'] ?? '100').toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Профильді жүктеу кезінде қате пайда болды: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const RootScreen();
      },
    );
  }
}
