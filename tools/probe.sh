#!/usr/bin/env bash
# Builds Examples/Probe, runs it on a simulator of its own, and prints the PROBE log.
# Needs xcodegen and Xcode; run outside any sandbox (CoreSimulator).
set -euo pipefail
cd "$(dirname "$0")/../Examples"
xcodegen generate --quiet
DEV_NAME="emil-probe"
udid=$(xcrun simctl list devices available | awk -v n="$DEV_NAME" '$0 ~ n {gsub(/[()]/,"",$2); print $2; exit}')
if [ -z "$udid" ]; then
  runtime=$(xcrun simctl list runtimes available | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]*' | tail -1)
  # Newest iPhone Pro this runtime supports (newer device types can need a newer runtime).
  for type in $(xcrun simctl list devicetypes | grep -o 'com.apple.CoreSimulator.SimDeviceType.iPhone-[0-9]*-Pro)' | tr -d ')'); do
    udid=$(xcrun simctl create "$DEV_NAME" "$type" "$runtime" 2>/dev/null) && break
  done
  [ -n "$udid" ] || { echo "no iPhone simulator could be created for $runtime"; exit 1; }
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" >/dev/null
xcodebuild -project Probe.xcodeproj -scheme Probe -destination "id=$udid" -derivedDataPath build -quiet build
xcrun simctl install "$udid" build/Build/Products/Debug-iphonesimulator/Probe.app
xcrun simctl launch --console-pty --terminate-running-process "$udid" dev.emil-design-swiftui.probe | grep --line-buffered '^PROBE'
