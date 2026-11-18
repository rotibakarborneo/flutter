import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

class AdminRepository {
  AdminRepository([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  factory AdminRepository.live() => AdminRepository();

  final FirebaseFirestore _db;

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<AdminSnapshot> loadDashboard() async {
    final branchSnap = await _db.collection('cabang').get();
    final today = _todayStr();

    List<OutletSummary> outlets = [];

    for (final bDoc in branchSnap.docs) {
      final bData = bDoc.data();
      final branchId = bDoc.id;
      final branchName = bData['nama_cabang']?.toString() ?? 'Outlet';

      // Cek presensi hari ini di cabang ini
      final presensiSnap = await _db
          .collection('presensi')
          .where('id_cabang', isEqualTo: branchId)
          .where('tanggal', isEqualTo: today)
          .get();

      final staffCount = presensiSnap.docs.length;
      final status = staffCount > 0 ? 'BUKA' : 'BELUM_BUKA';

      // Cek penjualan hari ini
      final kasirSnap = await _db
          .collection('transaksi_kasir')
          .where('id_cabang', isEqualTo: branchId)
          .where('tanggal_operasional', isEqualTo: today)
          .get();

      int sold = 0;
      for (final doc in kasirSnap.docs) {
        sold += (doc.data()['total_roti'] as num?)?.toInt() ?? 0;
      }

      outlets.add(
        OutletSummary(
          id: branchId,
          name: branchName,
          status: status,
          sold: sold,
          staff: staffCount,
          hours: 0,
          wage: 0,
        ),
      );
    }

    return AdminSnapshot(outlets);
  }

  Future<OutletReport> loadOutletReport(String branchId) async {
    final today = _todayStr();
    final snap = await _db
        .collection('laporan_shift')
        .where('id_cabang', isEqualTo: branchId)
        .where('tanggal_operasional', isEqualTo: today)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return OutletReport(
        date: today,
        start: '-',
        end: '-',
        breadStart: 0,
        breadLeft: 0,
        sold: 0,
        cashier: 0,
        outside: 0,
        damaged: 0,
        expense: 0,
        deposit: 0,
        floatCash: 0,
        note: '',
      );
    }

    final data = snap.docs.first.data();
    final bStart = money(data['roti_awal'] ?? data['roti_diantar']);
    final bLeft = money(data['roti_sisa']);
    return OutletReport(
      date: data['tanggal_operasional']?.toString() ?? today,
      start: data['jam_mulai']?.toString() ?? '-',
      end: data['jam_selesai']?.toString() ?? '-',
      breadStart: bStart,
      breadLeft: bLeft,
      sold: bStart - bLeft,
      cashier: money(data['penjualan_offline_roti']),
      outside: money(data['penjualan_luar_kasir_roti']),
      damaged: money(data['roti_rusak_bonus']),
      expense: money(data['pengeluaran']),
      deposit: money(data['setor_uang']),
      floatCash: money(data['sisa_modal']),
      note: data['catatan']?.toString() ?? '',
    );
  }

  Future<FinanceSnapshot> loadFinance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start;
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(end);

    final snap = await _db
        .collection('keuangan')
        .where('tanggal_operasional', isGreaterThanOrEqualTo: startKey)
        .where('tanggal_operasional', isLessThanOrEqualTo: endKey)
        .orderBy('tanggal_operasional', descending: true)
        .get();

    double income = 0;
    double expense = 0;
    List<FinanceRecord> records = [];

    for (final doc in snap.docs) {
      final item = doc.data();
      final amount = money(item['nominal']);
      final type = item['jenis']?.toString() ?? '';
      if (type == 'PEMASUKAN') {
        income += amount;
      } else {
        expense += amount;
      }
      records.add(
        FinanceRecord(
          category: item['kategori']?.toString() ?? 'Transaksi',
          branch: item['nama_cabang']?.toString() ?? 'Pusat',
          amount: amount,
          type: type,
        ),
      );
    }

    return FinanceSnapshot(income: income, expense: expense, records: records);
  }

  Future<List<AdminBonRecord>> loadBons() async {
    final snap = await _db
        .collection('bon')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs
        .map((doc) => AdminBonRecord.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> verifyBon(
    AppSession session, {
    required String bonId,
    required String status,
    required double paid,
    required String note,
  }) async {
    // Cari dokumen bon
    final snap = await _db
        .collection('bon')
        .where('bon_id', isEqualTo: bonId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final docRef = snap.docs.first.reference;
      final nominal =
          (snap.docs.first.data()['nominal'] as num?)?.toDouble() ?? 0;
      await docRef.update({
        'status': status,
        'dibayar': paid,
        'sisa_bon': max(0.0, nominal - paid),
        'catatan_admin': note,
        'id_admin': session.idKaryawan,
      });
    }
  }

  Future<List<BranchMaster>> branches() async {
    final snap = await _db.collection('cabang').get();
    return snap.docs
        .map(
          (d) => BranchMaster(
            id: d.id,
            name: d.data()['nama_cabang']?.toString() ?? 'Outlet',
          ),
        )
        .toList();
  }

  Future<void> saveFinance(
    AppSession session, {
    required String date,
    required String branchId,
    required String type,
    required String category,
    required double amount,
    required String note,
  }) async {
    String branchName = 'Pusat';
    if (branchId.isNotEmpty) {
      try {
        final bDoc = await _db.collection('cabang').doc(branchId).get();
        if (bDoc.exists) {
          branchName = bDoc.data()?['nama_cabang']?.toString() ?? 'Outlet';
        }
      } catch (_) {}
    }

    await _db.collection('keuangan').add({
      'id_admin': session.idKaryawan,
      'id_cabang_admin': session.idCabang,
      'tanggal_operasional': date,
      'id_cabang': branchId,
      'nama_cabang': branchName,
      'jenis': type,
      'kategori': category,
      'nominal': amount,
      'catatan': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addEmployee(
    AppSession session, {
    required String name,
    required String username,
    required String password,
    required String branchId,
    required double wage,
  }) async {
    // Tambah dokumen ke koleksi users di Firestore
    await _db.collection('users').add({
      'nama': name,
      'username': username,
      'role': 'KARYAWAN',
      'id_cabang': branchId,
      'tarif_per_jam': wage,
      'dibuat_oleh': session.idKaryawan,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBranch(
    AppSession session, {
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    await _db.collection('cabang').add({
      'nama_cabang': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radius,
      'dibuat_oleh': session.idKaryawan,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<PayrollRecord>> payroll({
    int days = 7,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = endDate ?? DateTime.now();
    final start = startDate ?? now.subtract(Duration(days: days - 1));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(now);

    final presensiSnap = await _db
        .collection('presensi')
        .where('tanggal', isGreaterThanOrEqualTo: startKey)
        .where('tanggal', isLessThanOrEqualTo: endKey)
        .get();

    // Kelompokkan per karyawan
    Map<String, Map<String, dynamic>> map = {};
    for (final doc in presensiSnap.docs) {
      final d = doc.data();
      final empId = d['id_karyawan']?.toString() ?? '';
      final empName = d['nama_karyawan']?.toString() ?? 'Karyawan';
      if (!map.containsKey(empId)) {
        map[empId] = {
          'id': empId,
          'nama': empName,
          'days': 0,
          'hours': 0.0,
          'wage': 0.0,
        };
      }
      map[empId]!['days'] = (map[empId]!['days'] as int) + 1;
      map[empId]!['hours'] =
          (map[empId]!['hours'] as double) +
          ((d['total_jam'] as num?)?.toDouble() ?? 8.0);
    }

    return map.values
        .map(
          (j) => PayrollRecord(
            id: j['id'] as String,
            name: j['nama'] as String,
            days: j['days'] as int,
            hours: j['hours'] as double,
            net: (j['hours'] as double) * 15000, // default tarif estimasi
          ),
        )
        .toList();
  }

  Future<List<BonusRecord>> bonus({
    int days = 7,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = endDate ?? DateTime.now();
    final start = startDate ?? now.subtract(Duration(days: days - 1));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(now);

    final reportSnap = await _db
        .collection('laporan_shift')
        .where('tanggal_operasional', isGreaterThanOrEqualTo: startKey)
        .where('tanggal_operasional', isLessThanOrEqualTo: endKey)
        .get();

    Map<String, Map<String, dynamic>> map = {};
    for (final doc in reportSnap.docs) {
      final d = doc.data();
      final empId = d['id_karyawan']?.toString() ?? '';
      if (!map.containsKey(empId)) {
        map[empId] = {
          'nama': d['nama_karyawan']?.toString() ?? 'Karyawan',
          'days': 0,
          'sold': 0,
        };
      }
      map[empId]!['days'] = (map[empId]!['days'] as int) + 1;
      final startB = (d['roti_awal'] as num?)?.toInt() ?? 0;
      final leftB = (d['roti_sisa'] as num?)?.toInt() ?? 0;
      map[empId]!['sold'] = (map[empId]!['sold'] as int) + (startB - leftB);
    }

    return map.values.map((j) {
      final sold = j['sold'] as int;
      final days = j['days'] as int;
      final target = days * 50; // target 50 roti per shift
      return BonusRecord(
        name: j['nama'] as String,
        days: days,
        sold: sold,
        target: target,
        excess: max(0, sold - target),
      );
    }).toList();
  }

  Future<List<AdminReportRecord>> shiftReports({
    int days = 7,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = endDate ?? DateTime.now();
    final start = startDate ?? now.subtract(Duration(days: days - 1));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(now);

    final snap = await _db
        .collection('laporan_shift')
        .where('tanggal_operasional', isGreaterThanOrEqualTo: startKey)
        .where('tanggal_operasional', isLessThanOrEqualTo: endKey)
        .orderBy('tanggal_operasional', descending: true)
        .get();

    return snap.docs.map((d) => AdminReportRecord.fromJson(d.data())).toList();
  }

  Future<List<CashierRecord>> cashier({required String date}) async {
    final snap = await _db
        .collection('transaksi_kasir')
        .where('tanggal_operasional', isEqualTo: date)
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((doc) => CashierRecord.fromJson(doc.data())).toList();
  }
}

double money(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

class OutletSummary {
  OutletSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.sold,
    required this.staff,
    required this.hours,
    required this.wage,
  });
  final String id, name, status;
  final int sold, staff;
  final double hours, wage;
}

class OutletReport {
  const OutletReport({
    required this.date,
    required this.start,
    required this.end,
    required this.breadStart,
    required this.breadLeft,
    required this.sold,
    required this.cashier,
    required this.outside,
    required this.damaged,
    required this.expense,
    required this.deposit,
    required this.floatCash,
    required this.note,
  });
  final String date, start, end, note;
  final double breadStart,
      breadLeft,
      sold,
      cashier,
      outside,
      damaged,
      expense,
      deposit,
      floatCash;
}

class AdminSnapshot {
  const AdminSnapshot(this.outlets);
  final List<OutletSummary> outlets;
  int get sold => outlets.fold(0, (total, outlet) => total + outlet.sold);
  int get open => outlets.where((outlet) => outlet.status == 'BUKA').length;
}

class FinanceRecord {
  FinanceRecord({
    required this.category,
    required this.branch,
    required this.amount,
    required this.type,
  });
  final String category, branch, type;
  final double amount;
}

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.income,
    required this.expense,
    required this.records,
  });
  final double income, expense;
  final List<FinanceRecord> records;
  double get balance => income - expense;
}

class AdminBonRecord {
  const AdminBonRecord({
    required this.id,
    required this.name,
    required this.branch,
    required this.amount,
    required this.note,
    required this.status,
    required this.paid,
    required this.remaining,
  });
  final String id, name, branch, note, status;
  final double amount, paid, remaining;

  factory AdminBonRecord.fromJson(
    Map<String, dynamic> j, [
    String docId = '',
  ]) => AdminBonRecord(
    id: j['bon_id']?.toString() ?? docId,
    name: j['nama_karyawan']?.toString() ?? 'Karyawan',
    branch: j['nama_cabang']?.toString() ?? 'Outlet',
    amount: money(j['nominal']),
    note: j['catatan']?.toString() ?? '',
    status: j['status']?.toString() ?? 'MENUNGGU',
    paid: money(j['dibayar']),
    remaining: money(j['sisa_bon']),
  );
}

class BranchMaster {
  const BranchMaster({required this.id, required this.name});
  final String id, name;
}

class PayrollRecord {
  const PayrollRecord({
    required this.id,
    required this.name,
    required this.days,
    required this.hours,
    required this.net,
  });
  final String id, name;
  final int days;
  final double hours, net;
}

class BonusRecord {
  const BonusRecord({
    required this.name,
    required this.days,
    required this.sold,
    required this.target,
    required this.excess,
  });
  final String name;
  final int days, sold, target, excess;
}

class AdminReportRecord {
  const AdminReportRecord({
    required this.date,
    required this.branch,
    required this.employee,
    required this.sold,
    required this.deposit,
  });
  final String date, branch, employee;
  final double sold, deposit;

  factory AdminReportRecord.fromJson(Map<String, dynamic> j) =>
      AdminReportRecord(
        date: j['tanggal_operasional']?.toString() ?? '',
        branch: j['nama_cabang']?.toString() ?? 'Outlet',
        employee: j['nama_karyawan']?.toString() ?? 'Karyawan',
        sold: money(
          j['roti_terjual'] ??
              ((j['roti_awal'] as num? ?? 0) - (j['roti_sisa'] as num? ?? 0)),
        ),
        deposit: money(j['setor_uang']),
      );
}

class CashierRecord {
  const CashierRecord({
    required this.branch,
    required this.employee,
    required this.payment,
    required this.total,
    required this.bread,
    required this.items,
  });
  final String branch, employee, payment, items;
  final double total, bread;

  factory CashierRecord.fromJson(Map<String, dynamic> j) => CashierRecord(
    branch: j['nama_cabang']?.toString() ?? 'Outlet',
    employee: j['nama_karyawan']?.toString() ?? 'Karyawan',
    payment: j['metode_bayar']?.toString() ?? '',
    total: money(j['total_bayar']),
    bread: money(j['total_roti']),
    items: (j['items'] as List? ?? [])
        .whereType<Map>()
        .map((x) => x['nama']?.toString() ?? '')
        .where((x) => x.isNotEmpty)
        .join(', '),
  );
}
