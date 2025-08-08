#!/bin/bash

echo "🔍 Validating Flutter Project Setup"
echo "=================================="

# Check project structure
echo "📁 Checking project structure..."

# Essential directories
dirs=(
    "lib"
    "android"
    "ios"
    "android/app"
    "ios/Runner"
)

all_dirs_exist=true
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/"
    else
        echo "❌ $dir/ (missing)"
        all_dirs_exist=false
    fi
done

# Essential files
files=(
    "pubspec.yaml"
    "lib/main.dart"
    "android/app/build.gradle"
    "android/build.gradle"
    "android/settings.gradle"
    "android/app/src/main/AndroidManifest.xml"
    "ios/Runner/Info.plist"
    "ios/Runner/AppDelegate.swift"
)

all_files_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        all_files_exist=false
    fi
done

echo ""
echo "📊 Project Statistics:"
echo "====================="

# Count Dart files
dart_files=$(find lib -name "*.dart" 2>/dev/null | wc -l)
echo "📄 Dart files: $dart_files"

# Count screens
screens=$(find lib/presentation/screens -name "*.dart" 2>/dev/null | wc -l)
echo "📱 Screens: $screens"

# Count widgets
widgets=$(find lib/presentation/widgets -name "*.dart" 2>/dev/null | wc -l)
echo "🧩 Widgets: $widgets"

# Count models
models=$(find lib/data/models -name "*.dart" 2>/dev/null | wc -l)
echo "📦 Models: $models"

# Count providers
providers=$(find lib/business_logic/providers -name "*.dart" 2>/dev/null | wc -l)
echo "🔄 Providers: $providers"

echo ""
echo "🎯 Platform Readiness:"
echo "====================="

# Android readiness
if [ -f "android/app/build.gradle" ] && [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo "✅ Android platform ready"
    android_ready=true
else
    echo "❌ Android platform not ready"
    android_ready=false
fi

# iOS readiness
if [ -f "ios/Runner/Info.plist" ] && [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo "✅ iOS platform ready"
    ios_ready=true
else
    echo "❌ iOS platform not ready"
    ios_ready=false
fi

echo ""
echo "🔧 Development Tools Check:"
echo "=========================="

# Check for Xcode (iOS development)
if command -v xcodebuild &> /dev/null; then
    xcode_version=$(xcodebuild -version | head -1)
    echo "✅ Xcode: $xcode_version"
    xcode_available=true
else
    echo "❌ Xcode not found (required for iOS development)"
    xcode_available=false
fi

# Check for Android SDK
if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
    echo "✅ Android SDK configured"
    android_sdk_available=true
else
    echo "⚠️  Android SDK not configured (check ANDROID_HOME)"
    android_sdk_available=false
fi

# Check for Flutter
if command -v flutter &> /dev/null; then
    flutter_version=$(flutter --version | head -1)
    echo "✅ Flutter: $flutter_version"
    flutter_available=true
else
    echo "❌ Flutter not found in PATH"
    flutter_available=false
fi

echo ""
echo "📋 Summary & Recommendations:"
echo "============================"

if [ "$all_dirs_exist" = true ] && [ "$all_files_exist" = true ]; then
    echo "✅ Project structure is complete"
else
    echo "❌ Project structure has missing components"
fi

echo ""
echo "🚀 Next Steps:"

if [ "$flutter_available" = false ]; then
    echo "1. Install Flutter SDK:"
    echo "   - Download from: https://flutter.dev/docs/get-started/install"
    echo "   - Or use: brew install --cask flutter"
    echo "   - Add to PATH: export PATH=\"\$PATH:/path/to/flutter/bin\""
fi

if [ "$xcode_available" = false ]; then
    echo "2. Install Xcode from App Store (for iOS development)"
fi

if [ "$android_sdk_available" = false ]; then
    echo "3. Install Android Studio and configure Android SDK"
fi

if [ "$flutter_available" = true ]; then
    echo "4. Run Flutter commands:"
    echo "   - flutter doctor (check setup)"
    echo "   - flutter pub get (install dependencies)"
    echo "   - flutter devices (list available devices)"
    echo "   - flutter run (run the app)"
fi

echo ""
echo "📱 Testing Commands (when Flutter is ready):"
echo "============================================"
echo "# Check Flutter setup"
echo "flutter doctor"
echo ""
echo "# Install dependencies"
echo "flutter pub get"
echo ""
echo "# List available devices"
echo "flutter devices"
echo ""
echo "# Run on iOS Simulator"
echo "flutter run -d ios"
echo ""
echo "# Run on Android Emulator"
echo "flutter run -d android"
echo ""
echo "# Build for release"
echo "flutter build apk          # Android"
echo "flutter build ios          # iOS"

echo ""
echo "🎉 Project Analysis Complete!"
echo "============================="

if [ "$all_dirs_exist" = true ] && [ "$all_files_exist" = true ]; then
    echo "Your Flutter project is properly structured and ready for development!"
    echo "Install Flutter SDK and run 'flutter pub get' to get started."
else
    echo "Please address the missing files/directories before proceeding."
fi
