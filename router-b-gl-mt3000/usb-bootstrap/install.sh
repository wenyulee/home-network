#!/bin/sh
# Router B (GL-MT3000) — USB install: Zscaler custom rules only.
#   sh /tmp/mountd/disk1_part1/router-b-bootstrap/install.sh
set -e

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PAYLOAD="$ROOT/payload"
SECRETS="$ROOT/secrets.env"
LOG=/tmp/router-b-bootstrap.log

say() { echo "[router-b-bootstrap] $*"; echo "$(date '+%F %T') $*" >>"$LOG"; }
die() { say "ERROR: $*"; exit 1; }

[ "$(id -u)" = "0" ] || die "must run as root"
[ -f /etc/openwrt_release ] || die "not OpenWrt"
[ -d "$PAYLOAD" ] || die "missing payload/ next to install.sh"
[ -f "$PAYLOAD/Zscaler.yaml" ] || die "missing payload/Zscaler.yaml"

if [ -f "$SECRETS" ]; then
	# shellcheck disable=SC1090
	. "$SECRETS"
fi

: "${OPENCLASH_DASHBOARD_PASS:=}"
: "${SUB_URL:=}"
: "${SUB_NAME:=ssLinks}"

say "ROOT=$ROOT (Zscaler-only)"
say "model=$(cat /tmp/sysinfo/model 2>/dev/null || echo unknown) fw=$(cat /etc/glversion 2>/dev/null || echo ?)"

if ! opkg list-installed 2>/dev/null | grep -q '^luci-app-openclash '; then
	die "luci-app-openclash not installed. Install OpenClash first, then re-run."
fi
if ! opkg list-installed 2>/dev/null | grep -q '^ruby '; then
	die "ruby not installed (overwrite needs it). Install ruby + ruby-yaml, then re-run."
fi

mkdir -p /etc/openclash/custom /etc/openclash/config /etc/openclash/rule_provider

say "install Zscaler custom rules + provider + overwrite"
cp -f "$PAYLOAD/openclash_custom_rules.list" /etc/openclash/custom/openclash_custom_rules.list
cp -f "$PAYLOAD/openclash_custom_overwrite.sh" /etc/openclash/custom/openclash_custom_overwrite.sh
cp -f "$PAYLOAD/Zscaler.yaml" /etc/openclash/rule_provider/Zscaler.yaml
rm -f /etc/openclash/rule_provider/ZscalerDomains.yaml
chmod 644 /etc/openclash/custom/openclash_custom_rules.list /etc/openclash/rule_provider/Zscaler.yaml
chmod 755 /etc/openclash/custom/openclash_custom_overwrite.sh

say "enable OpenClash custom rules UCI"
uci set openclash.config.enable='1'
uci set openclash.config.core_type='Meta'
uci set openclash.config.enable_custom_clash_rules='1'
uci set openclash.config.enable_respect_rules='1'
[ -n "$OPENCLASH_DASHBOARD_PASS" ] && uci set openclash.config.dashboard_password="$OPENCLASH_DASHBOARD_PASS"
if [ -n "$SUB_URL" ]; then
	if ! uci -q get openclash.@config_subscribe[0] >/dev/null; then
		uci add openclash config_subscribe >/dev/null
	fi
	uci set openclash.@config_subscribe[0].enabled='1'
	uci set openclash.@config_subscribe[0].name="$SUB_NAME"
	uci set openclash.@config_subscribe[0].address="$SUB_URL"
	uci set openclash.@config_subscribe[0].sub_ua='clash.meta'
	uci set openclash.config.config_path="/etc/openclash/config/${SUB_NAME}.yaml"
	say "subscription URL set ($SUB_NAME)"
fi
uci commit openclash

say "restart OpenClash"
/etc/init.d/openclash stop >/dev/null 2>&1 || true
sleep 1
/etc/init.d/openclash start || die "openclash start failed"
sleep 4

CFG=""
[ -f /etc/openclash/ssLinks.yaml ] && CFG=/etc/openclash/ssLinks.yaml
[ -f /etc/openclash/config/ssLinks.yaml ] && CFG=/etc/openclash/config/ssLinks.yaml
if [ -n "$CFG" ] && grep -q 'RULE-SET,Zscaler' "$CFG" 2>/dev/null; then
	say "OK: RULE-SET,Zscaler present in $CFG"
elif [ -n "$CFG" ]; then
	say "WARN: config exists but Zscaler rule not visible yet — update subscription once in Luci"
else
	say "WARN: no config yaml yet — set subscription in Luci, then restart OpenClash"
fi

say "DONE (Zscaler-only). log: $LOG"
exit 0
