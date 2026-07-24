# Router A — ASUS RT-AX86U Pro / ShellCrash

SSH: `wenyulee@192.168.50.1`  
Core: Mihomo via ShellCrash，API `:9999`，mixed `:7890`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/rules.yaml` | `/jffs/ShellCrash/yamls/rules.yaml`（啟動插入規則最前） |
| `custom/ruleset/Zscaler.yaml` | `/jffs/ShellCrash/ruleset/Zscaler.yaml`（classical：域名+IP） |
| `custom/ruleset/Mail.yaml` | `/jffs/ShellCrash/ruleset/Mail.yaml` |
| `custom/ruleset/Rebrickable.yaml` | `/jffs/ShellCrash/ruleset/Rebrickable.yaml` |
| `custom/rebrickable_nodes.txt` | `/jffs/ShellCrash/yamls/rebrickable_nodes.txt` |
| `custom/ruleset/Japan.yaml` | `/jffs/ShellCrash/ruleset/Japan.yaml` |
| `custom/japan_nodes.txt` | `/jffs/ShellCrash/yamls/japan_nodes.txt` |
| `custom/ruleset/AI.yaml` | `/jffs/ShellCrash/ruleset/AI.yaml` |
| `custom/log_capture.sh` | `/jffs/ShellCrash/scripts/log_capture.sh`（連線紀錄存 `/tmp/ShellCrash/traffic.log`） |
| `custom/update_zscaler_ruleset.sh` | `/jffs/ShellCrash/scripts/update_zscaler_ruleset.sh` |
| `custom/update_sub_clean.sh` | `/jffs/ShellCrash/task/update_sub_clean.sh` |
| `custom/dnsmasq.conf.add` | `/jffs/configs/dnsmasq.conf.add` |
| `custom/user.yaml` | `/jffs/ShellCrash/yamls/user.yaml` |
| `custom/ShellCrash.cfg.dns-snippet` | 寫入 `ShellCrash.cfg` 的 `dns_*` / `multiport` |
| `custom/fulltcp_by_mac.sh` | `/jffs/ShellCrash/scripts/fulltcp_by_mac.sh` |
| `custom/fulltcp_mac.list` | `/jffs/ShellCrash/configs/fulltcp_mac.list` |
| `custom/task-afstart` | `/jffs/ShellCrash/task/afstart` |
| `custom/post_sub_clean.sh` | `/jffs/ShellCrash/yamls/post_sub_clean.sh` |
| `custom/wan-start` | `/jffs/scripts/wan-start` |
| `custom/ip_filter` | `/jffs/ShellCrash/configs/ip_filter`（保持清空） |
| `custom/tailscale/*` | `/jffs/tailscale/start.sh`、`/jffs/scripts/post-mount` |
| （訂閱 + post 生成） | `/jffs/ShellCrash/yamls/config.yaml` ↔ `/tmp/ShellCrash/config.yaml` |

## 訂製規則（`rules.yaml`）

| 規則 | 出口 |
|------|------|
| `RULE-SET,Zscaler` | 手动选择 |
| Firstrade api3x / streamingx / invest | 手动选择 |
| Firstrade 其餘 suffix | DIRECT |
| `RULE-SET,AppleMedia` | 手动选择（壓過訂閱預設 →Apple） |
| LinkedIn `.com` / `.cn` | 全球代理 / REJECT |
| `RULE-SET,Mail` | DIRECT（SMTP 587/465 + Purelymail IMAP） |
| `RULE-SET,Rebrickable` | **Rebrickable**（url-test 組） |
| `RULE-SET,Japan` | **Japan**（url-test 組；`.jp` + taigatakahashi.com） |
| `RULE-SET,AI` | **Ai+**（訂閱既有 OpenAI 也在此組；補訂閱漏掉的 Claude/Cursor/Gemini domain，避免落到漏网之鱼兜底） |

## 訂製說明

- **`user.yaml`**：DNS / hosts 覆蓋；勿寫頂層 `ipv6: false`（會與 ShellCrash `set.yaml` 重複導致 `-t` 失敗）。見 changelog DNS persist。
- **`ShellCrash.cfg`**：`dns_nameserver`、`multiport`（含 Zscaler `10301`）、mixed-port `authentication`（供 LAN 客戶端；郵箱不再經 B socks）。
- **`ruleset/`**：皆 **classical**。`update_zscaler_ruleset.sh` 重抓官方 IP 時會保留域名段，並用 awk 做 coverage-preserving 的 CIDR containment dedup（實測 2026-07-24：2482→807 條 IPv4，覆蓋範圍驗證不變）。
- **`post_sub_clean.sh`**：訂閱後剝假節點（只刪 `name: 'Expire:…'` 行）、注入 rule-providers + Rebrickable url-test 組、DNS/Firstrade harden、`-t`、備份。
- **訂閱更新**：`task.list` **104** 與 `task.user` **204** → `update_sub_clean.sh`（勿改回裸 `update_config`）。
- **軟體升級**：勿自動升 1.9.5**beta1**。
- **重啟後**：確認 `手动选择`→`自动选择`、`Apple`→`DIRECT`；必要時跑 `fulltcp_by_mac.sh`。
- **`log_capture.sh`**：ShellCrash 原廠 `start_legacy.sh` 把 CrashCore 的 log 導去 `/dev/null`；這支腳本改接 Mihomo `/logs?level=info` API 自己存檔，不動原廠腳本。掛在 `task-afstart`，自我重連、每次重連順便檢查大小做輪替（上限 5MB），存 `/tmp/ShellCrash/traffic.log`（tmpfs，重開機會清空，跟 B 的 `/tmp/openclash.log` 一樣）。

## Snippets

`snippets/dns-hosts.yaml` 從生效配置擷取。完整訂閱檔不入库。
