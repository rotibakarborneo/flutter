import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roti_bakar_borneo_flutter/pages/admin_dashboard_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/finance_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/manage_data_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/admin_reports_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/profile_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/cashier_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/shift_report_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/history_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/profile_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/bon_page.dart';
import 'package:roti_bakar_borneo_flutter/pages/dashboard_page.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final AppSession session;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final admin = widget.session.isAdmin || widget.session.isBos;
    final pages = admin
        ? [
            AdminDashboardPage(session: widget.session),
            FinancePage(session: widget.session),
            ManageDataPage(session: widget.session),
            AdminReportsPage(session: widget.session),
            ProfilePage(session: widget.session),
          ]
        : [
            DashboardPage(
              session: widget.session,
              onNavigate: (i) => setState(() => index = i),
            ),
            CashierPage(session: widget.session),
            ShiftReportPage(session: widget.session),
            HistoryPage(session: widget.session),
            ProfilePage(session: widget.session),
          ];

    final navItems = admin
        ? const [
            (
              CupertinoIcons.building_2_fill,
              CupertinoIcons.building_2_fill,
              'Outlet',
            ),
            (
              CupertinoIcons.money_dollar_circle_fill,
              CupertinoIcons.money_dollar_circle,
              'Keuangan',
            ),
            (
              CupertinoIcons.plus_circle_fill,
              CupertinoIcons.plus_circle,
              'Tambah',
            ),
            (
              CupertinoIcons.chart_bar_square_fill,
              CupertinoIcons.chart_bar_square,
              'Laporan',
            ),
            (
              CupertinoIcons.person_crop_circle_fill,
              CupertinoIcons.person_crop_circle,
              'Profil',
            ),
          ]
        : const [
            (CupertinoIcons.house_fill, CupertinoIcons.house, 'Beranda'),
            (CupertinoIcons.cart_fill, CupertinoIcons.cart, 'Kasir'),
            (CupertinoIcons.doc_text_fill, CupertinoIcons.doc_text, 'Laporan'),
            (CupertinoIcons.clock_fill, CupertinoIcons.clock, 'Riwayat'),
            (
              CupertinoIcons.person_crop_circle_fill,
              CupertinoIcons.person_crop_circle,
              'Profil',
            ),
          ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xDE141210),
          border: Border(top: BorderSide(color: Color(0x24FFFFFF), width: 0.5)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 58,
                child: Row(
                  children: List.generate(navItems.length, (i) {
                    final isSelected = index == i;
                    final item = navItems[i];
                    return Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => index = i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BorneoColors.gold.withValues(alpha: 0.16)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isSelected ? item.$1 : item.$2,
                                size: 22,
                                color: isSelected
                                    ? BorneoColors.gold
                                    : const Color(0xFF8E8E93),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? BorneoColors.gold
                                    : const Color(0xFF8E8E93),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
