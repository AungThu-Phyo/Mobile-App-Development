# Test Execution Guide

## Prerequisites
- Flutter SDK installed
- Firebase config available for runtime (if running the full app)

## Install Dependencies
```bash
flutter pub get
```

## Static Analysis
```bash
flutter analyze
```

## Unit + Widget Tests
```bash
flutter test
```

## Coverage Report
```bash
flutter test --coverage
```

## Targeted Test Runs
```bash
flutter test test/unit
flutter test test/widget
```

## Integration Tests
> Requires a device or emulator. For emulator-based tests, run Firebase Emulators.

```bash
flutter test integration_test
```

### Firebase Emulator Run (recommended)
```bash
firebase emulators:start --only firestore,auth
```

Then run on an Android emulator (or pass a host IP for a physical device):
```bash
flutter test integration_test -d emulator-5554 \
	--dart-define=FIRESTORE_EMULATOR_HOST=10.0.2.2:8080 \
	--dart-define=FIREBASE_AUTH_EMULATOR_HOST=10.0.2.2:9099
```

## Regenerate Code (if needed)
```bash
dart run build_runner build --delete-conflicting-outputs
```
