#!/bin/sh
# Check a built Wick.app for yourself. Run after ./build.sh.
set -eu
cd "$(dirname "$0")/.."
APP=${1:-build/Wick.app}
BIN="$APP/Contents/MacOS/Wick"

echo "== Entitlements (expect only com.apple.security.app-sandbox = true)"
/usr/bin/codesign -d --entitlements - "$APP" 2>/dev/null
echo
echo "== Code signature flags (expect 'runtime' = hardened runtime)"
/usr/bin/codesign -dv "$APP" 2>&1 | grep flags
echo
echo "== Linked libraries (expect only /System and /usr/lib, no Network framework)"
/usr/bin/otool -L "$BIN" | sed 1d | awk '{print $1}' | sort -u
echo
echo "== Source scan for network, file, process, scripting, IPC or other-app APIs (expect nothing)"
grep -nE 'URLSession|URLRequest|NWConnection|import Network|socket\(|CFStream|NSAppleScript|NSAppleEvent|XPC|NSConnection|DistributedNotification|FileManager|contentsOf|Process\(|NSTask|posix_spawn|dlopen|NSWorkspace|NSRunningApplication|CGWindowList|NSPasteboard|getenv|environment|suiteName|IOServiceGetMatching' Sources/*.swift || echo "  none found"
echo
echo "== Local paths baked into the binary (expect nothing)"
strings -a "$BIN" | grep -E '/Users/|/home/' || echo "  none found"
echo
echo "== Network sockets held by a running Wick (expect nothing)"
for PID in $(/usr/bin/pgrep -x Wick || true); do
  /usr/sbin/lsof -nP -a -i -p "$PID" || echo "  pid $PID: none"
done
