#!/data/data/com.termux/files/usr/bin/bash
# Flutter SDK build script for Termux ARM64
# Run after flutter_arm64.zip is downloaded

set -e

FLUTTER_DIR=$HOME/flutter_arm64
PROJECT_DIR="/storage/emulated/0/Download/Vias/trae_agent"

echo "[1/5] Cleaning up..."
rm -rf "$FLUTTER_DIR"
mkdir -p "$FLUTTER_DIR"

echo "[2/5] Extracting Flutter SDK..."
cd $HOME
unzip -qo flutter_arm64.zip -d "$FLUTTER_DIR"
chmod +x "$FLUTTER_DIR"/bin/dart "$FLUTTER_DIR"/bin/flutter
echo "  Flutter extracted"

echo "[3/5] Setting up Android SDK..."
export ANDROID_HOME=$HOME/android
export ANDROID_SDK_ROOT=$HOME/android
export PATH="$FLUTTER_DIR/bin:$PATH"

# Create local.properties
echo "sdk.dir=$ANDROID_HOME" > "$PROJECT_DIR/android/local.properties"
echo "flutter.sdk=$FLUTTER_DIR" >> "$PROJECT_DIR/android/local.properties"
echo "flutter.buildMode=release" >> "$PROJECT_DIR/android/local.properties"
echo "flutter.versionCode=1" >> "$PROJECT_DIR/android/local.properties"
echo "flutter.versionName=0.1.0" >> "$PROJECT_DIR/android/local.properties"

# Accept Android licenses
echo "y" | $ANDROID_HOME/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses 2>/dev/null || true

echo "[4/5] Running flutter pub get..."
cd "$PROJECT_DIR"
flutter pub get 2>&1 | tail -5

echo "[5/5] Building APK..."
flutter build apk --release 2>&1 | tail -20

echo ""
echo "========== BUILD COMPLETE =========="
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo "APK: $APK_PATH"
    ls -lh "$APK_PATH"
    cp "$APK_PATH" /storage/emulated/0/Download/Vias/TraeAgent-v0.1.0.apk 2>/dev/null || true
    echo "Copied to: /storage/emulated/0/Download/Vias/TraeAgent-v0.1.0.apk"
else
    echo "BUILD FAILED — check above for errors"
fi
echo "===================================="
