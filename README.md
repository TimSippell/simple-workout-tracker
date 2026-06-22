# Offline Workout Tracker

A minimal, offline-first workout tracker. Built with a shared C++ core library, with native apps for Android (Kotlin/Jetpack Compose), iOS (SwiftUI), and desktop (ImGui).

<p align="center">
  <img src="screenshots/Workout.png" alt="Active workout" width="270">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="screenshots/Exercises.png" alt="Exercise library" width="270">
</p>

<p align="center">
  <img src="screenshots/Desktop.png" alt="Desktop GUI" width="600">
</p>

## Features

- Track sets, reps, and weight for each exercise
- Built-in exercise library with muscle group and equipment tags
- Create and reuse workout templates
- Estimated one-rep max (e1RM) using the average of Epley and Brzycki formulas, with RPE adjustment
- View workout history and progress over time
- Weight unit conversion (kg/lbs)
- All data stored locally in SQLite — no account required

## Architecture

The core logic lives in a shared C++ library (`lib/`) backed by SQLite. This library is used by:

- **Android app** — Kotlin + Jetpack Compose, calls the C++ lib via JNI
- **iOS app** — SwiftUI, calls the C++ lib via a C bridge
- **Desktop GUI** — cross-platform ImGui + OpenGL interface
- **TUI** — terminal interface for desktop use

## Dependencies

### Core library (`lib/`)

- C++20 compiler (GCC 10+, Clang 12+)
- CMake 3.16+
- SQLite 3

### Desktop GUI (`gui/`)

- GLFW 3
- OpenGL 3+
- ImGui and ImPlot (included in `extern/`)

### TUI (`tui/`)

- ncurses (Linux/macOS) or PDCurses (Windows)

### Android app (`android/`)

- Android SDK (API 35) + NDK
- Gradle 8.11+
- Kotlin 2.1 + Jetpack Compose
- Java 17

### iOS app (`ios/`)

- Xcode 15+ (Swift 5.9+)
- iOS 15.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Building

### Linux (GUI + TUI)

```sh
./build-linux.sh            # release build (default)
./build-linux.sh debug      # debug build
```

### Windows (TUI)

Requires [vcpkg](https://vcpkg.io/) with PDCurses and SQLite3 installed:

```sh
vcpkg install pdcurses sqlite3
```

Set `VCPKG_ROOT` environment variable, then:

```sh
build-windows.bat            # release build (default)
build-windows.bat debug      # debug build
```

### Android APK

```sh
./build-android.sh          # release build (default)
./build-android.sh debug    # debug build
```

The script downloads the SQLite amalgamation automatically on first run.

### iOS

```sh
cd ios
./setup.sh                  # download SQLite + generate Xcode project
open OfflineWorkoutTracker.xcodeproj
```

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## License

MIT
