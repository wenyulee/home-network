#!/bin/sh
TS_DIR=/tmp/mnt/sda1/tailscale
mkdir -p /var/run/tailscale "$TS_DIR/state"
# wait for USB if needed
i=0
while [ ! -x "$TS_DIR/bin/tailscaled" ] && [ $i -lt 30 ]; do sleep 2; i=$((i+1)); done
[ -x "$TS_DIR/bin/tailscaled" ] || exit 1
killall tailscaled 2>/dev/null
"$TS_DIR/bin/tailscaled" --state="$TS_DIR/state/tailscaled.state" --socket=/var/run/tailscale/tailscaled.sock --port=41641 >/tmp/tailscaled.log 2>&1 &
