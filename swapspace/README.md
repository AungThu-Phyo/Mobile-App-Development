# swapspace

A new Flutter project.

## Local Firebase Config

1. Copy `.env.example` to `.env`.
2. Fill in the Firebase values for the platforms you use.
3. Keep `.env` out of git; it is already listed in `.gitignore`.
4. Run `flutter pub get` and then `flutter run`.

## Firebase App Check Setup

This app already calls App Check activation in [lib/main.dart](lib/main.dart).

### 1) Firebase Console Configuration

1. Open Firebase Console -> Build -> App Check.
2. Register each app in this project:
	- Android: Play Integrity (recommended for release).
	- iOS: App Attest (fallback to DeviceCheck in Console if needed).
	- Web: reCAPTCHA v3.
3. For Web, copy the reCAPTCHA v3 site key.

### 2) Local Environment

Add the site key to your local `.env` file:

APP_CHECK_WEB_RECAPTCHA_SITE_KEY=your-recaptcha-v3-site-key

For Web builds without `.env`, you can also pass:

--dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=your-recaptcha-v3-site-key

### 3) Debug Testing Notes

- Android debug builds use Android Debug provider in code.
- iOS debug builds use Apple Debug provider in code.
- Register debug tokens shown in logs under App Check -> Manage debug tokens.

### 4) Enforce App Check

After verifying clients are sending valid tokens, enable enforcement in App Check for:

- Cloud Firestore
- Firebase Authentication (if used in your project setup)

Roll out enforcement gradually to avoid blocking older app builds.

## CI/CD Auto Deploy

This repository is configured to auto-deploy from GitHub workflow runs on push.

Recommended pre-push checks:

1. Run `flutter pub get`
2. Run `flutter test --no-pub`
3. Run `flutter build web --pwa-strategy=none`

Notes:

- The `--pwa-strategy` flag is currently deprecated in Flutter and may be removed in a future release.
- Ensure `.env` exists in the project root because it is declared as a Flutter asset in `pubspec.yaml`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference..
