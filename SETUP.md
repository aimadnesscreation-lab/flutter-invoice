# Development Setup Guide

This guide walks you through setting up a **lightweight Flutter development environment** on Linux Mint to work on the Invoice Pro app.

No Android Studio required — just the command-line tools (~200 MB vs 2 GB).

---

## Prerequisites

Open a terminal and install the required system packages:

```bash
sudo apt update
sudo apt install git curl unzip xz-utils zip libglu1-mesa \
     clang cmake ninja-build pkg-config libgtk-3-dev \
     liblzma-dev libstdc++-12-dev openjdk-17-jdk
```

---

## Step 1: Install Flutter

```bash
cd ~

# Download Flutter 3.44.0 (stable)
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.0-stable.tar.xz

# Extract it
tar xf flutter_linux_3.44.0-stable.tar.xz

# (Optional) Delete the archive to save space
rm flutter_linux_3.44.0-stable.tar.xz
```

### Add Flutter to PATH

Edit your shell config file:

```bash
nano ~/.bashrc
```

Add this at the bottom:

```bash
export PATH="$PATH:$HOME/flutter/bin"
```

Save (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`), then reload:

```bash
source ~/.bashrc
```

### Verify Flutter installation

```bash
flutter --version
```

You should see version info (3.44.0).

---

## Step 2: Install Android SDK (Lightweight — No Android Studio)

Install only the command-line tools (much smaller than Android Studio):

```bash
cd ~

# Download command-line tools (~130 MB)
curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip

# Create the SDK directory structure
mkdir -p Android/Sdk/cmdline-tools
mv cmdline-tools Android/Sdk/cmdline-tools/latest

# Delete the zip
rm commandlinetools-linux-11076708_latest.zip
```

### Install essential SDK components

```bash
cd ~/Android/Sdk/cmdline-tools/latest/bin

# Install platform tools (adb), SDK platform, and build tools
./sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

> **What this installs:**
> - `platform-tools` (~6 MB) — contains `adb` for USB installs
> - `platforms;android-34` — SDK platform to compile against
> - `build-tools;34.0.0` — tools needed for the build

### Accept licenses

```bash
yes | ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

### Set environment variables

Add to `~/.bashrc`:

```bash
nano ~/.bashrc
```

Add these lines:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

Then reload:

```bash
source ~/.bashrc
```

---

## Step 3: Verify Everything

Run Flutter doctor to check your setup:

```bash
flutter doctor
```

You should see something like:

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.44.0, on Linux)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[!] Chrome - develop for the web
[✓] Android Studio (not used)
[✓] Connected device (1 available)
```

The `[!] Chrome` warning is fine — we're building for Android, not web.
The `Android Studio (not used)` is expected since we installed only the CLI tools.

---

## Step 4: Clone the Project

```bash
cd ~
git clone https://github.com/aimadnesscreation-lab/flutter-invoice.git
cd flutter-invoice
flutter pub get
```

---

## Step 5: Enable USB Debugging on Your Phone

1. Open **Settings → About phone**
2. Tap **Build number** 7 times (you'll see "You are now a developer!")
3. Go back → **Settings → Developer options**
4. Enable **USB debugging**
5. Connect your phone to your computer via USB cable
6. On your phone, when prompted "Allow USB debugging?", tap **OK**

Verify your phone is detected:

```bash
flutter devices
```

You should see your phone listed, e.g.:

```
1 connected device:
SM-G998B (mobile) • RZ8N83HXXXX • android-arm64 • Android 14 (API 34)
```

---

## Step 6: Run the App

### First time (build + install):

```bash
flutter run --debug
```

This will:
1. Compile the app (~2-3 minutes the first time)
2. Install it on your phone via USB
3. Launch it automatically

### For faster iterations (hot reload):

Once the app is running from `flutter run`, you can:

| Key | Action | Time |
|---|---|---|
| `r` | Hot reload (update UI) | ~1 second |
| `R` | Hot restart (full restart) | ~3 seconds |
| `q` | Quit | Instant |

This means you can fix a bug, save the file, press `r`, and see the change on your phone in **under 2 seconds** — no CI, no download, no reinstall.

### To install a fresh APK without re-running:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The `-r` flag replaces the existing app and keeps your data.

---

## Troubleshooting

### `adb: command not found`

Make sure the SDK tools are in your PATH:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
source ~/.bashrc
```

### `device offline` or `unauthorized`

1. Disconnect the USB cable
2. Reconnect it
3. On your phone, check for a "Allow USB debugging?" prompt and tap **OK**
4. Run `adb kill-server && adb start-server && adb devices`

### `flutter: command not found`

Make sure Flutter is in your PATH:

```bash
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc
```

### `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

The existing app on your phone was signed with a different key. Uninstall it first:

```bash
adb uninstall com.invoicepro.invoice_pro
```

Then install again.

### Java errors during build

Make sure Java 17 is installed and set as default:

```bash
java -version  # Should show 17.x
```

If not:

```bash
sudo update-alternatives --config java
```

Select the Java 17 option.

---

## Summary

| Task | Command |
|---|---|
| Build & run on phone | `flutter run --debug` |
| Hot reload | Press `r` in terminal |
| Just build APK | `flutter build apk --debug` |
| Install APK via USB | `adb install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Check setup | `flutter doctor` |
| List connected devices | `flutter devices` |
