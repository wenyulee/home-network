#!/bin/ash
# After subscription download: validate, strip fake nodes, secure LAN proxy, keep custom rules.
# Exit 0 = config OK (fresh or restored from backup) -> safe to restart.
# Exit 1 = nothing usable -> caller should SKIP restart and keep running service.
SRC="${SRC:-/jffs/ShellCrash/yamls/config.yaml}"
RULES="${RULES:-/jffs/ShellCrash/yamls/rules.yaml}"
BAK="${BAK:-/jffs/ShellCrash/yamls/config.yaml.bak}"
USBDIR=/tmp/mnt/sda1/shellcrash-backup
CORE=/tmp/ShellCrash/CrashCore
[ -x "$CORE" ] || CORE=/jffs/ShellCrash/CrashCore
LOG=/tmp/ShellCrash/ShellCrash.log
# Broken 2026-07-20 morning file was ~33KB; healthy ~72KB
MIN_BYTES="${MIN_BYTES:-50000}"
say() { echo "$(date "+%Y-%m-%d_%H:%M:%S")~$1" >>"$LOG"; echo "post_sub_clean: $1" >&2; }

# Mixed-port LAN auth — always from ShellCrash.cfg (never hardcode / REDACTED in script)
AUTH=$(grep "^authentication=" /jffs/ShellCrash/configs/ShellCrash.cfg 2>/dev/null | sed "s/^authentication=//;s/^'//;s/'$//")
[ -n "$AUTH" ] || AUTH="routerb:REDACTED_MIXED_AUTH"

[ -s "$SRC" ] || exit 0

core_test() { "$CORE" -t -d /jffs/ShellCrash -f "$1" >/dev/null 2>&1; }

restore_bak() {
	if [ -s "$BAK" ] && grep -q "name: 手动选择" "$BAK" && core_test "$BAK"; then
		cp -f "$BAK" "$SRC"
		say "订阅校验失败，已还原上一份可用配置"
		return 0
	fi
	say "订阅校验失败且无可用备份，保持当前运行配置"
	return 1
}

# 0. Size sanity (truncated / incomplete provider payloads)
BYTES=$(wc -c <"$SRC" | tr -d ' ')
if [ "$BYTES" -lt "$MIN_BYTES" ]; then
	say "订阅体积过小(${BYTES}<${MIN_BYTES})，疑似不完整"
	restore_bak || exit 1
fi

# 1. Structural check: key proxy groups must exist
if ! grep -q "name: 手动选择" "$SRC" || ! grep -q "name: 自动选择" "$SRC"; then
	say "订阅缺少关键分组(手动选择/自动选择)"
	restore_bak || exit 1
fi

# 1b. proxy-groups must not collapse to a single specialty group
GROUP_LINES=$(grep -c "type: select\|type: url-test\|type: fallback" "$SRC" 2>/dev/null)
[ -z "$GROUP_LINES" ] && GROUP_LINES=0
if [ "$GROUP_LINES" -lt 5 ]; then
	say "订阅分组过少(select/url-test/fallback=${GROUP_LINES}<5)"
	restore_bak || exit 1
fi

# 2. Clean: strip provider fake nodes (Expire/Traffic/Sync info rows ONLY — do not
#    drop whole proxy-group lines that merely *reference* those names), then
#    scrub leftover references from group proxy lists; force allow-lan + auth.
TMP=/tmp/sslinks-clean.$$
awk -v auth="$AUTH" '
  /name: '\''Expire:|name: '\''Traffic:|name: '\''Sync:/ { next }
  /^authentication:/ { next }
  /^allow-lan:/ { print "allow-lan: true"; next }
  { print }
  /^bind-address:/ { print "authentication: [\x27" auth "\x27]" }
' "$SRC" > "$TMP" && mv -f "$TMP" "$SRC"
# Remove dangling fake names from proxy-groups lists (otherwise -t fails)
sed -i \
  -e "s/'Expire: [^']*', *//g" \
  -e "s/'Traffic: [^']*', *//g" \
  -e "s/'Sync: [^']*', *//g" \
  "$SRC"

if ! grep -q "^authentication:" "$SRC"; then
	TMP=/tmp/sslinks-auth.$$
	awk -v auth="$AUTH" '
	  BEGIN{done=0}
	  /^mixed-port:/ && !done {
	    print
	    print "allow-lan: true"
	    print "authentication: [\x27" auth "\x27]"
	    done=1
	    next
	  }
	  /^allow-lan:/ { next }
	  /^authentication:/ { next }
	  { print }
	' "$SRC" > "$TMP" && mv -f "$TMP" "$SRC"
fi

# 2b. DNS harden + Firstrade hosts pin (Cloudflare DoH)
awk '
  /^[[:space:]]*direct-nameserver:/ {
    print "  direct-nameserver: [ \x27https://1.1.1.1/dns-query\x27, \x27https://doh.pub/dns-query\x27 ]"
    next
  }
  /^[[:space:]]*nameserver-policy:/ {
    print "  nameserver-policy: {\x22rule-set:cn\x22: [ 223.5.5.5, 119.29.29.29 ], \x22+.firstrade.com\x22: [ \x27https://1.1.1.1/dns-query\x27 ], \x22+.firstrade.net\x22: [ \x27https://1.1.1.1/dns-query\x27 ], \x22+.linkedin.com\x22: [ \x27https://1.1.1.1/dns-query\x27 ], \x22+.licdn.com\x22: [ \x27https://1.1.1.1/dns-query\x27 ]}"
    next
  }
  { print }
' "$SRC" > /tmp/sslinks-dns.$$ && mv -f /tmp/sslinks-dns.$$ "$SRC"
# Ensure top-level Firstrade hosts pins (shell-only)
# strip previous pins
for host in api3x.firstrade.com streamingx.firstrade.com rec.firstrade.net www.firstrade.com invest.firstrade.com; do
  sed -i "/^[[:space:]]*'${host}':/d;/^[[:space:]]*${host}:/d" "$SRC"
done
# remove existing top-level hosts block
awk '
  BEGIN{skip=0}
  /^hosts:/{skip=1; next}
  skip && /^[^[:space:]]/{skip=0}
  skip && /^[[:space:]]/{next}
  {print}
' "$SRC" > /tmp/sslinks-nohosts.$$ && mv -f /tmp/sslinks-nohosts.$$ "$SRC"
# prepend hosts before dns:
awk '
  BEGIN{
    print "hosts:"
    print "  '\''api3x.firstrade.com'\'': 54.230.70.76"
    print "  '\''streamingx.firstrade.com'\'': 18.65.14.45"
    print "  '\''rec.firstrade.net'\'': 13.226.69.45"
    print "  '\''www.firstrade.com'\'': 76.76.21.93"
    print "  '\''invest.firstrade.com'\'': 54.230.70.83"
    print "  '\''www.linkedin.com'\'': 104.18.41.41"
    print "  '\''linkedin.com'\'': 130.211.32.14"
    print ""
  }
  {print}
' "$SRC" > /tmp/sslinks-hosts.$$ && mv -f /tmp/sslinks-hosts.$$ "$SRC"

say "Firstrade clean-DoH + hosts pin applied"

# 2c. Drop subscription-baked Firstrade DOMAIN rules (canonical: yamls/rules.yaml)
awk '
  /Firstrade managed/ { next }
  { print }
' "$SRC" > /tmp/sslinks-dedupe.$$ && mv -f /tmp/sslinks-dedupe.$$ "$SRC"
say "Stripped duplicate #Firstrade managed rules (use rules.yaml)"

# 2d. Inject local file rule-providers (classical bundles + Zscaler)
awk '
  /Zscaler:[[:space:]]*\{/ { next }
  /ZscalerDomains:[[:space:]]*\{/ { next }
  /MailSMTP:[[:space:]]*\{/ { next }
  /Rebrickable:[[:space:]]*\{ type: file/ { next }
  /^rule-providers:/ {
    print
    print "    Zscaler: { type: file, behavior: classical, path: ./ruleset/Zscaler.yaml }"
    print "    MailSMTP: { type: file, behavior: classical, path: ./ruleset/MailSMTP.yaml }"
    print "    Rebrickable: { type: file, behavior: classical, path: ./ruleset/Rebrickable.yaml }"
    next
  }
  { print }
' "$SRC" > /tmp/sslinks-providers.$$ && mv -f /tmp/sslinks-providers.$$ "$SRC"
say "Local rule-providers injected (Zscaler/MailSMTP/Rebrickable)"

# 2e. Inject Rebrickable url-test group (CF-safe nodes only; see rebrickable_nodes.txt)
RB_NODES_FILE=/jffs/ShellCrash/yamls/rebrickable_nodes.txt
[ -s "$RB_NODES_FILE" ] || RB_NODES_FILE=/jffs/ShellCrash/rebrickable_nodes.txt
# Drop any previous Rebrickable group line
sed -i "/name: Rebrickable[, }]/d" "$SRC" 2>/dev/null
if [ -s "$RB_NODES_FILE" ]; then
	RB_LIST=""
	while IFS= read -r n || [ -n "$n" ]; do
		case "$n" in \#*|"") continue ;; esac
		# only keep names that still exist in this subscription
		if grep -q "'$n'" "$SRC" 2>/dev/null; then
			if [ -n "$RB_LIST" ]; then
				RB_LIST="$RB_LIST, '$n'"
			else
				RB_LIST="'$n'"
			fi
		fi
	done < "$RB_NODES_FILE"
	if [ -n "$RB_LIST" ]; then
		awk -v plist="$RB_LIST" '
		  /^proxy-groups:/ {
		    print
		    print "    - { name: Rebrickable, type: url-test, proxies: [" plist "], tolerance: 50, lazy: true, url: '\''https://rebrickable.com/api/v3/'\'', interval: 300, expected-status: 200 }"
		    next
		  }
		  { print }
		' "$SRC" > /tmp/sslinks-rebrick.$$ && mv -f /tmp/sslinks-rebrick.$$ "$SRC"
		say "Rebrickable url-test group injected"
	else
		say "Rebrickable: no listed nodes present in subscription (skipped)"
	fi
fi

# 3. Full validation with the core itself (same check ShellCrash uses at startup)
if ! core_test "$SRC"; then
	say "订阅内核校验(-t)失败"
	restore_bak || exit 1
fi

# 4. Refresh known-good backup + rotate dated copies to USB (keep 7)
cp -f "$SRC" "$BAK"
if [ -d /tmp/mnt/sda1 ] && mkdir -p "$USBDIR" 2>/dev/null; then
	cp -f "$SRC" "$USBDIR/config-$(date +%Y%m%d-%H%M).yaml" 2>/dev/null
	ls -t "$USBDIR"/config-*.yaml 2>/dev/null | tail -n +8 | while read f; do rm -f "$f"; done
fi
say "订阅校验通过，备份已更新"

# 5. Custom rules file (create once) — prefer RULE-SET bundles
if [ ! -s "$RULES" ]; then
cat > "$RULES" <<'RULESEOF'
# ShellCrash 自定义规则（启动时自动插入最前）
- RULE-SET,Zscaler,手动选择,no-resolve
- RULE-SET,MailSMTP,DIRECT
- RULE-SET,Rebrickable,Rebrickable
RULESEOF
fi
exit 0
