import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Dashboard'),
      backgroundColor: BorneoColors.background,
    ),
    body: const Center(child: Text('Admin Dashboard placeholder')),
  );
}
