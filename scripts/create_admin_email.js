// scripts/create_admin_email.js
// ------------------------------------------------
// Buat akun admin dengan email admin@rbb.app dan password takonbose,
// lalu buat profil di Firestore yang cocok dengan login UI.
// ------------------------------------------------

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');
const fs = require('fs');

// Service account (uploaded file)
const keyPath = "C:/Users/User/.gemini/antigravity/brain/ca285ecb-231b-4711-8094-b2697259dc6b/.user_uploaded/media_1795108603334_ab2ae053.json";
if (!fs.existsSync(keyPath)) {
  console.error('[ERROR] Service account not found at', keyPath);
  process.exit(1);
}
const serviceAccount = require(keyPath);
initializeApp({ credential: cert(serviceAccount) });

const auth = getAuth();
const db = getFirestore();

const EMAIL = 'admin@rbb.app';
const PASSWORD = 'takonbose';
const DISPLAY_NAME = 'Boss Admin Borneo';

async function main() {
  try {
    // Check if user already exists by email
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(EMAIL);
      console.log('[INFO] User already exists, updating password/displayName');
      await auth.updateUser(userRecord.uid, {
        password: PASSWORD,
        displayName: DISPLAY_NAME,
        emailVerified: true,
      });
    } catch (e) {
      console.log('[INFO] Creating new admin user');
      userRecord = await auth.createUser({
        email: EMAIL,
        password: PASSWORD,
        displayName: DISPLAY_NAME,
        emailVerified: true,
      });
    }
    console.log(`[SUKSES] Auth user ${EMAIL} (uid=${userRecord.uid}) ready`);

    // Create / update Firestore profile
    await db.collection('users').doc(userRecord.uid).set({
      username: 'admin',
      nama: 'Boss Admin Borneo',
      role: 'ADMIN',
      id_cabang: 'PUSAT',
      foto_profil_url: '',
    }, { merge: true });
    console.log('[SUKSES] Firestore profile for admin created/updated');
  } catch (err) {
    console.error('[GAGAL]', err);
  }
}

main().then(() => process.exit());
