#!/bin/bash
# TaskMatch installer for macOS (Apple Silicon).
#   curl -fsSL https://taskmatch-site.vercel.app/install.sh | bash
# Downloads the app, puts it in Applications, opens it and points you to the menu bar.
set -euo pipefail

DMG_URL="https://github.com/sweksha-cloud/taskmatch-site/releases/latest/download/TaskMatch-mac-arm64.dmg"
APP_NAME="work-match.app"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "TaskMatch runs on macOS only."
[ "$(uname -m)" = "arm64" ] || fail "TaskMatch needs an Apple Silicon Mac (M1 or newer)."

TMP="$(mktemp -d)"
MNT="$TMP/mount"
cleanup() {
  hdiutil detach -quiet "$MNT" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

say "Downloading TaskMatch..."
curl -fL --progress-bar -o "$TMP/TaskMatch.dmg" "$DMG_URL" || fail "Download failed. Check your internet connection."

mkdir -p "$MNT"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$MNT" "$TMP/TaskMatch.dmg" || fail "Couldn't open the download."
[ -d "$MNT/$APP_NAME" ] || fail "The download doesn't contain the app."

# Quit a copy that's already running, so the new one can replace it.
if pgrep -xq work_match; then
  say "Closing the TaskMatch that's already running..."
  osascript -e 'quit app "work-match"' >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -xq work_match || break; sleep 1; done
  pkill -x work_match 2>/dev/null || true
  sleep 1
fi

DEST="/Applications"
[ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }

say "Installing to $DEST..."
rm -rf "${DEST:?}/$APP_NAME"
ditto "$MNT/$APP_NAME" "$DEST/$APP_NAME"
xattr -cr "$DEST/$APP_NAME" 2>/dev/null || true

say "Opening TaskMatch..."
open "$DEST/$APP_NAME"

osascript >/dev/null 2>&1 <<'EOF' || true
display dialog "TaskMatch is running in your menu bar. Click the 🌍 at the top right of your screen.

It has no Dock icon and no window until you click the globe. Then choose \"Skip, try it as a guest\"." with title "TaskMatch is installed" buttons {"Got it"} default button 1 with icon note giving up after 60
EOF

printf '\n\033[1;32mDone!\033[0m TaskMatch is running. Click the 🌍 in your menu bar (top right of your screen).\n'
