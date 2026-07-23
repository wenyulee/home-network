#!/bin/sh
# Build / refresh USB payload from repo (run on Mac).
# Usage:
#   ./prepare-usb.sh                  # write into ./dist/
#   ./prepare-usb.sh /Volumes/USB     # also copy tree to USB stick
set -e
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd)
DEST="${1:-$HERE/dist}"
BOOT="$DEST/router-b-bootstrap"

echo "prepare → $BOOT"
rm -rf "$BOOT"
mkdir -p "$BOOT/payload"

cp -f "$HERE/install.sh" "$BOOT/install.sh"
cp -f "$HERE/README.md" "$BOOT/README.md"
cp -f "$HERE/secrets.env.example" "$BOOT/secrets.env.example"
chmod +x "$BOOT/install.sh"

cp -f "$HERE/../custom/openclash_custom_rules.list" "$BOOT/payload/"
cp -f "$HERE/../custom/openclash_custom_overwrite.sh" "$BOOT/payload/"
cp -f "$HERE/../custom/tailscale/uci-tailscale" "$BOOT/payload/"
RS="$REPO/router-a-asus-merlin/custom/ruleset"
cp -f "$RS/Zscaler.yaml" "$RS/MailSMTP.yaml" "$RS/Rebrickable.yaml" "$BOOT/payload/"
# optional node list for Rebrickable url-test
if [ -f "$HERE/../custom/rebrickable_nodes.txt" ]; then
	cp -f "$HERE/../custom/rebrickable_nodes.txt" "$BOOT/payload/"
elif [ -f "$REPO/router-a-asus-merlin/custom/rebrickable_nodes.txt" ]; then
	cp -f "$REPO/router-a-asus-merlin/custom/rebrickable_nodes.txt" "$BOOT/payload/"
fi
chmod +x "$BOOT/payload/openclash_custom_overwrite.sh"

if [ -f "$HERE/secrets.env" ]; then
	cp -f "$HERE/secrets.env" "$BOOT/secrets.env"
	echo "included secrets.env"
else
	echo "NOTE: no secrets.env yet — copy secrets.env.example → secrets.env, fill, re-run prepare"
fi

echo "OK: $BOOT"
echo "On router:  sh <usb>/router-b-bootstrap/install.sh"
ls -la "$BOOT" "$BOOT/payload"
