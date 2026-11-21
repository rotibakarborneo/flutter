import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_bakar_borneo_flutter/firebase_options.dart';
import 'package:roti_bakar_borneo_flutter/pages/home_shell.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/features/auth/data/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BorneoApp());
}

class BorneoApp extends StatelessWidget {
  const BorneoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Roti Bakar Borneo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BorneoColors.background,
      colorScheme: const ColorScheme.dark(
        primary: BorneoColors.green,
        secondary: BorneoColors.gold,
        surface: Color(0xFF191714),
        onSurface: BorneoColors.text,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: BorneoColors.green,
        barBackgroundColor: Color(0xDE141210),
        scaffoldBackgroundColor: BorneoColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xDE141210),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: BorneoColors.gold),
        titleTextStyle: TextStyle(
          color: BorneoColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      // other theme settings omitted for brevity – you can keep previous definitions if needed.
    ),
    home: const SessionGate(),
  );
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<AppSession?>(
    future: () async {
      // Sesi hanya dianggap valid jika pengguna masih login di Firebase Auth.
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) {
        await AppSession.clear();
        return null;
      }
      final localSession = await AppSession.read();
      if (localSession == null || localSession.idKaryawan != user.uid) {
        await AppSession.clear();
        if (FirebaseAuth.instance.currentUser == null) return null;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) return null;
        final data = doc.data()!;
        final session = AppSession(
          idKaryawan: user.uid,
          nama: data['nama']?.toString() ?? '',
          role: data['role']?.toString() ?? 'KARYAWAN',
          idCabang: data['id_cabang']?.toString() ?? '',
          fotoProfilUrl: data['foto_profil_url']?.toString(),
        );
        await session.save();
        return session;
      }
      return localSession;
    }(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.data == null
          ? const LoginPage()
          : HomeShell(session: snapshot.data!);
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan password wajib diisi.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final session = await const AuthRepository().login(
        username: username,
        password: password,
      );
      await session.save();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeShell(session: session)),
        (_) => false,
      );
    } catch (error) {
      final text =
          error is FirebaseException && error.code == 'permission-denied'
          ? 'Akses ditolak. Profil akun belum diatur dengan benar.'
          : '$error';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  CupertinoIcons.flame_fill,
                  color: BorneoColors.gold,
                  size: 52,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Masuk ke Borneo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun karyawan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BorneoColors.muted),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(CupertinoIcons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(CupertinoIcons.lock),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
