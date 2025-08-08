#!/bin/bash

echo "🔍 Code Quality Check for Group Trip Expense Splitter"
echo "===================================================="

# Check if we have the basic Flutter project structure
echo "📁 Checking project structure..."

# Check essential files
files_to_check=(
    "pubspec.yaml"
    "lib/main.dart"
    "lib/core/theme/design_tokens.dart"
    "lib/business_logic/providers/auth_providers.dart"
    "lib/data/models/user.dart"
    "lib/presentation/screens/auth/login_screen.dart"
)

missing_files=()
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        missing_files+=("$file")
    fi
done

# Check directory structure
echo ""
echo "📂 Checking directory structure..."

directories_to_check=(
    "lib"
    "lib/core"
    "lib/business_logic"
    "lib/data"
    "lib/presentation"
    "lib/presentation/screens"
    "lib/presentation/widgets"
)

missing_dirs=()
for dir in "${directories_to_check[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/"
    else
        echo "❌ $dir/ (missing)"
        missing_dirs+=("$dir")
    fi
done

# Count Dart files
echo ""
echo "📊 Code Statistics:"
dart_files=$(find lib -name "*.dart" | wc -l)
echo "📄 Dart files: $dart_files"

# List main components
echo ""
echo "🧩 Main Components:"
echo "Screens:"
find lib/presentation/screens -name "*.dart" 2>/dev/null | sed 's/.*\//  - /' | sed 's/\.dart$//'

echo ""
echo "Widgets:"
find lib/presentation/widgets -name "*.dart" 2>/dev/null | sed 's/.*\//  - /' | sed 's/\.dart$//'

echo ""
echo "Models:"
find lib/data/models -name "*.dart" 2>/dev/null | sed 's/.*\//  - /' | sed 's/\.dart$//'

echo ""
echo "Providers:"
find lib/business_logic/providers -name "*.dart" 2>/dev/null | sed 's/.*\//  - /' | sed 's/\.dart$//'

# Check for common issues
echo ""
echo "🔍 Checking for potential issues..."

# Check for TODO comments
todo_count=$(grep -r "TODO" lib --include="*.dart" | wc -l)
echo "📝 TODO comments: $todo_count"

# Check for import issues (basic check)
echo ""
echo "📦 Import Analysis:"
relative_imports=$(grep -r "import '\.\." lib --include="*.dart" | wc -l)
echo "🔗 Relative imports: $relative_imports"

package_imports=$(grep -r "import 'package:" lib --include="*.dart" | wc -l)
echo "📦 Package imports: $package_imports"

# Summary
echo ""
echo "📋 Summary:"
echo "==========="

if [ ${#missing_files[@]} -eq 0 ] && [ ${#missing_dirs[@]} -eq 0 ]; then
    echo "✅ Project structure looks good!"
else
    echo "⚠️  Some files/directories are missing:"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
    for dir in "${missing_dirs[@]}"; do
        echo "   - $dir/"
    done
fi

echo ""
echo "📈 Code Metrics:"
echo "  - Dart files: $dart_files"
echo "  - TODO items: $todo_count"
echo "  - Relative imports: $relative_imports"
echo "  - Package imports: $package_imports"

echo ""
echo "🎯 Next Steps:"
echo "1. Install Flutter SDK if not already installed"
echo "2. Run: ./setup_flutter_project.sh"
echo "3. Run: flutter pub get"
echo "4. Run: flutter run"

echo ""
echo "📚 For detailed setup instructions, see: SETUP_GUIDE.md"
