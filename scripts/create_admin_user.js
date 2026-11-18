// scripts/create_admin_user.js
// Script seeder untuk menginisialisasi akun Admin utama, Cabang awal, dan Katalog Menu di Firebase.

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const keyPath = path.join(__dirname, '..', 'serviceAccountKey.json');

if (!fs.existsSync(keyPath)) {
  console.error('\n[ERROR] File serviceAccountKey.json belum ditemukan di root project.');
  console.log('Unduh dari: Firebase Console -> Project Settings -> Service accounts -> Generate new private key');
  console.log('Lalu letakkan file tersebut di folder project ini dengan nama: serviceAccountKey.json\n');
  process.exit(1);
}

const serviceAccount = require(keyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

// Kredensial akun admin utama
const ADMIN_USERNAME = 'admin';
const ADMIN_EMAIL = `${ADMIN_USERNAME}@rbb.app`;
const ADMIN_PASSWORD = 'admin';
const ADMIN_UID = 'admin_borneo_utama';

// Daftar katalog menu awal (porsi utuh & separuh)
const DAFTAR_MENU = [
  { nama: 'Mentega Saja', harga_utuh: 8000, harga_separuh: 6000, urutan: 1 },
  { nama: 'Mentega Susu', harga_utuh: 10000, harga_separuh: 6000, urutan: 2 },
  { nama: 'Coklat Selai Buah', harga_utuh: 14000, harga_separuh: 8000, urutan: 3 },
  { nama: 'Coklat Full', harga_utuh: 15000, harga_separuh: 8000, urutan: 4 },
  { nama: 'Coklat Keju Pisah', harga_utuh: 17000, harga_separuh: 11000, urutan: 5 },
  { nama: 'Coklat Keju Campur', harga_utuh: 19000, harga_separuh: 12000, urutan: 6 },
  { nama: 'Keju Full', harga_utuh: 18000, harga_separuh: 10000, urutan: 7 },
  { nama: 'Durian Full', harga_utuh: 16000, harga_separuh: 8000, urutan: 8 },
  { nama: 'Vanilla Full', harga_utuh: 16000, harga_separuh: 10000, urutan: 9 },
  { nama: 'Tiramisu Full', harga_utuh: 21000, harga_separuh: 11000, urutan: 10 },
  { nama: 'Greentea Full', harga_utuh: 21000, harga_separuh: 11000, urutan: 11 },
  { nama: 'Taro Full', harga_utuh: 21000, harga_separuh: 11000, urutan: 12 },
  { nama: 'Chococrunchy Full', harga_utuh: 22000, harga_separuh: 12000, urutan: 13 },
  { nama: 'Chococrunchy Keju Mix', harga_utuh: 25000, harga_separuh: 13000, urutan: 14 },
];

async function seed() {
  console.log('--- Memulai Seeding Firebase Roti Bakar Borneo ---');

  let uid = ADMIN_UID;
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL).catch(() => null);
    if (existing) {
      console.log(`Akun Auth [${ADMIN_EMAIL}] sudah ada (UID: ${existing.uid}).`);
      uid = existing.uid;
    } else {
      const user = await auth.createUser({
        uid: ADMIN_UID,
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        displayName: 'Boss Admin Borneo',
        emailVerified: true,
      });
      console.log(`[SUKSES] Akun Auth admin dibuat: ${ADMIN_EMAIL} (UID: ${user.uid})`);
      uid = user.uid;
    }

    // 1. Tambah/update profil admin di Firestore koleksi 'users'
    await db.collection('users').doc(uid).set({
      username: ADMIN_USERNAME,
      nama: 'Boss Admin Borneo',
      role: 'ADMIN',
      id_cabang: 'PUSAT',
      foto_profil_url: '',
      dibuat_pada: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`[SUKSES] Profil Firestore 'users/${uid}' berhasil disimpan.`);

    // 2. Buat Cabang Utama awal jika belum ada
    const cabangRef = db.collection('cabang').doc('CABANG-01');
    const cabangDoc = await cabangRef.get();
    if (!cabangDoc.exists) {
      await cabangRef.set({
        nama_cabang: 'Outlet Pusat Borneo',
        latitude: -1.265386,
        longitude: 116.831200,
        radius_meter: 100,
        dibuat_oleh: uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('[SUKSES] Data cabang awal [Outlet Pusat Borneo] berhasil dibuat.');
    }

    // 3. Seeding Katalog Menu (Porsi Utuh & Separuh)
    console.log('[INFO] Memeriksa dan seeding koleksi menu...');
    for (const menu of DAFTAR_MENU) {
      const docId = menu.nama.toLowerCase().replace(/[^a-z0-9]/g, '_');
      await db.collection('menu').doc(docId).set({
        nama: menu.nama,
        harga_utuh: menu.harga_utuh,
        harga_separuh: menu.harga_separuh,
        urutan: menu.urutan,
        aktif: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    console.log(`[SUKSES] ${DAFTAR_MENU.length} Menu berhasil disimpan ke koleksi 'menu'.`);

    console.log('\n======================================================');
    console.log('SEEDING SELESAI!');
    console.log(`Username Login : ${ADMIN_USERNAME}`);
    console.log(`Password Login : ${ADMIN_PASSWORD}`);
    console.log('======================================================\n');
  } catch (error) {
    console.error('[GAGAL] Terjadi kesalahan saat seeding:', error);
  }
}

seed();
