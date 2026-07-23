#!/bin/ash
CRASHDIR=/jffs/ShellCrash
. "$CRASHDIR/libs/get_config.sh"
. "$CRASHDIR/libs/check_cmd.sh"
. "$CRASHDIR/libs/check_target.sh"
. "$CRASHDIR/libs/logger.sh"
. "$CRASHDIR/starts/core_config.sh"
get_core_config || exit 1
# Refresh Zscaler IP rule-set (best-effort; keep going if fetch fails)
[ -x "$CRASHDIR/scripts/update_zscaler_ruleset.sh" ] && \
	"$CRASHDIR/scripts/update_zscaler_ruleset.sh" "$CRASHDIR/ruleset/Zscaler.yaml" || true
if "$CRASHDIR/yamls/post_sub_clean.sh"; then
	"$CRASHDIR/start.sh" restart
else
	logger "订阅更新校验失败且无可用备份，跳过重启以保持当前服务" 31
fi
