import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/core/network/admin_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.session});
  final AppSession session;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<AdminSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminRepository.live().loadDashboard();
  }

  String rupiah(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => '.')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Executive Multi-Outlet Monitor')),
    body: FutureBuilder<AdminSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat outlet: ${snapshot.error}'));
        }
        final data = snapshot.data ?? const AdminSnapshot([]);
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() => _future = AdminRepository.live().loadDashboard()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BorneoColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BorneoColors.stroke),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIVE SALES TODAY',
                            style: TextStyle(
                              color: BorneoColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rupiah(data.sold * 15000),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BorneoColors.green.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${data.open}/${data.outlets.length} buka',
                        style: const TextStyle(
                          color: BorneoColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...data.outlets.map(
                (outlet) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: BorneoColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: BorneoColors.stroke),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: outlet.status == 'BUKA'
                          ? BorneoColors.green.withValues(alpha: 0.18)
                          : BorneoColors.red.withValues(alpha: 0.18),
                      child: Icon(
                        Icons.store,
                        color: outlet.status == 'BUKA'
                            ? BorneoColors.green
                            : BorneoColors.red,
                      ),
                    ),
                    title: Text(
                      outlet.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${outlet.sold} roti terjual • ${outlet.staff} staff',
                    ),
                    trailing: Text(
                      outlet.status == 'BUKA' ? 'BUKA' : 'TUTUP',
                      style: TextStyle(
                        color: outlet.status == 'BUKA'
                            ? BorneoColors.green
                            : BorneoColors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              if (data.outlets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('Belum ada outlet')),
                ),
            ],
          ),
        );
      },
    ),
  );
}
