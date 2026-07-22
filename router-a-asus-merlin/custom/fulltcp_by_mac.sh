#!/bin/ash
# Full-TCP hijack into ShellCrash for listed MACs (like Router B OpenClash).
# Only when device is on Router A LAN/Wi-Fi (client MAC visible).
# Behind Router B, A cannot see client MAC.

MAC_FILE=/jffs/ShellCrash/configs/fulltcp_mac.list
JUMP=shellcrash
OWN=shellcrash_fulltcp_mac

[ -s "$MAC_FILE" ] || exit 0
[ -n "$(pidof CrashCore)" ] || exit 0
iptables -t nat -L "$JUMP" -n >/dev/null 2>&1 || exit 0

# Recreate private jumper chain
iptables -t nat -F "$OWN" 2>/dev/null || iptables -t nat -N "$OWN"
iptables -t nat -F "$OWN"

# Detach old PREROUTING jump to OWN if any
while iptables -t nat -D PREROUTING -p tcp -j "$OWN" 2>/dev/null; do :; done

for mac in $(grep -v '^[[:space:]]*#' "$MAC_FILE" | grep -v '^[[:space:]]*$' | tr 'a-z' 'A-Z'); do
  iptables -t nat -A "$OWN" -m mac --mac-source "$mac" -j "$JUMP"
done
# non-matching MACs fall through
iptables -t nat -A "$OWN" -j RETURN

# Insert OWN before common-ports multiport shellcrash rule
idx=$(iptables -t nat -S PREROUTING 2>/dev/null | awk '/-j shellcrash/ && /multiport/ {print NR-1; exit}')
[ -z "$idx" ] && idx=4
iptables -t nat -I PREROUTING "$idx" -p tcp -j "$OWN"
logger -t shellcrash-fulltcp "full-TCP MAC jumper installed at PREROUTING $idx"
