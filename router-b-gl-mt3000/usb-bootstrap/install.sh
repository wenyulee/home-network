#!/bin/sh
# Router B (GL-MT3000) — one-shot install from USB.
# Run on the router after plugging the stick, e.g.:
#   sh /tmp/mountd/disk1_part1/router-b-bootstrap/install.sh
# or:
#   sh /mnt/sda1/router-b-bootstrap/install.sh
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

if [ -f "$SECRETS" ]; then
	# shellcheck disable=SC1090
	. "$SECRETS"
else
	say "WARN: no secrets.env — using placeholders / skipping subscribe"
fi

: "${OPENCLASH_DASHBOARD_PASS:=changeme}"
: "${SUB_URL:=}"
: "${SUB_NAME:=ssLinks}"

say "ROOT=$ROOT"
say "model=$(cat /tmp/sysinfo/model 2>/dev/null || echo unknown) fw=$(cat /etc/glversion 2>/dev/null || echo ?)"

# --- prerequisites ---
if ! opkg list-installed 2>/dev/null | grep -q '^luci-app-openclash '; then
	die "luci-app-openclash not installed. Install OpenClash from GL Apps / Softcenter first, then re-run."
fi
if ! opkg list-installed 2>/dev/null | grep -q '^ruby '; then
	die "ruby not installed (OpenClash overwrite needs it). Install ruby + ruby-yaml, then re-run."
fi

mkdir -p /etc/openclash/custom /etc/openclash/config /etc/openclash/rule_provider /etc/tailscale

# --- custom OpenClash files ---
say "install OpenClash custom files"
cp -f "$PAYLOAD/openclash_custom_rules.list" /etc/openclash/custom/openclash_custom_rules.list
cp -f "$PAYLOAD/openclash_custom_overwrite.sh" /etc/openclash/custom/openclash_custom_overwrite.sh
for f in Zscaler.yaml Mail.yaml Rebrickable.yaml Japan.yaml AI.yaml; do
	[ -f "$PAYLOAD/$f" ] && cp -f "$PAYLOAD/$f" /etc/openclash/rule_provider/"$f"
done
rm -f /etc/openclash/rule_provider/ZscalerDomains.yaml /etc/openclash/rule_provider/MailSMTP.yaml
for n in rebrickable_nodes.txt japan_nodes.txt; do
	[ -f "$PAYLOAD/$n" ] && cp -f "$PAYLOAD/$n" /etc/openclash/custom/"$n"
done
chmod 644 /etc/openclash/custom/openclash_custom_rules.list /etc/openclash/rule_provider/*.yaml 2>/dev/null || true
chmod 755 /etc/openclash/custom/openclash_custom_overwrite.sh

# --- independent Zscaler IP-range refresh (no dependency on Router A) ---
if [ -f "$PAYLOAD/update_zscaler_ruleset.sh" ]; then
	cp -f "$PAYLOAD/update_zscaler_ruleset.sh" /etc/openclash/custom/update_zscaler_ruleset.sh
	chmod 755 /etc/openclash/custom/update_zscaler_ruleset.sh
	if ! crontab -l 2>/dev/null | grep -q "zscaler-ruleset-refresh"; then
		(crontab -l 2>/dev/null; echo "55 3 * * * /etc/openclash/custom/update_zscaler_ruleset.sh #zscaler-ruleset-refresh") | crontab -
		say "Zscaler refresh cron installed (55 3 * * *)"
	fi
fi

# --- OpenClash UCI ---
say "apply OpenClash UCI"
uci set openclash.config.enable='1'
uci set openclash.config.core_type='Meta'
uci set openclash.config.enable_custom_clash_rules='1'
uci set openclash.config.enable_respect_rules='1'
uci set openclash.config.enable_redirect_dns='1'
uci set openclash.config.redirect_dns='1'
uci set openclash.config.enable_udp_proxy='1'
uci set openclash.config.enable_meta_sniffer='1'
uci set openclash.config.enable_meta_sniffer_pure_ip='1'
uci set openclash.config.proxy_mode='rule'
uci set openclash.config.operation_mode='fake-ip'
uci set openclash.config.en_mode='fake-ip'
uci set openclash.config.ipv6_enable='0'
uci set openclash.config.ipv6_dns='0'
uci set openclash.config.mixed_port='7893'
uci set openclash.config.default_dashboard='zashboard'
uci set openclash.config.dashboard_password="$OPENCLASH_DASHBOARD_PASS"
uci set openclash.config.config_path='/etc/openclash/config/ssLinks.yaml'

# subscription
if [ -n "$SUB_URL" ]; then
	# ensure at least one config_subscribe section
	if ! uci -q get openclash.@config_subscribe[0] >/dev/null; then
		uci add openclash config_subscribe >/dev/null
	fi
	uci set openclash.@config_subscribe[0].enabled='1'
	uci set openclash.@config_subscribe[0].name="$SUB_NAME"
	uci set openclash.@config_subscribe[0].address="$SUB_URL"
	uci set openclash.@config_subscribe[0].sub_ua='clash.meta'
	uci set openclash.config.config_path="/etc/openclash/config/${SUB_NAME}.yaml"
	say "subscription URL set ($SUB_NAME)"
else
	say "WARN: SUB_URL empty — add subscription in Luci OpenClash after install"
fi
uci commit openclash

# --- LAN/WAN IPv6 off (matches home-network policy) ---
say "disable LAN RA/DHCPv6 + WAN IPv6"
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci -q set dhcp.lan.ndp='disabled' || true
uci set network.wan.ipv6='0'
uci -q delete network.lan.ip6assign || true
uci -q delete network.lan.ip6hint || true
uci -q delete network.lan.ip6ifaceid || true
uci -q delete network.lan.ip6class || true
uci commit dhcp
uci commit network
/etc/init.d/odhcpd restart >/dev/null 2>&1 || true

# --- Tailscale (enable only; login separately) ---
if [ -f "$PAYLOAD/uci-tailscale" ]; then
	say "install Tailscale UCI (enabled=1; auth still needed)"
	cp -f "$PAYLOAD/uci-tailscale" /etc/config/tailscale
	uci set tailscale.settings.enabled='1'
	uci commit tailscale
	[ -x /etc/init.d/tailscale ] && /etc/init.d/tailscale enable || true
fi

# --- pull subscription + restart OpenClash ---
say "restart OpenClash"
/etc/init.d/openclash stop >/dev/null 2>&1 || true
sleep 1

# OpenClash update subscribe if helper exists
if [ -n "$SUB_URL" ] && [ -x /usr/share/openclash/openclash.sh ]; then
	say "try OpenClash subscribe update"
	# common entrypoints differ by version — best-effort
	/usr/share/openclash/openclash.sh reload >/dev/null 2>&1 || true
fi

/etc/init.d/openclash start || die "openclash start failed"
sleep 4

# verify custom bits landed after first start/overwrite
if [ -f /etc/openclash/ssLinks.yaml ] || [ -f /etc/openclash/config/ssLinks.yaml ]; then
	CFG=/etc/openclash/ssLinks.yaml
	[ -f /etc/openclash/config/ssLinks.yaml ] && CFG=/etc/openclash/config/ssLinks.yaml
	if grep -q 'RULE-SET,Zscaler' "$CFG" 2>/dev/null || grep -q 'AppleMedia,手动' "$CFG" 2>/dev/null; then
		say "OK: custom rules present in $CFG"
	else
		say "WARN: config exists but custom rules not visible yet — open Luci → OpenClash → update subscription once"
	fi
else
	say "WARN: no ssLinks.yaml yet — update subscription in Luci OpenClash"
fi

say "DONE"
say "Next:"
say "  1) Luci OpenClash: update subscription if config empty"
say "  2) Set 手动选择 → 自动选择; Apple → DIRECT"
say "  3) Tailscale: luci or 'tailscale up' to login"
say "log: $LOG"
exit 0
