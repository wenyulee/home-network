#!/bin/sh
# Router B (OpenWrt, mobile — no dependency on Router A): fetch official Zscaler
# IP ranges → Clash classical rule-provider (domains + IP-CIDR), independently of
# whatever WAN B currently has (home double-proxy behind A, cellular, other Wi-Fi).
# Tries a direct fetch first (works on any network); falls back to B's own
# mixed-port proxy only if direct fails. IPv4 CIDRs are collapsed (containment
# dedup, coverage-preserving — see router-a-asus-merlin/custom/update_zscaler_ruleset.sh
# for the verified algorithm, identical here). IPv6 stays dedup-only.
set -e
OUT="${1:-/etc/openclash/rule_provider/Zscaler.yaml}"
TMPDIR="/tmp/zscaler-fetch-b.$$"
mkdir -p "$TMPDIR" "$(dirname "$OUT")"
LOG=/tmp/openclash.log
say() { echo "$(date "+%Y-%m-%d_%H:%M:%S")~$1" >>"$LOG" 2>/dev/null; echo "zscaler_ruleset(B): $1" >&2; }

MIXED_PORT=$(uci -q get openclash.config.mixed_port || echo 7893)
AUTH_ENABLED=$(uci -q get openclash.@authentication[0].enabled 2>/dev/null || echo 0)
AUTH=""
if [ "$AUTH_ENABLED" = "1" ]; then
	AUTH_USER=$(uci -q get openclash.@authentication[0].username 2>/dev/null || true)
	AUTH_PASS=$(uci -q get openclash.@authentication[0].password 2>/dev/null || true)
	[ -n "$AUTH_USER" ] && AUTH="${AUTH_USER}:${AUTH_PASS}"
fi

fetch() {
	url="$1"; out="$2"
	# direct first — no dependency on B's own proxy state when mobile
	curl -fsSL --connect-timeout 8 --max-time 30 -o "$out" "$url" && return 0
	if [ -n "$AUTH" ]; then
		curl -fsSL --connect-timeout 12 --max-time 45 -x "http://${AUTH}@127.0.0.1:${MIXED_PORT}" -o "$out" "$url" && return 0
	else
		curl -fsSL --connect-timeout 12 --max-time 45 -x "http://127.0.0.1:${MIXED_PORT}" -o "$out" "$url" && return 0
	fi
	return 1
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

# Collapse IPv4: drop any /n fully covered by a broader CIDR already in the set.
V4RAW="$TMPDIR/v4.txt"
V6RAW="$TMPDIR/v6.txt"
grep -v ':' "$RAW" >"$V4RAW" || true
grep ':' "$RAW" >"$V6RAW" || true
v4cnt=$(wc -l <"$V4RAW" | tr -d ' ')
if [ "$v4cnt" -gt 0 ]; then
	awk -F/ '{print $2, $0}' "$V4RAW" | sort -n -k1,1 | cut -d' ' -f2- \
		| awk '
			function pow2(n,   r,i) { r = 1; for (i = 0; i < n; i++) r = r * 2; return r }
			function ip2int(ip,   a) { split(ip, a, "."); return a[1]*16777216 + a[2]*65536 + a[3]*256 + a[4] }
			{
				split($0, parts, "/")
				plen = parts[2] + 0
				blocksize = pow2(32 - plen)
				masked = int(ip2int(parts[1]) / blocksize) * blocksize
				contained = 0
				for (i = 1; i <= nbroad; i++) {
					bs = broad_blocksize[i]
					if (int(masked / bs) * bs == broad_net[i]) { contained = 1; break }
				}
				if (contained) next
				kept[++nkept] = masked "/" plen
				if (plen < 32) {
					nbroad++
					broad_net[nbroad] = masked
					broad_blocksize[nbroad] = blocksize
				}
			}
			END {
				for (i = 1; i <= nkept; i++) {
					split(kept[i], kp, "/")
					n = kp[1] + 0
					o1 = int(n / 16777216); n = n - o1*16777216
					o2 = int(n / 65536);    n = n - o2*65536
					o3 = int(n / 256);      o4 = n - o3*256
					print o1"."o2"."o3"."o4"/"kp[2]
				}
			}
		' >"$TMPDIR/v4_collapsed.txt"
	newv4cnt=$(wc -l <"$TMPDIR/v4_collapsed.txt" | tr -d ' ')
	if [ "$newv4cnt" -gt 0 ]; then
		cat "$TMPDIR/v4_collapsed.txt" "$V6RAW" | sort -u >"$RAW"
		say "collapsed IPv4 CIDRs $v4cnt -> $newv4cnt (coverage-preserving containment dedup)"
	fi
fi
cnt=$(wc -l <"$RAW" | tr -d ' ')

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
