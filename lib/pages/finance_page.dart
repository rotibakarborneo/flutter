import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/core/network/admin_repository.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key, required this.session});
  final AppSession session;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late Future<FinanceSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminRepository.live().loadFinance();
  }

  String rupiah(double value) =>
      'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => '.')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analytics Overview')),
    body: FutureBuilder<FinanceSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat keuangan: ${snapshot.error}'),
          );
        }
        final data =
            snapshot.data ??
            const FinanceSnapshot(income: 0, expense: 0, records: []);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _metric('Setoran', data.income, BorneoColors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric('Pengeluaran', data.expense, BorneoColors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metric(
              'Saldo Bersih',
              data.balance,
              BorneoColors.gold,
              full: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...data.records
                .take(20)
                .map(
                  (record) => Card(
                    color: BorneoColors.card,
                    child: ListTile(
                      title: Text(record.category),
                      subtitle: Text(record.branch),
                      trailing: Text(
                        '${record.type == 'PEMASUKAN' ? '+' : '-'}${rupiah(record.amount)}',
                        style: TextStyle(
                          color: record.type == 'PEMASUKAN'
                              ? BorneoColors.green
                              : BorneoColors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );

  Widget _metric(
    String title,
    double value,
    Color color, {
    bool full = false,
  }) => Container(
    width: full ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: BorneoColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: BorneoColors.stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: BorneoColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          rupiah(value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );
}
