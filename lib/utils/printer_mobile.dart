import 'package:flutter/material.dart';

/// Fallback sementara untuk platform mobile. Integrasi Bluetooth dapat
/// ditambahkan kembali setelah paket printer yang dipilih tersedia.
Future<void> printReceipt() async {
  debugPrint('Fitur cetak Bluetooth belum dikonfigurasi.');
}
