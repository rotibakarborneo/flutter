import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class ShiftReportPage extends StatelessWidget {
  const ShiftReportPage({super.key, required this.session});
  final AppSession session;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Laporan Shift'),
      backgroundColor: BorneoColors.background,
    ),
    body: const Center(child: Text('Shift report placeholder')),
  );
}
