# swapspace

A new Flutter project.

## Local Firebase Config

1. Copy `.env.example` to `.env`.
2. Fill in the Firebase values for the platforms you use.
3. Keep `.env` out of git; it is already listed in `.gitignore`.
4. Run `flutter pub get` and then `flutter run`.

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
