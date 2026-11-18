import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:roti_bakar_borneo_flutter/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';
import 'package:roti_bakar_borneo_flutter/utils/image_compressor.dart';
import 'package:roti_bakar_borneo_flutter/core/network/employee_repository.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, required this.session});
  final AppSession session;
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  XFile? photo;
  Uint8List? photoBytes;
  bool working = false;
  String status = 'Siapkan GPS dan foto untuk presensi.';

  Future<void> ambilFoto() async {
    setState(() {
      working = true;
      status = 'Mengunci lokasi GPS…';
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw 'Izin lokasi wajib diberikan.';
      if (!await Geolocator.isLocationServiceEnabled())
        throw 'Nyalakan GPS perangkat terlebih dahulu.';
      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() => status = 'Membuka kamera…');
      XFile? shot;
      try {
        shot = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 65,
          maxWidth: 1280,
        );
      } catch (_) {
        shot = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 65,
          maxWidth: 1280,
        );
      }
      if (shot == null) {
        setState(() => status = 'Foto dibatalkan.');
        return;
      }
      final bytes = await compressPhoto(shot);
      setState(() {
        photo = shot;
        photoBytes = bytes;
        status = 'Foto siap. Pilih jenis presensi.';
      });
      if (!mounted) return;
      await pilihJenisPresensi(location);
    } catch (error) {
      if (mounted) {
        setState(() => status = 'Presensi belum berhasil.');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> pilihJenisPresensi(Position location) async {
    final checkIn = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Masuk shift'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Pulang shift'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (checkIn == null || photoBytes == null) return;
    await kirimPresensi(checkIn, location);
  }

  Future<void> kirimPresensi(bool checkIn, Position location) async {
    setState(() => working = true);
    try {
      await EmployeeRepository.live().saveAttendance(
        widget.session,
        checkIn: checkIn,
        latitude: location.latitude,
        longitude: location.longitude,
        photoBase64: base64Encode(photoBytes!),
      );
      if (!mounted) return;
      setState(
        () => status = checkIn
            ? 'Presensi masuk berhasil dikirim.'
            : 'Presensi pulang berhasil dikirim.',
      );
    } catch (error) {
      if (mounted) {
        setState(() => status = 'Presensi belum berhasil dikirim.');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI placeholder – replace with the original UI from main.dart if needed.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        backgroundColor: BorneoColors.background,
        foregroundColor: BorneoColors.text,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: working ? null : ambilFoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(working ? 'Memproses…' : 'Ambil foto presensi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
