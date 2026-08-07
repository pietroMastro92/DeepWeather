#!/bin/zsh
# Build DeepWeather (Universal Binary: arm64 + x86_64) with Tuist and launch it.
set -euo pipefail
cd "$(dirname "$0")"

# Xcode is installed but xcode-select points to Command Line Tools.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export TUIST_SKIP_UPDATE_CHECK=1

tuist generate --no-open
tuist xcodebuild build \
    -scheme DeepWeather \
    -configuration Debug \
    -derivedDataPath .build/DerivedData

pkill -x DeepWeather 2>/dev/null || true
open .build/DerivedData/Build/Products/Debug/DeepWeather.app
