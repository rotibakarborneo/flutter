import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

class EmployeeRepository {
  EmployeeRepository([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  factory EmployeeRepository.live() => EmployeeRepository();

  final FirebaseFirestore _db;

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<ShiftContext> context(AppSession session) async {
    try {
      // Ambil laporan shift kemarin/terakhir untuk cabang ini
      final snap = await _db
          .collection('laporan_shift')
          .where('id_cabang', isEqualTo: session.idCabang)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      int leftover = 0;
      if (snap.docs.isNotEmpty) {
        leftover = (snap.docs.first.data()['roti_sisa'] as num?)?.toInt() ?? 0;
      }

      // Hitung total penjualan kasir hari ini di cabang ini
      final today = _todayStr();
      final kasirSnap = await _db
          .collection('transaksi_kasir')
          .where('id_cabang', isEqualTo: session.idCabang)
          .where('tanggal_operasional', isEqualTo: today)
          .get();

      double sales = 0;
      for (final doc in kasirSnap.docs) {
        sales += (doc.data()['total_bayar'] as num?)?.toDouble() ?? 0.0;
      }

      return ShiftContext(leftover: leftover, cashierSales: sales);
    } catch (_) {
      return const ShiftContext(leftover: 0, cashierSales: 0);
    }
  }

  Future<EmployeePerformance> performance(AppSession session) async {
    try {
      final today = _todayStr();
      final presensiSnap = await _db
          .collection('presensi')
          .where('id_karyawan', isEqualTo: session.idKaryawan)
          .where('tanggal', isEqualTo: today)
          .limit(1)
          .get();

      String status = 'BELUM_ABSEN';
      double hours = 0.0;
      double wage = 0.0;

      if (presensiSnap.docs.isNotEmpty) {
        final data = presensiSnap.docs.first.data();
        status = data['status_presensi']?.toString() ?? 'HADIR';
        hours = (data['total_jam'] as num?)?.toDouble() ?? 0.0;
        wage = (data['estimasi_gaji'] as num?)?.toDouble() ?? 0.0;
      }

      return EmployeePerformance(hours: hours, wage: wage, status: status);
    } catch (_) {
      return const EmployeePerformance(
        hours: 0,
        wage: 0,
        status: 'BELUM_ABSEN',
      );
    }
  }

  Future<String> saveCashier(
    AppSession session,
    List<Map<String, dynamic>> items,
    String payment, {
    double? uangDibayar,
    double? kembalian,
  }) async {
    final today = _todayStr();
    final trxId =
        'RBB-${DateFormat('yyMMdd').format(DateTime.now())}-${Random().nextInt(9000) + 1000}';

    double totalBayar = 0;
    double totalRoti = 0;
    for (final it in items) {
      final qty = (it['qty'] as num?)?.toDouble() ?? 1;
      final harga = (it['harga'] as num?)?.toDouble() ?? 0;
      totalBayar += qty * harga;
      totalRoti += qty;
    }

    await _db.collection('transaksi_kasir').add({
      'transaksi_id': trxId,
      'id_karyawan': session.idKaryawan,
      'nama_karyawan': session.nama,
      'id_cabang': session.idCabang,
      'tanggal_operasional': today,
      'items': items,
      'metode_bayar': payment,
      'total_bayar': totalBayar,
      'uang_dibayar': uangDibayar ?? totalBayar,
      'kembalian': kembalian ?? 0.0,
      'total_roti': totalRoti,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return trxId;
  }

  Future<void> saveReport(
    AppSession session, {
    required int delivered,
    required int leftover,
    required int damaged,
    required double expense,
    required double deposit,
    required double floatCash,
    required String note,
  }) async {
    final today = _todayStr();
    await _db.collection('laporan_shift').add({
      'id_karyawan': session.idKaryawan,
      'id_cabang': session.idCabang,
      'tanggal_operasional': today,
      'roti_diantar': delivered,
      'roti_awal': delivered,
      'roti_sisa': leftover,
      'roti_rusak_bonus': damaged,
      'pengeluaran': expense,
      'setor_uang': deposit,
      'sisa_modal': floatCash,
      'catatan': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<EmployeeHistory> history(
    AppSession session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final today = endDate ?? DateTime.now();
    final start = startDate ?? today.subtract(const Duration(days: 30));
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(today);

    final presensiSnap = await _db
        .collection('presensi')
        .where('id_karyawan', isEqualTo: session.idKaryawan)
        .where('tanggal', isGreaterThanOrEqualTo: startKey)
        .where('tanggal', isLessThanOrEqualTo: endKey)
        .orderBy('tanggal', descending: true)
        .get();

    final shifts = presensiSnap.docs
        .map((d) => ShiftHistory.fromJson(d.data()))
        .toList();

    final reportSnap = await _db
        .collection('laporan_shift')
        .where('id_karyawan', isEqualTo: session.idKaryawan)
        .where('tanggal_operasional', isGreaterThanOrEqualTo: startKey)
        .where('tanggal_operasional', isLessThanOrEqualTo: endKey)
        .orderBy('tanggal_operasional', descending: true)
        .get();

    final reports = reportSnap.docs
        .map((d) => ShiftReportHistory.fromJson(d.data()))
        .toList();

    return EmployeeHistory(shifts: shifts, reports: reports);
  }

  Future<List<BonRecord>> bonSaya(AppSession session) async {
    final snap = await _db
        .collection('bon')
        .where('id_karyawan', isEqualTo: session.idKaryawan)
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) => BonRecord.fromJson(d.data())).toList();
  }

  Future<void> ajukanBon(
    AppSession session, {
    required double nominal,
    required String note,
  }) async {
    final id =
        'BON-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    await _db.collection('bon').add({
      'bon_id': id,
      'id_karyawan': session.idKaryawan,
      'nama_karyawan': session.nama,
      'id_cabang': session.idCabang,
      'nominal': nominal,
      'catatan': note,
      'status': 'MENUNGGU',
      'dibuat_pada': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'dibayar': 0.0,
      'sisa_bon': nominal,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAttendance(
    AppSession session, {
    required bool checkIn,
    required double latitude,
    required double longitude,
    required String photoBase64,
  }) async {
    final today = _todayStr();
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    // Cari apakah sudah ada data presensi hari ini
    final existSnap = await _db
        .collection('presensi')
        .where('id_karyawan', isEqualTo: session.idKaryawan)
        .where('tanggal', isEqualTo: today)
        .limit(1)
        .get();

    if (existSnap.docs.isNotEmpty) {
      final docRef = existSnap.docs.first.reference;
      if (!checkIn) {
        await docRef.update({
          'jam_pulang': timeStr,
          'lat_pulang': latitude,
          'lng_pulang': longitude,
          'status_presensi': 'SELESAI',
        });
      } else {
        await docRef.update({
          'jam_masuk': timeStr,
          'lat': latitude,
          'lng': longitude,
          'status_presensi': 'HADIR',
        });
      }
    } else {
      await _db.collection('presensi').add({
        'id_karyawan': session.idKaryawan,
        'nama_karyawan': session.nama,
        'id_cabang': session.idCabang,
        'tanggal': today,
        'jam_masuk': checkIn ? timeStr : '-',
        'jam_pulang': checkIn ? '-' : timeStr,
        'status_presensi': checkIn ? 'HADIR' : 'PULANG',
        'lat': latitude,
        'lng': longitude,
        'foto_base64': photoBase64, // Disimpan langsung di Firestore (karena sudah dikompresi ≤ 100 KB)
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> uploadProfilePhoto(
    AppSession session,
    String photoBase64,
  ) async {
    await _db.collection('users').doc(session.idKaryawan).update({
      'foto_profil_url': photoBase64,
    });
  }
}

double _money(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

class ShiftContext {
  const ShiftContext({required this.leftover, required this.cashierSales});
  final int leftover;
  final double cashierSales;
}

class EmployeePerformance {
  const EmployeePerformance({
    required this.hours,
    required this.wage,
    required this.status,
  });
  final double hours, wage;
  final String status;
}

class EmployeeHistory {
  const EmployeeHistory({required this.shifts, required this.reports});
  final List<ShiftHistory> shifts;
  final List<ShiftReportHistory> reports;
}

class ShiftHistory {
  const ShiftHistory({
    required this.employeeId,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });
  final String employeeId, date, checkIn, checkOut, status;
  factory ShiftHistory.fromJson(Map<String, dynamic> json) => ShiftHistory(
    employeeId: json['id_karyawan']?.toString() ?? '',
    date: json['tanggal']?.toString() ?? '',
    checkIn: json['jam_masuk']?.toString() ?? '-',
    checkOut: json['jam_pulang']?.toString() ?? '-',
    status: json['status_presensi']?.toString() ?? '',
  );
}

class ShiftReportHistory {
  const ShiftReportHistory({
    required this.employeeId,
    required this.date,
    required this.breadStart,
    required this.breadLeft,
    required this.sold,
    required this.deposit,
    required this.note,
  });
  final String employeeId, date, note;
  final double breadStart, breadLeft, sold, deposit;
  factory ShiftReportHistory.fromJson(Map<String, dynamic> json) =>
      ShiftReportHistory(
        employeeId: json['id_karyawan']?.toString() ?? '',
        date: json['tanggal_operasional']?.toString() ?? '',
        breadStart: _money(json['roti_awal']),
        breadLeft: _money(json['roti_sisa']),
        sold: _money(
          json['roti_terjual'] ??
              ((json['roti_awal'] as num? ?? 0) -
                  (json['roti_sisa'] as num? ?? 0)),
        ),
        deposit: _money(json['setor_uang']),
        note: json['catatan']?.toString() ?? '',
      );
}

class BonRecord {
  const BonRecord({
    required this.id,
    required this.amount,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.paid,
    required this.remaining,
  });
  final String id, note, status, createdAt;
  final double amount, paid, remaining;
  factory BonRecord.fromJson(Map<String, dynamic> json) => BonRecord(
    id: json['bon_id']?.toString() ?? '',
    amount: _money(json['nominal']),
    note: json['catatan']?.toString() ?? '',
    status: json['status']?.toString() ?? 'MENUNGGU',
    createdAt: json['dibuat_pada']?.toString() ?? '',
    paid: _money(json['dibayar']),
    remaining: _money(json['sisa_bon']),
  );
}
