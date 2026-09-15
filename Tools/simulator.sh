#!/bin/sh
# One simulator per lane. A lane working on an example creates its own device, named after the
# device type and the example, so no two lanes share a device-interaction session; it deletes the
# device when it is done. Never install on, drive, or reset a simulator you did not create here.
#
#   Tools/simulator.sh create [device type]   creates and boots "<type> · <example>", prints its UDID
#   Tools/simulator.sh udid   [device type]   prints the UDID of this lane's device (empty if none)
#   Tools/simulator.sh delete [device type]   shuts the device down and deletes it
#
# The example is the name of the directory this file's Tools/ sits in (maps, messages, …); the
# device type defaults to "iPhone 17e"; the runtime is the newest installed iOS.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
example=$(basename "$here")
action=${1:-udid}
type=${2:-iPhone 17e}
name="$type · $example"

udid() {
    xcrun simctl list devices -j | python3 -c '
import json, sys
name = sys.argv[1]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    for d in devices:
        if d["name"] == name and d.get("isAvailable", True):
            print(d["udid"]); sys.exit(0)
' "$name"
}

case "$action" in
    create)
        existing=$(udid || true)
        if [ -n "$existing" ]; then
            echo "$existing"; xcrun simctl boot "$existing" 2>/dev/null || true; exit 0
        fi
        runtime=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
ios = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]]
ios.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
print(ios[-1]["identifier"])')
        new=$(xcrun simctl create "$name" "$type" "$runtime")
        xcrun simctl boot "$new"
        echo "$new"
        ;;
    udid)
        udid || true
        ;;
    delete)
        existing=$(udid || true)
        if [ -n "$existing" ]; then
            xcrun simctl shutdown "$existing" 2>/dev/null || true
            xcrun simctl delete "$existing"
        fi
        ;;
    *)
        echo "usage: $0 create|udid|delete [device type]" >&2; exit 2
        ;;
esac
