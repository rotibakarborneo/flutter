import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/features/auth/data/auth_repository.dart';
import 'package:roti_bakar_borneo_flutter/main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: BorneoColors.gold,
          child: Icon(Icons.person, size: 48, color: Colors.black),
        ),
        const SizedBox(height: 12),
        Text(
          session.nama,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          session.role,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BorneoColors.muted),
        ),
        const SizedBox(height: 24),
        Card(
          color: BorneoColors.card,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Cabang'),
                subtitle: Text(
                  session.idCabang.isEmpty ? 'Pusat' : session.idCabang,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('ID karyawan'),
                subtitle: Text(session.idKaryawan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () async {
            await AuthRepository().logout();
            await AppSession.clear();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
          style: FilledButton.styleFrom(
            backgroundColor: BorneoColors.red,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    ),
  );
}
