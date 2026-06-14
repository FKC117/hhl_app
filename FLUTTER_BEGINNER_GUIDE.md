# HHL Flutter Beginner Guide

This project is the Flutter mobile app. Run commands from:

```powershell
cd F:\hhl_app\hhl_application
```

## 1. One-time computer setup

Flutter is already installed at `C:\Users\Lenovo\flutter`, but its `bin` folder
is not currently available on this computer's `PATH`.

1. Open Windows search and type **environment variables**.
2. Open **Edit environment variables for your account**.
3. Edit `Path`, add `C:\Users\Lenovo\flutter\bin`, and save.
4. Install Android Studio and its Android SDK/emulator if they are missing.
5. Close and reopen PowerShell, then run:

```powershell
flutter doctor
flutter doctor --android-licenses
flutter devices
```

Resolve every red item reported by `flutter doctor` that relates to Android.

Until `PATH` is fixed, any Flutter command can be run with the full path:

```powershell
& C:\Users\Lenovo\flutter\bin\flutter.bat doctor
```

## 2. Open the project in a terminal

```powershell
cd F:\hhl_app\hhl_application
Get-Location
```

`Get-Location` should print `F:\hhl_app\hhl_application`.

Useful navigation commands:

```powershell
cd ..              # move up one folder
cd folder_name     # enter a folder
Get-ChildItem      # list files in the current folder
```

## 3. Start the app without the backend

The current UI prototype does not need Django yet.

1. Open Android Studio.
2. Open **Device Manager** and start an Android emulator.
3. In PowerShell, run:

```powershell
cd F:\hhl_app\hhl_application
flutter pub get
flutter devices
flutter run
```

While `flutter run` is active:

```text
r = hot reload after a code change
R = full hot restart
q = stop the app
```

## 4. Run in Chrome for the quickest UI preview

```powershell
cd F:\hhl_app\hhl_application
flutter run -d chrome
```

Chrome is useful for fast UI work. Android must still be tested before release.

To make Chrome look more like a phone while designing:

1. Open Chrome DevTools with `F12`
2. Click the device toolbar icon
3. Choose a phone size like `Pixel 7` or `iPhone SE`

That gives you a phone-sized preview, but it is still a web build.

## 4.1 See the real mobile app look

For the real mobile-app feel, run the Android emulator:

```powershell
cd F:\hhl_app\hhl_application
flutter devices
flutter run -d emulator-5554
```

Your emulator device name may be different, so first check it with `flutter devices`.

Why this matters:

- `flutter run -d chrome` shows the Flutter web version in a browser
- `flutter run` on an Android emulator shows the actual Android app UI
- We can design fast in Chrome, then verify the true mobile feel in the emulator

## 5. Start Flutter and Django together later

Use two PowerShell windows.

Backend terminal, from the Django project:

```powershell
.\venv\Scripts\python.exe .\hhl\manage.py runserver 0.0.0.0:8000
```

Flutter terminal:

```powershell
cd F:\hhl_app\hhl_application
flutter run
```

Android emulator API URL:

```text
http://10.0.2.2:8000/api/v1/
```

Do not use `localhost` for the Android emulator; inside the emulator, `localhost`
means the emulator itself.

## 6. Check code before each milestone

```powershell
flutter pub get
flutter format lib test
flutter analyze
flutter test
```

If `flutter format` is unavailable in your Flutter version, use:

```powershell
dart format lib test
```

## Current milestone

- Material 3 healthcare theme
- Responsive login screen
- App router with login to shell flow
- Chat-first home screen
- Bottom navigation on mobile
- Navigation rail on wide screens
- Doctors tab connected to live backend endpoints
- Reports and profile starter screens
- Service shortcuts and emergency warning
- Working prototype navigation and message composer
- First API connection added for doctors

Next milestone: connect real login, token storage, and protected API requests.
