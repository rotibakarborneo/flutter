import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_bakar_borneo_flutter/core/session/app_session.dart';

/// Domain email internal — username dikonversi ke email format ini.
const _emailDomain = 'rbb.app';

class AuthRepository {
  const AuthRepository();

  Future<AppSession> login({
    required String username,
    required String password,
  }) async {
    final email = '$username@$_emailDomain';
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) {
        throw const AuthException('Data profil tidak ditemukan.');
      }
      final data = doc.data()!;
      return AppSession(
        idKaryawan: uid,
        nama: data['nama']?.toString() ?? '',
        role: data['role']?.toString() ?? 'KARYAWAN',
        idCabang: data['id_cabang']?.toString() ?? '',
        fotoProfilUrl: data['foto_profil_url']?.toString(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthException('Username atau password tidak sesuai.');
        case 'user-disabled':
          throw const AuthException('Akun ini telah dinonaktifkan.');
        default:
          throw AuthException('Login gagal: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
