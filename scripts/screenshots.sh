#!/usr/bin/env bash
# Maakt App Store-screenshots in de simulator (iPhone 6.3" en iPad 13").
# Gebruik: scripts/screenshots.sh   (vereist Xcode + XcodeGen)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=AppStore/raw
BUNDLE=app.lrvdlinden.vlagdagen
mkdir -p "$OUT"

xcodegen generate
xcodebuild build -project Vlagdagen.xcodeproj -scheme Vlagdagen -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO | tail -n 5
APP=build/Build/Products/Debug-iphonesimulator/Vlagdagen.app

udid_for() {
  xcrun simctl list devices available -j | python3 -c '
import json,sys,re
name=sys.argv[1]; data=json.load(sys.stdin)["devices"]
cands=[(rt,d) for rt,ds in data.items() if "iOS" in rt for d in ds if d["name"].startswith(name)]
cands.sort(key=lambda x: [int(n) for n in re.findall(r"\d+", x[0])], reverse=True)
print(cands[0][1]["udid"] if cands else "")' "$1"
}

shoot() { # device-dir udid naam args...
  local dir=$1 udid=$2 name=$3; shift 3
  xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE" -AppleLanguages "(nl)" -AppleLocale nl_NL -skipSplash YES "$@" >/dev/null
  sleep 5
  xcrun simctl io "$udid" screenshot --type=png "$OUT/$dir/$name.png"
  echo "  $dir/$name"
}

for spec in "iphone:iPhone 16 Pro" "ipad:iPad Pro 13-inch"; do
  dir=${spec%%:*}; name=${spec#*:}
  udid=$(udid_for "$name")
  [ -z "$udid" ] && { echo "Geen simulator voor $name"; xcrun simctl list devices available; exit 1; }
  echo "== $name ($udid)"
  mkdir -p "$OUT/$dir"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance light
  xcrun simctl status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
  xcrun simctl install "$udid" "$APP"
  sleep 3

  shoot "$dir" "$udid" 01-vandaag-ja        -hasOnboarded YES -demoDate 2027-04-27T09:41 -demoTab today
  shoot "$dir" "$udid" 02-aftellen          -hasOnboarded YES -demoDate 2027-04-19T09:41 -demoTab today
  shoot "$dir" "$udid" 03-halfstok          -hasOnboarded YES -demoDate 2027-05-04T09:41 -demoTab today
  shoot "$dir" "$udid" 04-agenda            -hasOnboarded YES -demoDate 2027-04-19T09:41 -demoTab agenda
  shoot "$dir" "$udid" 05-meldingen         -hasOnboarded YES -demoDate 2027-04-19T09:41 -demoTab settings
  shoot "$dir" "$udid" 06-handleiding       -hasOnboarded YES -demoDate 2027-04-19T09:41 -demoTab guide -demoGuide halfstok
  shoot "$dir" "$udid" 07-detail            -hasOnboarded YES -demoDate 2027-11-20T09:41 -demoTab today -demoFlagDay amalia-2027-12-07
  shoot "$dir" "$udid" 08-welkom            -hasOnboarded NO  -demoDate 2027-04-19T09:41

  xcrun simctl shutdown "$udid" || true
done
echo "Klaar: $OUT"
