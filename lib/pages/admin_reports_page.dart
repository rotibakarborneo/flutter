import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/network/admin_repository.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key, required this.session});
  final AppSession session;

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late Future<List<AdminReportRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminRepository.live().shiftReports(days: 7);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laporan 7 Hari')),
    body: FutureBuilder<List<AdminReportRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty)
          return const Center(child: Text('Belum ada laporan shift'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              color: BorneoColors.card,
              child: ListTile(
                leading: const Icon(
                  Icons.description,
                  color: BorneoColors.gold,
                ),
                title: Text(report.employee),
                subtitle: Text('${report.branch} • ${report.date}'),
                trailing: Text(
                  '${report.sold.toInt()} roti',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
