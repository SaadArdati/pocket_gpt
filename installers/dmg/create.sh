#!/bin/sh
test -f "PocketGPT.dmg" && rm "PocketGPT.dmg"
mv "build/macos/Build/Products/Release/pocketgpt.app" "build/macos/Build/Products/Release/PocketGPT.app"
create-dmg \
  --volname "PocketGPT Installer" \
  --volicon "./installers/dmg/AppIcon.icns" \
  --background "./installers/dmg/background@2x.png" \
  --window-size 600 390 \
  --icon-size 132 \
  --icon "PocketGPT.app" 142 180 \
  --hide-extension "PocketGPT.app" \
  --app-drop-link 458 180 \
  --hdiutil-quiet \
  "PocketGPT.dmg" \
  "build/macos/Build/Products/Release/PocketGPT.app"