#!/bin/bash

echo "🤖 Android Setup for Flutter - Group Trip Expense Splitter"
echo "=========================================================="

# Function to check if Android SDK exists
check_android_sdk() {
    local sdk_paths=(
        "$HOME/Library/Android/sdk"
        "$HOME/Android/Sdk"
        "$HOME/android-sdk"
        "/usr/local/android-sdk"
    )
    
    for path in "${sdk_paths[@]}"; do
        if [ -d "$path" ]; then
            echo "✅ Android SDK found at: $path"
            export ANDROID_HOME="$path"
            return 0
        fi
    done
    
    echo "❌ Android SDK not found in common locations"
    return 1
}

# Function to set up environment variables
setup_environment() {
    echo "🔧 Setting up Android environment variables..."
    
    export ANDROID_HOME="$1"
    export PATH="$PATH:$ANDROID_HOME/emulator"
    export PATH="$PATH:$ANDROID_HOME/tools"
    export PATH="$PATH:$ANDROID_HOME/tools/bin"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
    
    echo "✅ Environment variables set:"
    echo "   ANDROID_HOME=$ANDROID_HOME"
    echo "   PATH updated with Android tools"
}

# Function to check Flutter doctor
check_flutter_doctor() {
    echo "🔍 Checking Flutter doctor for Android issues..."
    /Users/drtravis/flutter/bin/flutter doctor
}

# Function to list available emulators
list_emulators() {
    echo "📱 Checking for available Android emulators..."
    /Users/drtravis/flutter/bin/flutter emulators
}

# Function to create a new AVD if none exist
create_avd() {
    echo "🆕 Creating new Android Virtual Device..."
    
    if [ -n "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" ]; then
        echo "Available system images:"
        "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --list | grep "system-images" | head -10
        
        echo ""
        echo "Creating Pixel 7 AVD with API 34..."
        echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
            -n "Pixel_7_API_34" \
            -k "system-images;android-34;google_apis;arm64-v8a" \
            -d "pixel_7"
        
        if [ $? -eq 0 ]; then
            echo "✅ AVD created successfully: Pixel_7_API_34"
        else
            echo "⚠️  AVD creation failed. You may need to install system images first."
            echo "Run this in Android Studio SDK Manager:"
            echo "  - Android 14 (API 34) system image"
            echo "  - Google APIs ARM 64 v8a System Image"
        fi
    else
        echo "⚠️  AVD Manager not found. Please create AVD through Android Studio:"
        echo "  1. Open Android Studio"
        echo "  2. Go to Tools > AVD Manager"
        echo "  3. Click 'Create Virtual Device'"
        echo "  4. Choose Pixel 7, API 34"
    fi
}

# Function to test Android app
test_android_app() {
    echo "🚀 Testing Android app..."
    
    cd /Users/drtravis/Documents/expense_splitter_demo
    
    echo "📦 Getting Flutter dependencies..."
    /Users/drtravis/flutter/bin/flutter pub get
    
    echo "📱 Checking available devices..."
    /Users/drtravis/flutter/bin/flutter devices
    
    echo ""
    echo "🎯 To run the app on Android:"
    echo "1. Start an emulator: flutter emulators --launch <emulator_name>"
    echo "2. Run the app: flutter run -d android"
    echo ""
    echo "Or run both commands automatically:"
    echo "flutter emulators --launch Pixel_7_API_34 && flutter run -d android"
}

# Main execution
main() {
    echo "Starting Android setup process..."
    echo ""
    
    # Step 1: Check for Android SDK
    if check_android_sdk; then
        setup_environment "$ANDROID_HOME"
    else
        echo ""
        echo "📋 Android SDK Setup Required:"
        echo "1. Android Studio should be opening now"
        echo "2. Follow the setup wizard to install Android SDK"
        echo "3. Go to SDK Manager and install:"
        echo "   - Android SDK Platform (API 34)"
        echo "   - Android SDK Build-Tools"
        echo "   - Android Emulator"
        echo "   - System Images (Google APIs ARM 64 v8a)"
        echo "4. Re-run this script after SDK installation"
        echo ""
        echo "💡 Default SDK location will be: ~/Library/Android/sdk"
        return 1
    fi
    
    # Step 2: Check Flutter doctor
    check_flutter_doctor
    
    # Step 3: List emulators
    list_emulators
    
    # Step 4: Create AVD if needed
    echo ""
    read -p "🤔 Do you want to create a new Android Virtual Device? (y/n): " create_new_avd
    if [[ $create_new_avd =~ ^[Yy]$ ]]; then
        create_avd
    fi
    
    # Step 5: Test setup
    echo ""
    test_android_app
    
    echo ""
    echo "🎉 Android setup process complete!"
    echo "📱 Next steps:"
    echo "1. If AVD was created, launch it: flutter emulators --launch Pixel_7_API_34"
    echo "2. Run the app: flutter run -d android"
    echo "3. Enjoy testing on Android! 🤖"
}

# Run main function
main
