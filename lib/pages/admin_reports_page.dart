import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Reports'),
      backgroundColor: BorneoColors.background,
    ),
    body: const Center(child: Text('Admin Reports placeholder')),
  );
}
