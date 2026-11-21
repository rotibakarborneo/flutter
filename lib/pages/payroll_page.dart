import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:roti_bakar_borneo_flutter/core/network/admin_repository.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

enum _PayrollTab { sevenDays, thirtyDays, bonus }

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key, required this.session});
  final AppSession session;

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  _PayrollTab _tab = _PayrollTab.sevenDays;
  late Future<List<PayrollRecord>> _payrollFuture;
  late Future<List<BonusRecord>> _bonusFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _payrollFuture = AdminRepository.live().payroll(days: 7);
    _bonusFuture = AdminRepository.live().bonus(days: 30);
  }

  void _select(_PayrollTab tab) {
    setState(() {
      _tab = tab;
      if (tab == _PayrollTab.sevenDays) {
        _payrollFuture = AdminRepository.live().payroll(days: 7);
      } else if (tab == _PayrollTab.thirtyDays) {
        _payrollFuture = AdminRepository.live().payroll(days: 30);
      } else {
        _bonusFuture = AdminRepository.live().bonus(days: 30);
      }
    });
  }

  String _rupiah(double value) =>
      'Rp ${value.round().toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => '.')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Payroll'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: () => setState(_load),
          icon: const Icon(CupertinoIcons.arrow_clockwise),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<_PayrollTab>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _PayrollTab.sevenDays,
                label: Text('7 Hari'),
                icon: Icon(CupertinoIcons.calendar),
              ),
              ButtonSegment(
                value: _PayrollTab.thirtyDays,
                label: Text('30 Hari'),
                icon: Icon(CupertinoIcons.calendar_today),
              ),
              ButtonSegment(
                value: _PayrollTab.bonus,
                label: Text('Bonus'),
                icon: Icon(CupertinoIcons.gift),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (selection) => _select(selection.first),
          ),
        ),
        Expanded(
          child: _tab == _PayrollTab.bonus
              ? _bonusContent()
              : _payrollContent(_tab == _PayrollTab.sevenDays
                    ? _payrollFuture
                    : _payrollFuture),
        ),
      ],
    ),
  );

  Widget _payrollContent(Future<List<PayrollRecord>> future) =>
      FutureBuilder<List<PayrollRecord>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message('Gagal memuat payroll: ${snapshot.error}');
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) return _message('Belum ada shift selesai pada periode ini.');
          final total = records.fold<double>(0, (sum, item) => sum + item.net);
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _payrollFuture = AdminRepository.live().payroll(
                days: _tab == _PayrollTab.sevenDays ? 7 : 30,
              );
            }),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _summary(
                  title: 'Total gaji bersih',
                  value: _rupiah(total),
                  subtitle: '${records.length} karyawan • bon tidak termasuk payroll',
                  icon: CupertinoIcons.money_dollar_circle,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rincian karyawan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...records.map(_payrollCard),
              ],
            ),
          );
        },
      );

  Widget _bonusContent() => FutureBuilder<List<BonusRecord>>(
    future: _bonusFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _message('Gagal memuat bonus roti: ${snapshot.error}');
      }
      final records = snapshot.data ?? [];
      if (records.isEmpty) return _message('Belum ada laporan shift selesai yang dapat dihitung bonusnya.');
      final totalExcess = records.fold<int>(0, (sum, item) => sum + item.excess);
      final totalSold = records.fold<int>(0, (sum, item) => sum + item.sold);
      final totalTarget = records.fold<int>(0, (sum, item) => sum + item.target);
      return RefreshIndicator(
        onRefresh: () async => setState(
          () => _bonusFuture = AdminRepository.live().bonus(days: 30),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _summary(
              title: 'Total kelebihan roti',
              value: '+$totalExcess roti',
              subtitle: 'Periode 30 hari terakhir yang sudah selesai',
              icon: CupertinoIcons.gift,
              isBonus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _smallMetric('Terjual', '$totalSold')),
                const SizedBox(width: 8),
                Expanded(child: _smallMetric('Target', '$totalTarget')),
                const SizedBox(width: 8),
                Expanded(child: _smallMetric('Kelebihan', '$totalExcess')),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Bonus per karyawan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...records.map(_bonusCard),
            const SizedBox(height: 8),
            const Text(
              'Bonus ditampilkan sebagai jumlah roti di atas target, bukan nominal uang.',
              style: TextStyle(color: BorneoColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );

  Widget _payrollCard(PayrollRecord record) => Card(
    color: BorneoColors.card,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _detail('Hari masuk', '${record.days} hari')),
              Expanded(child: _detail('Jam kerja', '${record.hours.toStringAsFixed(1)} jam')),
              Expanded(child: _detail('Terlambat', '${record.lateMinutes} menit')),
            ],
          ),
          const Divider(height: 20),
          _moneyRow('Gaji kotor', _rupiah(record.gross)),
          const SizedBox(height: 5),
          _moneyRow('Potongan terlambat', '-${_rupiah(record.deduction)}', color: BorneoColors.red),
          const SizedBox(height: 8),
          _moneyRow('Gaji bersih', _rupiah(record.net), strong: true),
        ],
      ),
    ),
  );

  Widget _bonusCard(BonusRecord record) => Card(
    color: BorneoColors.card,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: BorneoColors.green.withValues(alpha: 0.16),
        child: const Icon(CupertinoIcons.gift_fill, color: BorneoColors.green),
      ),
      title: Text(record.name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        '${record.days} shift • ${record.totalHours.toStringAsFixed(1)} jam\n'
        'Terjual ${record.sold} • Target ${record.target}',
      ),
      isThreeLine: true,
      trailing: Text(
        '+${record.excess}',
        style: TextStyle(
          color: record.excess > 0 ? BorneoColors.green : BorneoColors.muted,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    ),
  );

  Widget _summary({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool isBonus = false,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: BorneoColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BorneoColors.stroke),
    ),
    child: Row(
      children: [
        Icon(icon, color: isBonus ? BorneoColors.green : BorneoColors.gold, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: BorneoColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: BorneoColors.muted, fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _smallMetric(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: BorneoColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: BorneoColors.stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: BorneoColors.muted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ],
    ),
  );

  Widget _detail(String title, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: BorneoColors.muted, fontSize: 11)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    ],
  );

  Widget _moneyRow(String title, String value, {bool strong = false, Color? color}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(
            color: strong ? BorneoColors.text : BorneoColors.muted,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
          )),
          Text(value, style: TextStyle(
            color: color ?? BorneoColors.text,
            fontWeight: FontWeight.w900,
          )),
        ],
      );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
