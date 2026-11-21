import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/firebase_options.dart';

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
    final normalizedName = name.trim();
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPassword = password;
    final normalizedBranchId = branchId.trim();

    if (normalizedName.length < 3) {
      throw const FormatException('Nama karyawan minimal 3 karakter.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(normalizedUsername)) {
      throw const FormatException(
        'Username hanya boleh berisi huruf, angka, titik, strip, atau underscore.',
      );
    }
    if (normalizedPassword.length < 6) {
      throw const FormatException('Password minimal 6 karakter.');
    }
    if (normalizedBranchId.isEmpty) {
      throw const FormatException('Cabang wajib dipilih.');
    }
    if (!wage.isFinite || wage < 0) {
      throw const FormatException('Tarif per jam tidak valid.');
    }

    FirebaseApp? employeeApp;
    try {
      employeeApp = Firebase.app('employeeCreator');
    } on FirebaseException {
      employeeApp = await Firebase.initializeApp(
        name: 'employeeCreator',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final employeeAuth = FirebaseAuth.instanceFor(app: employeeApp);
    UserCredential credential;
    try {
      credential = await employeeAuth.createUserWithEmailAndPassword(
        email: '$normalizedUsername@rbb.app',
        password: normalizedPassword,
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'email-already-in-use':
          throw const FormatException('Username tersebut sudah digunakan.');
        case 'weak-password':
          throw const FormatException('Password terlalu lemah.');
        case 'invalid-email':
          throw const FormatException('Username tidak valid.');
        default:
          throw FormatException('Gagal membuat akun: ${error.message}');
      }
    }

    final uid = credential.user!.uid;
    try {
      await _db.collection('users').doc(uid).set({
        'nama': normalizedName,
        'username': normalizedUsername,
        'role': 'KARYAWAN',
        'id_cabang': normalizedBranchId,
        'tarif_per_jam': wage,
        'dibuat_oleh': session.idKaryawan,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await employeeAuth.signOut();
    } catch (_) {
      await credential.user?.delete();
      await employeeAuth.signOut();
      rethrow;
    }
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
    final end = endDate ?? _lastCompletedOperationalDate(DateTime.now());
    final start = startDate ?? end.subtract(Duration(days: days - 1));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(end);

    final results = await Future.wait([
      _db
          .collection('presensi')
          .where('tanggal', isGreaterThanOrEqualTo: startKey)
          .where('tanggal', isLessThanOrEqualTo: endKey)
          .get(),
      _db.collection('users').get(),
      _db.collection('cabang').get(),
    ]);

    final userData = {
      for (final doc in (results[1] as QuerySnapshot<Map<String, dynamic>>).docs)
        doc.id: doc.data(),
    };
    final branchData = {
      for (final doc in (results[2] as QuerySnapshot<Map<String, dynamic>>).docs)
        doc.id: doc.data(),
    };

    final grouped = <String, Map<String, dynamic>>{};
    for (final doc in (results[0] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final shift = doc.data();
      final status = (shift['status_presensi'] ?? shift['status'])
          ?.toString()
          .toUpperCase();
      if (status != 'SELESAI' && status != 'TUTUP_SELESAI') continue;

      final employeeId = shift['id_karyawan']?.toString() ?? '';
      if (employeeId.isEmpty) continue;
      final hours = _shiftHours(shift);
      if (hours <= 0) continue;

      final profile = userData[employeeId] ?? const <String, dynamic>{};
      final branch = branchData[shift['id_cabang']?.toString()] ??
          const <String, dynamic>{};
      final wage = money(profile['tarif_per_jam'] ?? shift['tarif_per_jam']);
      final lateMinutes = _lateMinutes(shift, branch);
      final schedule = (branch['jam_operasional'] is Map)
          ? Map<String, dynamic>.from(branch['jam_operasional'] as Map)
          : branch;
      final rawRate = schedule['potongan_per_15_menit'];
      final deductionRate = rawRate == null ? 750.0 : money(rawRate);
      final deduction = lateMinutes == 0
          ? 0.0
          : ((lateMinutes + 14) ~/ 15) * deductionRate;

      final row = grouped.putIfAbsent(employeeId, () => {
        'id': employeeId,
        'name': profile['nama']?.toString() ??
            shift['nama_karyawan']?.toString() ??
            'Karyawan',
        'days': 0,
        'hours': 0.0,
        'gross': 0.0,
        'deduction': 0.0,
        'lateMinutes': 0,
      });
      row['days'] = (row['days'] as int) + 1;
      row['hours'] = (row['hours'] as double) + hours;
      row['gross'] = (row['gross'] as double) + (hours * wage);
      row['deduction'] = (row['deduction'] as double) + deduction;
      row['lateMinutes'] = (row['lateMinutes'] as int) + lateMinutes;
    }

    final records = grouped.values.map((row) {
      final gross = row['gross'] as double;
      final deduction = row['deduction'] as double;
      return PayrollRecord(
        id: row['id'] as String,
        name: row['name'] as String,
        days: row['days'] as int,
        hours: row['hours'] as double,
        gross: gross,
        deduction: deduction,
        lateMinutes: row['lateMinutes'] as int,
        net: max(0.0, gross - deduction),
      );
    }).toList();
    records.sort((a, b) => b.net.compareTo(a.net));
    return records;
  }

  Future<List<BonusRecord>> bonus({
    int days = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? _lastCompletedOperationalDate(DateTime.now());
    final start = startDate ?? end.subtract(Duration(days: days - 1));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(end);

    final results = await Future.wait([
      _db
          .collection('laporan_shift')
          .where('tanggal_operasional', isGreaterThanOrEqualTo: startKey)
          .where('tanggal_operasional', isLessThanOrEqualTo: endKey)
          .get(),
      _db
          .collection('presensi')
          .where('tanggal', isGreaterThanOrEqualTo: startKey)
          .where('tanggal', isLessThanOrEqualTo: endKey)
          .get(),
      _db.collection('users').get(),
    ]);

    final userData = {
      for (final doc in (results[2] as QuerySnapshot<Map<String, dynamic>>).docs)
        doc.id: doc.data(),
    };
    final hoursByShift = <String, double>{};
    for (final doc in (results[1] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final shift = doc.data();
      final status = (shift['status_presensi'] ?? shift['status'])
          ?.toString()
          .toUpperCase();
      if (status != 'SELESAI' && status != 'TUTUP_SELESAI') continue;
      final employeeId = shift['id_karyawan']?.toString() ?? '';
      final date = shift['tanggal']?.toString() ?? '';
      if (employeeId.isEmpty || date.isEmpty) continue;
      hoursByShift['$employeeId|$date'] = _shiftHours(shift);
    }

    // Satu laporan per karyawan per tanggal operasional, agar duplikasi laporan
    // tidak menggandakan jumlah roti maupun target bonus.
    final uniqueReports = <String, Map<String, dynamic>>{};
    for (final doc in (results[0] as QuerySnapshot<Map<String, dynamic>>).docs) {
      final report = doc.data();
      final employeeId = report['id_karyawan']?.toString() ?? '';
      final date = report['tanggal_operasional']?.toString() ?? '';
      if (employeeId.isEmpty || date.isEmpty) continue;
      uniqueReports.putIfAbsent('$employeeId|$date', () => report);
    }

    final grouped = <String, Map<String, dynamic>>{};
    for (final entry in uniqueReports.entries) {
      final report = entry.value;
      final parts = entry.key.split('|');
      final employeeId = parts[0];
      final date = parts[1];
      final hours = hoursByShift[entry.key] ?? 0;
      final target = bonusTargetForHours(hours);
      // Belum ada target bonus yang ditetapkan untuk shift di bawah 8 jam.
      if (target == 0) continue;

      final breadStart = money(report['roti_awal'] ?? report['roti_diantar']);
      final breadLeft = money(report['roti_sisa']);
      final damaged = money(report['roti_rusak_bonus']);
      final sold = report['roti_terjual'] == null
          ? max(0, (breadStart - breadLeft - damaged).round())
          : money(report['roti_terjual']).round();

      final profile = userData[employeeId] ?? const <String, dynamic>{};
      final row = grouped.putIfAbsent(employeeId, () => {
        'id': employeeId,
        'name': profile['nama']?.toString() ??
            report['nama_karyawan']?.toString() ??
            'Karyawan',
        'days': 0,
        'hours': 0.0,
        'sold': 0,
        'target': 0,
      });
      row['days'] = (row['days'] as int) + 1;
      row['hours'] = (row['hours'] as double) + hours;
      row['sold'] = (row['sold'] as int) + sold;
      row['target'] = (row['target'] as int) + target;
    }

    final records = grouped.values.map((row) {
      final sold = row['sold'] as int;
      final target = row['target'] as int;
      return BonusRecord(
        id: row['id'] as String,
        name: row['name'] as String,
        days: row['days'] as int,
        totalHours: row['hours'] as double,
        sold: sold,
        target: target,
        excess: max(0, sold - target),
      );
    }).toList();
    records.sort((a, b) => b.excess.compareTo(a.excess));
    return records;
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

DateTime _lastCompletedOperationalDate(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: now.hour < 5 ? 2 : 1));
}

int _minutesFromTime(dynamic value) {
  final text = value?.toString() ?? '';
  final match = RegExp(r'(\\d{1,2}):(\\d{2})').firstMatch(text);
  if (match == null) return -1;
  final hour = int.tryParse(match.group(1)!) ?? -1;
  final minute = int.tryParse(match.group(2)!) ?? -1;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return -1;
  return hour * 60 + minute;
}

double _shiftHours(Map<String, dynamic> shift) {
  final stored = money(shift['total_jam']);
  if (stored > 0) return stored;
  final start = _minutesFromTime(shift['jam_masuk']);
  final end = _minutesFromTime(shift['jam_pulang']);
  if (start < 0 || end < 0) return 0;
  var minutes = end - start;
  if (minutes < 0) minutes += 1440;
  return minutes / 60;
}

int _lateMinutes(
  Map<String, dynamic> shift,
  Map<String, dynamic> branch,
) {
  final schedule = branch['jam_operasional'] is Map
      ? Map<String, dynamic>.from(branch['jam_operasional'] as Map)
      : branch;
  final opening = _minutesFromTime(
    schedule['jam_buka'] ?? schedule['jam_operasional_mulai'],
  );
  final checkIn = _minutesFromTime(shift['jam_masuk']);
  if (opening < 0 || checkIn < 0) return 0;
  final tolerance = money(
    schedule['toleransi_terlambat_menit'] ?? schedule['toleransi_menit'],
  ).round();
  return max(0, checkIn - opening - tolerance);
}

/// Target per shift sesuai ketentuan operasional. Jam kerja dibulatkan ke
/// jam terdekat karena target ditentukan dalam satuan jam bulat.
int bonusTargetForHours(double hours) {
  if (hours < 7.5) return 0;
  switch (hours.round().clamp(8, 14).toInt()) {
    case 8:
      return 55;
    case 9:
      return 62;
    case 10:
      return 69;
    case 11:
      return 75;
    case 12:
      return 82;
    case 13:
      return 89;
    default:
      return 96;
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
    required this.gross,
    required this.deduction,
    required this.lateMinutes,
    required this.net,
  });
  final String id, name;
  final int days, lateMinutes;
  final double hours, gross, deduction, net;
}

class BonusRecord {
  const BonusRecord({
    required this.id,
    required this.name,
    required this.days,
    required this.totalHours,
    required this.sold,
    required this.target,
    required this.excess,
  });
  final String id, name;
  final int days, sold, target, excess;
  final double totalHours;
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
