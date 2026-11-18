# Roti Bakar Borneo Flutter App

## Overview
This repository contains a Flutter application for the **Roti Bakar Borneo** business and a web dashboard for owners/managers.

- Android app with real‑time Firebase Firestore integration
- Push/local notifications for outlet open/close, shift reports, and bon requests
- Optional Gemini‑powered chatbot for business insights (offline fallback works without an API key)
- Web dashboard (Flutter web) that can be served locally or via Firebase Hosting

## Prerequisites
- **Flutter SDK** (latest stable) – make sure `flutter` is on your PATH.
- **Android SDK** (for building the APK) – Android Studio recommended.
- **Chrome** (for running the web dashboard locally).
- **Node.js** (optional, for Firebase CLI).
- **Firebase account** (free Spark plan is enough).

## Project Setup
1. **Clone / open the project** in Android Studio or VS Code.
2. Run `flutter pub get` to fetch dependencies.
3. Follow the **Firebase Setup Guide** (see `FIREBASE_SETUP_GUIDE.md`) to link your own Firebase project:
   - Add `google-services.json` in `android/app/`.
   - Enable Firestore (test mode works for development).
   - (Optional) Enable Firebase Storage if you want to store high‑resolution photos; otherwise the app stores selfies as Base64 strings.
4. (Optional) Provide a Gemini API key:
   - Open the app, go to **Settings → Gemini**, and paste your API key.
   - If omitted, the app uses an offline fallback.

## Running the Android App
```bash
# Connect a device or start an emulator
flutter devices
# Build and run in debug mode
flutter run
# Build a release APK
flutter build apk --release
# Install the APK on a device
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Running the Web Dashboard locally
```bash
flutter run -d chrome   # launches the web app in Chrome
# Or build static assets
flutter build web
# Serve the built files (requires a simple http server, e.g., Python)
python -m http.server 8080 -d build/web
```

## Deploying the Web Dashboard to Firebase Hosting
```bash
# Install Firebase CLI (once)
npm install -g firebase-tools
# Log in to Firebase
firebase login
# Initialise hosting (choose the existing Firebase project)
firebase init hosting
# When prompted, set the public directory to "build/web" and configure as a single‑page app.
# Deploy
firebase deploy --only hosting
```

## Notifications
- Android: Push notifications are handled via **Firebase Cloud Messaging**.
- Local notifications use `flutter_local_notifications`.
- Ensure the device has Google Play services and that you have granted the **POST_NOTIFICATIONS** permission.

## Troubleshooting
- **`flutter` not recognized** – make sure the Flutter SDK `bin` directory is added to your system `PATH`.
- **Firebase errors** – double‑check that `google-services.json` matches the package name `com.example.roti_bakar_borneo` (or your own package ID).
- **Gemini API key issues** – verify the key is valid and has access to the Generative AI API.

---
*Happy coding!*