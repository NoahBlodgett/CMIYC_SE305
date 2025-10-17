# Frontend (Flutter)

This folder contains the Flutter frontend app.

## Prerequisites
- Flutter SDK installed and on PATH
- VS Code with Flutter & Dart extensions (recommended)
- Android Studio (for Android emulator) or Chrome (for Web)

## Install dependencies
```
flutter pub get
```

## Useful commands
```
# Analyze code with lints
flutter analyze

# Run tests
flutter test

# Run on Chrome (web)
flutter run -d chrome

# Run on Android (if you have an emulator/device)
flutter devices
flutter run -d <device-id>
```

## Assets & Fonts
Add your assets under `assets/` and fonts under `assets/fonts/` then update `pubspec.yaml` accordingly (see commented sections).

Example structure:
```
frontend/lib/
  assets/
    images/
    icons/
  assets/fonts/
    Inter-Regular.ttf
``` 

Enable them by uncommenting the `assets:` and `fonts:` sections in `pubspec.yaml` and pointing to the correct paths.

## Notes
- `analysis_options.yaml` enables recommended Flutter lints via `flutter_lints`.
- `publish_to: 'none'` prevents accidental publishing to pub.dev.
- The SDK constraints are set to be compatible with recent stable Flutter versions. Update if you upgrade Flutter.
