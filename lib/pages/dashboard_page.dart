import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/core/network/employee_repository.dart';
import 'package:roti_bakar_borneo_flutter/pages/attendance_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/bon_page.dart';
import 'package:roti_bakar_borneo_flutter/widgets/hero_panel.dart';
import 'package:roti_bakar_borneo_flutter/widgets/section_title.dart';
import 'package:roti_bakar_borneo_flutter/widgets/quick_card.dart';
import 'package:roti_bakar_borneo_flutter/widgets/mini_metric.dart';
import 'package:roti_bakar_borneo_flutter/widgets/history_tile.dart';
import 'package:roti_bakar_borneo_flutter/utils/printer_helper.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.session,
    required this.onNavigate,
  });
  final AppSession session;
  final ValueChanged<int> onNavigate;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<EmployeePerformance> _future;

  @override
  void initState() {
    super.initState();
    _future = EmployeeRepository.live().performance(widget.session);
  }

  String rupiah(double value) =>
      'Rp${value.toStringAsFixed(0).replaceAllMapped(RegExp(r"(?<!^)(?=(\\d{3})+$)"), (m) => ".")}';

  @override
  Widget build(BuildContext context) => FutureBuilder<EmployeePerformance>(
    future: _future,
    builder: (context, snapshot) {
      final data =
          snapshot.data ??
          const EmployeePerformance(hours: 0, wage: 0, status: 'BELUM_ABSEN');
      final active = data.status == 'BUKA';
      return RefreshIndicator(
        onRefresh: () async => setState(
          () => _future = EmployeeRepository.live().performance(widget.session),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${widget.session.nama.isEmpty ? 'Kasir' : widget.session.nama.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x22FFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x26FFFFFF),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.location_solid,
                                  size: 12,
                                  color: BorneoColors.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.session.idCabang.isEmpty
                                      ? 'Outlet Borneo'
                                      : widget.session.idCabang,
                                  style: const TextStyle(
                                    color: BorneoColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0x333FAE67)
                                  : const Color(0x33A99D90),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? const Color(0x66B0E0A5)
                                    : const Color(0x66A99D90),
                              ),
                            ),
                            child: Text(
                              active ? 'SHIFT AKTIF' : 'BELUM ABSEN',
                              style: TextStyle(
                                color: active
                                    ? BorneoColors.green
                                    : BorneoColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      CupertinoIcons.arrow_clockwise,
                      color: BorneoColors.gold,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _future = EmployeeRepository.live().performance(
                        widget.session,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            HeroPanel(
              eyebrow: 'SHIFT OUTLET',
              title: active ? 'Sedang bekerja' : 'Belum memulai shift',
              subtitle: active
                  ? 'Total jam dan gaji akan terus diperbarui otomatis.'
                  : 'Presensi dengan foto dan GPS saat di outlet.',
              icon: CupertinoIcons.timer,
              value: active ? '${data.hours.toStringAsFixed(1)} jam' : null,
            ),
            const SizedBox(height: 22),
            const SectionTitle('Performa hari ini'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiniMetric(
                    label: 'Jam kerja',
                    value: '${data.hours.toStringAsFixed(1)} jam',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniMetric(
                    label: 'Estimasi gaji',
                    value: rupiah(data.wage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Akses cepat'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                QuickCard(
                  icon: CupertinoIcons.checkmark_shield_fill,
                  title: 'Presensi',
                  subtitle: 'Masuk / pulang',
                  accent: BorneoColors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AttendancePage(session: widget.session),
                    ),
                  ),
                ),
                QuickCard(
                  icon: CupertinoIcons.cart_fill,
                  title: 'Kasir POS',
                  subtitle: 'Transaksi offline',
                  accent: BorneoColors.gold,
                  onTap: () => widget.onNavigate(1),
                ),
                QuickCard(
                  icon: CupertinoIcons.doc_text_fill,
                  title: 'Laporan shift',
                  subtitle: 'Isi sebelum pulang',
                  accent: BorneoColors.red,
                  onTap: () => widget.onNavigate(2),
                ),
                QuickCard(
                  icon: CupertinoIcons.creditcard_fill,
                  title: 'Bon saya',
                  subtitle: 'Lihat status bon',
                  accent: const Color(0xFFBE8AF0),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BonPage(session: widget.session),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
