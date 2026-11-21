// scripts/create_admin_custom.js
// ------------------------------------------------
// Buat atau perbarui akun admin dengan UID khusus, email, password,
// lalu buat profil di Firestore.
// ------------------------------------------------

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');
const fs = require('fs');

// Path ke service account yang di‑upload oleh user
const keyPath = "C:/Users/User/.gemini/antigravity/brain/ca285ecb-231b-4711-8094-b2697259dc6b/.user_uploaded/media_1795108603334_ab2ae053.json";
if (!fs.existsSync(keyPath)) {
  console.error('[ERROR] Service account file tidak ditemukan di', keyPath);
  process.exit(1);
}

const serviceAccount = require(keyPath);
initializeApp({ credential: cert(serviceAccount) });
const auth = getAuth();
const db = getFirestore();

// Data yang diminta user
const UID = 'BNLbYJyCEWcvKwNxt9KE2GNBC2K2';
const EMAIL = 'rotibakarborneo@gmail.com';
const PASSWORD = 'takonbose';
const DISPLAY_NAME = 'Boss Admin Borneo';

async function main() {
  try {
    // Cek apakah user sudah ada (by UID)
    let userRecord;
    try {
      userRecord = await auth.getUser(UID);
      console.log('[INFO] User sudah ada, memperbarui email/password/displayName');
      await auth.updateUser(UID, {
        email: EMAIL,
        password: PASSWORD,
        displayName: DISPLAY_NAME,
        emailVerified: true,
      });
    } catch (e) {
      // Jika tidak ada, buat baru dengan UID yang diberikan
      console.log('[INFO] Membuat user baru dengan UID khusus');
      userRecord = await auth.createUser({
        uid: UID,
        email: EMAIL,
        password: PASSWORD,
        displayName: DISPLAY_NAME,
        emailVerified: true,
      });
    }
    console.log(`[SUKSES] Auth user ${EMAIL} (uid=${userRecord.uid}) siap`);

    // Buat / perbarui profil di Firestore
    await db.collection('users').doc(userRecord.uid).set({
      username: 'admin',            // username yang dipakai di UI
      nama: 'Boss Admin Borneo',
      role: 'ADMIN',
      id_cabang: 'PUSAT',
      foto_profil_url: '',
    }, { merge: true });
    console.log('[SUKSES] Dokumen profil Firestore selesai');
  } catch (err) {
    console.error('[GAGAL] ', err);
  }
}

main().then(() => process.exit());
