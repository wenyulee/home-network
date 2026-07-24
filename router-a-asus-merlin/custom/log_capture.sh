#!/bin/ash
# Persist Mihomo's per-connection match log to disk (A's CrashCore is launched
# via ShellCrash's stock start_legacy.sh with stdout/stderr redirected to
# /dev/null, so nothing is otherwise captured — unlike B, where OpenClash
# itself writes to /tmp/openclash.log). Taps the same info the dashboard
# shows, via Mihomo's own /logs API, instead of patching vendored ShellCrash
# scripts that would be overwritten on update.
# Self-healing: the outer loop reconnects if CrashCore restarts (connection
# drops); rotation is handled by a separate cron entry (see README).
API="http://127.0.0.1:9999/logs?level=info"
LOG=/tmp/ShellCrash/traffic.log
PIDFILE=/tmp/ShellCrash/log_capture.pid
mkdir -p /tmp/ShellCrash

# refuse to start a second instance
if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
	exit 0
fi

MAX_BYTES=5000000

(
	while true; do
		# rotate on every (re)connect — daily subscription restart guarantees
		# at least one reconnect/day even if the stream itself never drops
		if [ -s "$LOG" ]; then
			bytes=$(wc -c <"$LOG" | tr -d ' ')
			[ "$bytes" -gt "$MAX_BYTES" ] && : >"$LOG"
		fi
		curl -s --max-time 0 "$API" >>"$LOG" 2>/dev/null
		sleep 5
	done
) </dev/null >/dev/null 2>&1 &
echo $! >"$PIDFILE"
