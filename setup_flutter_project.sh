#!/bin/bash

# Flutter Project Setup Script
# This script will help set up the Flutter project with proper platform support

echo "🚀 Setting up Flutter Project for Group Trip Expense Splitter"
echo "============================================================"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter first:"
    echo "1. Install via Homebrew: brew install --cask flutter"
    echo "2. Or download from: https://flutter.dev/docs/get-started/install/macos"
    echo "3. Add Flutter to your PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Create a temporary directory for the new project
TEMP_DIR="temp_flutter_project"
CURRENT_DIR=$(pwd)

echo "📁 Creating temporary Flutter project..."
flutter create $TEMP_DIR --org com.expensesplitter --project-name expense_splitter

if [ $? -eq 0 ]; then
    echo "✅ Flutter project created successfully"
    
    # Copy platform directories to current project
    echo "📱 Copying platform directories..."
    cp -r $TEMP_DIR/android ./
    cp -r $TEMP_DIR/ios ./
    cp -r $TEMP_DIR/linux ./
    cp -r $TEMP_DIR/macos ./
    cp -r $TEMP_DIR/windows ./
    cp -r $TEMP_DIR/web ./
    
    # Copy other essential files if they don't exist
    if [ ! -f "analysis_options.yaml" ]; then
        cp $TEMP_DIR/analysis_options.yaml ./
    fi
    
    if [ ! -f ".gitignore" ]; then
        cp $TEMP_DIR/.gitignore ./
    fi
    
    if [ ! -f ".metadata" ]; then
        cp $TEMP_DIR/.metadata ./
    fi
    
    # Clean up
    rm -rf $TEMP_DIR
    
    echo "🧹 Cleaning up temporary files..."
    echo "✅ Project setup complete!"
    
    # Run flutter pub get
    echo "📦 Installing dependencies..."
    flutter pub get
    
    if [ $? -eq 0 ]; then
        echo "✅ Dependencies installed successfully"
        
        # Check available devices
        echo "📱 Checking available devices..."
        flutter devices
        
        echo ""
        echo "🎉 Setup Complete!"
        echo "==================="
        echo "Your Flutter project is now ready for development."
        echo ""
        echo "Next steps:"
        echo "1. Open iOS Simulator: open -a Simulator"
        echo "2. Start Android Emulator from Android Studio"
        echo "3. Run the app: flutter run"
        echo ""
        echo "To test on specific platforms:"
        echo "- iOS: flutter run -d ios"
        echo "- Android: flutter run -d android"
        echo "- Web: flutter run -d web-server"
        
    else
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    
else
    echo "❌ Failed to create Flutter project"
    exit 1
fi
