import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession({
    required this.idKaryawan,
    required this.nama,
    required this.role,
    required this.idCabang,
    this.fotoProfilUrl,
  });
  final String idKaryawan;
  final String nama;
  final String role;
  final String idCabang;
  final String? fotoProfilUrl;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isBos => role.toUpperCase() == 'BOS';

  static const _idKey = 'session.id_karyawan';
  static const _namaKey = 'session.nama';
  static const _roleKey = 'session.role';
  static const _cabangKey = 'session.id_cabang';
  static const _fotoKey = 'session.foto_profil_url';

  static Future<AppSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    if (id == null || id.isEmpty) return null;
    return AppSession(
      idKaryawan: id,
      nama: prefs.getString(_namaKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'KARYAWAN',
      idCabang: prefs.getString(_cabangKey) ?? '',
      fotoProfilUrl: prefs.getString(_fotoKey),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, idKaryawan);
    await prefs.setString(_namaKey, nama);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_cabangKey, idCabang);
    if (fotoProfilUrl != null && fotoProfilUrl!.isNotEmpty) {
      await prefs.setString(_fotoKey, fotoProfilUrl!);
    }
  }

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).clear();
}
