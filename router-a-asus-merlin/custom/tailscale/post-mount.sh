#!/bin/sh
/koolshare/bin/ks-mount-start.sh start $1

/jffs/scripts/shellcrash-usb-offload >/dev/null 2>&1 &

# Tailscale (USB-backed binary)
if [ -x /jffs/tailscale/start.sh ]; then
  /jffs/tailscale/start.sh &
fi
