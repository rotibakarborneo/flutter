# Firebase Setup Guide for Roti Bakar Borneo

This guide walks you through linking your existing Firebase project to the Flutter app and setting up the web dashboard.

## 1. Create / Select a Firebase Project
1. Open the Firebase console: https://console.firebase.google.com/
2. Click **Add project** (or select an existing one).
3. Give it a name, e.g. `roti-bakar-berau`. Click **Continue**.
4. Disable Google Analytics for the free Spark plan (you can enable later if you wish).
5. Click **Create project** and wait for it to finish.

## 2. Register Android App
1. In the project overview, click the **Android** icon **Add app**.
2. **Android package name**: use the one defined in `android/app/build.gradle`. By default it is `com.example.roti_bakar_borneo`. If you changed it, use your package name.
3. **App nickname** (optional): `RotiBakarAndroid`.
4. Click **Register app**.
5. **Download `google-services.json`** when prompted.
6. Place the file in the Flutter project: 
   ```
   <project_root>/android/app/google-services.json
   ```
7. In the same screen, click **Next** until the end and then **Finish**.

## 3. Register Web App (for the dashboard)
1. Back in the console, click the **Web** icon **Add app**.
2. **App nickname**: `RotiBakarWeb`.
3. Check **Also set up Firebase Hosting now** if you want to deploy later, otherwise you can skip.
4. Click **Register app**.
5. You will see a config snippet like:
   ```js
   const firebaseConfig = {
     apiKey: "...",
     authDomain: "...",
     projectId: "...",
     storageBucket: "...",
     messagingSenderId: "...",
     appId: "..."
   };
   ```
   Save these values – the Flutter web build will pick them up automatically from the generated `firebase_options.dart` after running `flutterfire configure` (see step 5).

## 4. Enable Firestore (Database)
1. In the left sidebar, go to **Build > Firestore Database**.
2. Click **Create database**.
3. Choose **Start in test mode** (allows open read/write for development). You can lock it down later.
4. Choose a Cloud Firestore location (default is fine).
5. Click **Enable**.

## 5. (Optional) Enable Firebase Storage
If you want to store high‑resolution photos instead of Base64 strings:
1. Go to **Storage** in the left menu.
2. Click **Get started** and follow the wizard.
3. Use the default rules (read/write for authenticated users) for development.
> **Note:** Enabling Storage on the Spark (free) plan works but has a limited quota. The app currently stores selfies as Base64, so you can skip this step unless you need larger files.

## 6. Configure the Flutter project
Run the FlutterFire CLI to generate the `firebase_options.dart` file that contains the config for Android, iOS, and Web.
```bash
# Install the CLI (once)
dart pub global activate flutterfire_cli
# Add it to your PATH (Windows PowerShell)
$env:PATH += ";$env:APPDATA\Pub\Cache\bin"
# Navigate to the project root
cd C:\Users\User\AndroidStudioProjects\roti_bakar_borneo_flutter
# Configure
flutterfire configure
```
- Select the Firebase project you created.
- Choose the platforms you need (Android, iOS, Web).
- The CLI will write `lib/firebase_options.dart` and update Android and iOS files automatically.

## 7. Add the `google-services.json` file
Make sure the file you downloaded in step 2 is located at:
```
<project_root>/android/app/google-services.json
```
If you renamed any directories, adjust the path in `android/app/build.gradle` accordingly.

## 8. Verify the setup
Run the app on an Android device or emulator:
```bash
flutter run
```
Open the web dashboard locally:
```bash
flutter run -d chrome
```
If no runtime errors appear and you can see data updating in Firestore (use the console to watch changes), the setup is complete.

---
**Tips**
- When you are ready to go production, change Firestore rules from test mode to a secure set.
- To add a Gemini API key, open the app → Settings → Gemini → Paste your key.
- For deployment, see `scripts/deploy.sh`.
