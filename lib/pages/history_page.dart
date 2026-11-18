import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Riwayat'),
      backgroundColor: BorneoColors.background,
    ),
    body: const Center(child: Text('History placeholder')),
  );
}
