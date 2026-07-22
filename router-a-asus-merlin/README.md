# Router A — ASUS RT-AX86U Pro / ShellCrash

SSH: `wenyulee@192.168.50.1`  
Core: Mihomo via ShellCrash，API `:9999`，mixed `:7890`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/rules.yaml` | `/jffs/ShellCrash/yamls/rules.yaml` |
| `custom/user.yaml` | `/jffs/ShellCrash/yamls/user.yaml`（DNS/hosts 覆盖，防 restart 回退） |
| `custom/ShellCrash.cfg.dns-snippet` | 写入 `/jffs/ShellCrash/configs/ShellCrash.cfg` 的 `dns_*` 项 |
| `custom/fulltcp_by_mac.sh` | `/jffs/ShellCrash/scripts/fulltcp_by_mac.sh` |
| `custom/fulltcp_mac.list` | `/jffs/ShellCrash/configs/fulltcp_mac.list` |
| `custom/task-afstart` | `/jffs/ShellCrash/task/afstart`（含 fulltcp 调用） |
| `custom/post_sub_clean.sh` | `/jffs/ShellCrash/yamls/post_sub_clean.sh` |
| `custom/wan-start` | `/jffs/scripts/wan-start` |
| `custom/ip_filter` | `/jffs/ShellCrash/configs/ip_filter` |
| `custom/tailscale/start.sh` | `/jffs/tailscale/start.sh` |
| `custom/tailscale/post-mount.sh` | `/jffs/scripts/post-mount`（含 Tailscale 啟動段） |
| （由訂閱 + post 生成） | `/jffs/ShellCrash/yamls/config.yaml` ↔ runtime `/tmp/ShellCrash/config.yaml` |
| （不入库） | `/tmp/mnt/sda1/tailscale/bin/*`、`…/state/tailscaled.state` |

## 訂製說明

- **`user.yaml`**：ShellCrash 官方合并覆盖。含 `dns:` / `hosts:` 时，启动**不会**再生成把 `direct-nameserver` 指到 `127.0.0.1` 的默认 DNS 块。见 `docs/changelog/2026-07-22-a-dns-persist.md`。
- **`ShellCrash.cfg` `dns_nameserver=…`**：显式国内 DNS，避免 `get_config.sh` 因本机 dnsmasq 自动改成 `127.0.0.1`。
- **`rules.yaml`**：啟動時插到規則最前。含 Firstrade DIRECT、SMTP DIRECT、Rebrickable 西班牙節點。
- **`post_sub_clean.sh`**：訂閱下載後：體積/結構檢查、剝假節點、LAN auth、DNS harden、Firstrade hosts pin、`-t` 校驗、備份。
- **`wan-start`**：WAN 起來時強制系統 DNS 為阿里/DNSPod。
- **`ip_filter`**：ShellCrash LAN IP 過濾（黑名單 → 源 IP `RETURN`）。**保持清空**：不排除 B WAN；B 側 `192.168.8.182` 依賴雙層代理才能上大部分網站。

## Snippets

`snippets/dns-hosts.yaml` 從 2026-07-22 生效配置擷取（含 Firstrade hosts + DNS）。完整訂閱檔不入库。
