#!/bin/bash
set -e

echo "=== AuraPDF Build Pipeline ==="

# 1. Compile and execute the icon generator to create logo.png
echo "Generating high-resolution logo..."
swiftc GenerateIcon.swift -o GenerateIcon
./GenerateIcon
rm -f GenerateIcon

# 2. Build the multi-resolution macOS .icns file
echo "Converting logo to macOS .icns format..."
mkdir -p AppIcon.iconset
sips -z 16 16     logo.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     logo.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     logo.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     logo.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   logo.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   logo.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   logo.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   logo.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   logo.png --out AppIcon.iconset/icon_512x512.png

iconutil -c icns AppIcon.iconset
rm -rf AppIcon.iconset logo.png

# 3. Create the app bundle structure
echo "Setting up AuraPDF.app bundle structure..."
rm -rf AuraPDF.app
mkdir -p AuraPDF.app/Contents/MacOS
mkdir -p AuraPDF.app/Contents/Resources

# Move generated icon into Resources
mv AppIcon.icns AuraPDF.app/Contents/Resources/AppIcon.icns

# 4. Compile the SwiftUI Application
echo "Compiling SwiftUI source files..."
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) App.swift WorkspaceState.swift PageCardView.swift ContentView.swift -o AuraPDF.app/Contents/MacOS/AuraPDF

# 5. Copy configuration Info.plist
echo "Packaging Info.plist..."
cp Info.plist AuraPDF.app/Contents/Info.plist

# 6. Sign the app locally to prevent Gatekeeper warnings
echo "Signing the application bundle..."
codesign --force --sign - AuraPDF.app

echo "=== Build Complete! ==="
echo "You can launch the app with: open AuraPDF.app"
