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

## Targeted Test Runs
```bash
flutter test test/unit
flutter test test/widget
```

## Integration Tests
> Requires a device or emulator (or a web target).

```bash
flutter test integration_test
```

## Regenerate Code (if needed)
```bash
dart run build_runner build --delete-conflicting-outputs
```
