#!/bin/ash
# Fetch official Zscaler IP ranges → Clash classical rule-provider (domains + IP-CIDR).
# Prefer python3 collapse when available; else emit unique CIDRs via grep (no merge).
set -e
OUT="${1:-/jffs/ShellCrash/ruleset/Zscaler.yaml}"
TMPDIR="/tmp/zscaler-fetch.$$"
mkdir -p "$TMPDIR" "$(dirname "$OUT")"
LOG=/tmp/ShellCrash/ShellCrash.log
say() { echo "$(date "+%Y-%m-%d_%H:%M:%S")~$1" >>"$LOG" 2>/dev/null; echo "zscaler_ruleset: $1" >&2; }

AUTH=$(grep "^authentication=" /jffs/ShellCrash/configs/ShellCrash.cfg 2>/dev/null | sed "s/^authentication=//;s/^'//;s/'$//")
fetch() {
	url="$1"; out="$2"
	if [ -n "$AUTH" ]; then
		curl -fsSL --connect-timeout 12 --max-time 45 -x "http://${AUTH}@127.0.0.1:7890" -o "$out" "$url" && return 0
	fi
	curl -fsSL --connect-timeout 12 --max-time 45 -o "$out" "$url"
}

ok=0
for cloud in zscaler.net zscalerthree.net zscloud.net zscalerone.net zscalertwo.net; do
	for path in "api/${cloud}/cenr/json" "api/${cloud}/hubs/cidr/json/recommended" "api/${cloud}/hubs/cidr/json/required"; do
		f="$TMPDIR/$(echo "$path" | tr / _)"
		fetch "https://config.zscaler.com/${path}" "$f" && ok=$((ok + 1)) || true
	done
done
fetch "https://config.zscaler.com/api/private.zscaler.com/zpa/json" "$TMPDIR/zpa.json" && ok=$((ok + 1)) || true
[ "$ok" -ge 3 ] || { say "fetch failed ok=$ok"; rm -rf "$TMPDIR"; exit 1; }

RAW="$TMPDIR/cidrs.txt"
: >"$RAW"
grep -ohE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}|[0-9a-fA-F:]+::/[0-9]{1,3}|[0-9a-fA-F:]+:[0-9a-fA-F:]+/[0-9]{1,3}' "$TMPDIR"/* 2>/dev/null \
	| sort -u >"$RAW" || true
grep -ohE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$TMPDIR"/* 2>/dev/null \
	| tr -d '"' | while read -r ip; do echo "${ip}/32"; done >>"$RAW" || true
sort -u "$RAW" -o "$RAW"
cnt=$(wc -l <"$RAW" | tr -d ' ')
[ "$cnt" -gt 50 ] || { say "too few cidrs ($cnt)"; rm -rf "$TMPDIR"; exit 1; }

{
	echo "# Zscaler: domains + official IP ranges (classical RULE-SET)"
	echo "# IPs: config.zscaler.com — regenerate via update_zscaler_ruleset.sh ($(date -Iseconds 2>/dev/null || date))"
	echo "payload:"
	echo "  ## domains"
	echo "  - DOMAIN-SUFFIX,zscaler.com"
	echo "  - DOMAIN-SUFFIX,zscaler.net"
	echo "  - DOMAIN-SUFFIX,zscloud.net"
	echo "  - DOMAIN-SUFFIX,zscalerthree.net"
	echo "  - DOMAIN-SUFFIX,zscalerone.net"
	echo "  - DOMAIN-SUFFIX,zscalertwo.net"
	echo "  - DOMAIN-SUFFIX,zpath.net"
	echo "  ## IP ranges (no-resolve)"
	while read -r c; do
		[ -n "$c" ] || continue
		case "$c" in
			*:*) echo "  - IP-CIDR6,$c,no-resolve" ;;
			*) echo "  - IP-CIDR,$c,no-resolve" ;;
		esac
	done <"$RAW"
} >"$OUT"

rm -rf "$TMPDIR"
say "updated $OUT ($cnt cidrs + domains, $(wc -c <"$OUT") bytes)"
exit 0
