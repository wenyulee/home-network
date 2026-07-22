# Router A — ASUS RT-AX86U Pro / ShellCrash

SSH: `wenyulee@192.168.50.1`  
Core: Mihomo via ShellCrash，API `:9999`，mixed `:7890`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/rules.yaml` | `/jffs/ShellCrash/yamls/rules.yaml` |
| `custom/post_sub_clean.sh` | `/jffs/ShellCrash/yamls/post_sub_clean.sh` |
| `custom/wan-start` | `/jffs/scripts/wan-start` |
| `custom/ip_filter` | `/jffs/ShellCrash/configs/ip_filter` |
| `custom/tailscale/start.sh` | `/jffs/tailscale/start.sh` |
| `custom/tailscale/post-mount.sh` | `/jffs/scripts/post-mount`（含 Tailscale 啟動段） |
| （由訂閱 + post 生成） | `/jffs/ShellCrash/yamls/config.yaml` ↔ runtime `/tmp/ShellCrash/config.yaml` |
| （不入库） | `/tmp/mnt/sda1/tailscale/bin/*`、`…/state/tailscaled.state` |

## 訂製說明

- **`rules.yaml`**：啟動時插到規則最前。含 Firstrade DIRECT、SMTP DIRECT、Rebrickable 西班牙節點。
- **`post_sub_clean.sh`**：訂閱下載後：體積/結構檢查、剝假節點、LAN auth、DNS harden、Firstrade hosts pin、`-t` 校驗、備份。
- **`wan-start`**：WAN 起來時強制系統 DNS 為阿里/DNSPod。
- **`ip_filter`**：ShellCrash IP 黑/白名單。目前為空（B 二次代理排除已回溯）。

## Snippets

`snippets/dns-hosts.yaml` 從 2026-07-22 生效配置擷取（含 Firstrade hosts + DNS）。完整訂閱檔不入库。
