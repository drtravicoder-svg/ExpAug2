# 🚀 Flutter Development Environment Setup Guide

## Prerequisites

### 1. Install Flutter SDK

**Option A: Using Homebrew (Recommended)**
```bash
# Install Flutter
brew install --cask flutter

# Add Flutter to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="$PATH:/opt/homebrew/bin/flutter/bin"
```

**Option B: Manual Installation**
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/macos)
2. Extract to `/Users/yourusername/flutter`
3. Add to PATH in your shell profile:
   ```bash
   export PATH="$PATH:/Users/yourusername/flutter/bin"
   ```

### 2. Install Development Tools

**Xcode (for iOS development):**
```bash
# Install Xcode from App Store
# Then install command line tools
sudo xcode-select --install
```

**Android Studio (for Android development):**
1. Download from [developer.android.com](https://developer.android.com/studio)
2. Install Android SDK and create virtual devices

### 3. Verify Installation
```bash
flutter doctor
```

## 🏗️ Project Setup

### Option 1: Automated Setup (Recommended)
```bash
# Run the setup script
./setup_flutter_project.sh
```

### Option 2: Manual Setup

1. **Create platform directories:**
```bash
# Create a temporary Flutter project to get platform files
flutter create temp_project --org com.expensesplitter --project-name expense_splitter

# Copy platform directories
cp -r temp_project/android ./
cp -r temp_project/ios ./
cp -r temp_project/linux ./
cp -r temp_project/macos ./
cp -r temp_project/windows ./
cp -r temp_project/web ./

# Copy essential files
cp temp_project/analysis_options.yaml ./
cp temp_project/.gitignore ./
cp temp_project/.metadata ./

# Clean up
rm -rf temp_project
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Generate missing files:**
```bash
# Generate model files (if using freezed/json_annotation)
flutter packages pub run build_runner build
```

## 📱 Testing Environment Setup

### iOS Simulator
```bash
# Open iOS Simulator
open -a Simulator

# List available simulators
xcrun simctl list devices

# Run app on iOS
flutter run -d ios
```

### Android Emulator
```bash
# List available devices
flutter devices

# Start Android emulator from Android Studio or command line
emulator -avd <device_name>

# Run app on Android
flutter run -d android
```

### Web Browser
```bash
# Run on web
flutter run -d web-server
```

## 🔧 Development Commands

### Basic Commands
```bash
# Check Flutter installation
flutter doctor

# List connected devices
flutter devices

# Run app (auto-selects device)
flutter run

# Run with hot reload
flutter run --hot

# Build for release
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

### Development Tools
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Generate code (for freezed/json_annotation)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🐛 Troubleshooting

### Common Issues

1. **Flutter not found:**
   - Ensure Flutter is in your PATH
   - Restart terminal after adding to PATH

2. **iOS build issues:**
   - Run `flutter clean`
   - Delete `ios/Pods` and `ios/Podfile.lock`
   - Run `cd ios && pod install`

3. **Android build issues:**
   - Check Android SDK installation
   - Update Android SDK tools
   - Check `android/local.properties`

4. **Dependencies issues:**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run `flutter pub deps`

### Useful Debug Commands
```bash
# Clean build cache
flutter clean

# Verbose output
flutter run -v

# Check dependencies
flutter pub deps

# Doctor with verbose output
flutter doctor -v
```

## 🎯 Testing Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] `flutter doctor` shows no critical issues
- [ ] iOS Simulator available and working
- [ ] Android Emulator available and working
- [ ] Project builds without errors
- [ ] Hot reload working
- [ ] Navigation between screens working
- [ ] Forms and validation working
- [ ] State management (Riverpod) working

## 📚 Next Steps

Once setup is complete:

1. **Test Basic Functionality:**
   - Login screen
   - Navigation between tabs
   - Create trip flow
   - Add expense flow

2. **Firebase Integration:**
   - Set up Firebase project
   - Add configuration files
   - Test authentication
   - Test Firestore operations

3. **Advanced Testing:**
   - Test on multiple devices
   - Test different screen sizes
   - Performance testing
   - Memory usage testing

## 🆘 Getting Help

If you encounter issues:

1. Check `flutter doctor` output
2. Review error messages carefully
3. Check Flutter documentation
4. Search Flutter GitHub issues
5. Ask on Stack Overflow with `flutter` tag

---

**Happy Coding! 🎉**
