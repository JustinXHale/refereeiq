#!/bin/bash

# Read version and build from pubspec.yaml
version=$(grep "^version:" pubspec.yaml | sed 's/version: //')
# version looks like "0.5.0+1"
version_name=${version%%+*}      # e.g. "0.5.0"
build_number=${version#*+}       # e.g. "1"

# Create dist directory if missing
mkdir -p dist

# Build the APK
echo "🚀 Building RefereeIQ v${version_name}+${build_number}.apk ..."
flutter clean
flutter pub get
flutter build apk --release

# Rename and move the APK to dist/
apk_source="build/app/outputs/flutter-apk/app-release.apk"
apk_target="dist/RefereeIQ-v${version_name}+${build_number}.apk"

if [ -f "$apk_source" ]; then
  mv "$apk_source" "$apk_target"
  echo "✅ Build complete: $apk_target"
else
  echo "❌ Build failed: APK not found at $apk_source"
  exit 1
fi
