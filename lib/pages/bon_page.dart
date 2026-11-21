import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/core/network/employee_repository.dart';
import 'package:flutter/cupertino.dart';

class BonPage extends StatefulWidget {
  const BonPage({super.key, required this.session});
  final AppSession session;

  @override
  State<BonPage> createState() => _BonPageState();
}

class _BonPageState extends State<BonPage> {
  late Future<List<BonRecord>> _future;
  final _nominal = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = EmployeeRepository.live().bonSaya(widget.session);
  }

  @override
  void dispose() {
    _nominal.dispose();
    _note.dispose();
    super.dispose();
  }

  String rupiah(double value) =>
      'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => '.')}';

  Future<void> _submit() async {
    final nominal = double.tryParse(_nominal.text.trim()) ?? 0;
    if (nominal <= 0) return;
    await EmployeeRepository.live().ajukanBon(
      widget.session,
      nominal: nominal,
      note: _note.text.trim(),
    );
    _nominal.clear();
    _note.clear();
    if (!mounted) return;
    setState(() => _future = EmployeeRepository.live().bonSaya(widget.session));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payroll & Bon')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: BorneoColors.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajukan Bon',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nominal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nominal'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: BorneoColors.gold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Ajukan'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Riwayat Bon',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<BonRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            if (records.isEmpty)
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Belum ada bon')),
              );
            return Column(
              children: records
                  .map(
                    (record) => Card(
                      color: BorneoColors.card,
                      child: ListTile(
                        leading: const Icon(
                          CupertinoIcons.creditcard_fill,
                          color: BorneoColors.gold,
                        ),
                        title: Text(
                          rupiah(record.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(record.note),
                        trailing: Text(
                          record.status,
                          style: TextStyle(
                            color: record.status == 'MENUNGGU'
                                ? BorneoColors.gold
                                : BorneoColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
