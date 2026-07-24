#!/bin/sh
# Build USB payload: Zscaler custom rules only (run on Mac).
#   ./prepare-usb.sh
#   ./prepare-usb.sh /Volumes/USB
set -e
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd)
DEST="${1:-$HERE/dist}"
BOOT="$DEST/router-b-bootstrap"

echo "prepare → $BOOT (Zscaler-only)"
rm -rf "$BOOT"
mkdir -p "$BOOT/payload"

cp -f "$HERE/install.sh" "$BOOT/install.sh"
cp -f "$HERE/README.md" "$BOOT/README.md"
cp -f "$HERE/secrets.env.example" "$BOOT/secrets.env.example"
chmod +x "$BOOT/install.sh"

cp -f "$HERE/zscaler_only_rules.list" "$BOOT/payload/openclash_custom_rules.list"
cp -f "$HERE/zscaler_only_overwrite.sh" "$BOOT/payload/openclash_custom_overwrite.sh"
cp -f "$REPO/router-a-asus-merlin/custom/ruleset/Zscaler.yaml" "$BOOT/payload/Zscaler.yaml"
chmod +x "$BOOT/payload/openclash_custom_overwrite.sh"

if [ -f "$HERE/secrets.env" ]; then
	cp -f "$HERE/secrets.env" "$BOOT/secrets.env"
	echo "included secrets.env"
else
	echo "NOTE: secrets.env optional (dashboard pass / SUB_URL)"
fi

echo "OK: $BOOT"
echo "On router:  sh <usb>/router-b-bootstrap/install.sh"
ls -la "$BOOT" "$BOOT/payload"
