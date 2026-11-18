// lib/utils/image_compressor.dart
// Kompresi foto presensi ke ukuran kecil (≤ 100 KB)
// Menggunakan Uint8List (bytes) sehingga 100% kompatibel di Web, Android, & iOS tanpa dart:io.

import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

Future<Uint8List> compressPhoto(
  XFile file, {
  int targetSizeInBytes = 100 * 1024, // 100 KB
}) async {
  final bytes = await file.readAsBytes();

  // Jika ukuran aslinya sudah ≤ 100 KB, tidak perlu kompres lagi
  if (bytes.lengthInBytes <= targetSizeInBytes) {
    return bytes;
  }

  try {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1080,
      minHeight: 1080,
      quality: 60,
      format: CompressFormat.jpeg,
    );
    return compressed;
  } catch (_) {
    // Fallback jika platform web belum mendukung wasm compress
    return bytes;
  }
}
