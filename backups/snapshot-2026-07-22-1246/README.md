# Snapshot 2026-07-22-1246

從 Router A / B **當下生效設定**拉取的備份（密碼／訂閱／節點憑證已脫敏）。

## 用途

- **對比**：訂閱更新或 ShellCrash／OpenClash 升級後，用本目錄與裝置上檔案 `diff`
- **還原訂製**：只還原下方「可安全上機」清單；**不要**把 `*.redacted.yaml` 整包蓋回裝置

## 可安全上機還原（A）

| 快照檔 | 裝置路徑 |
|--------|----------|
| `router-a/user.yaml` | `/jffs/ShellCrash/yamls/user.yaml` |
| `router-a/rules.yaml` | `/jffs/ShellCrash/yamls/rules.yaml` |
| `router-a/post_sub_clean.sh` | `/jffs/ShellCrash/yamls/post_sub_clean.sh` |
| `router-a/fulltcp_by_mac.sh` | `/jffs/ShellCrash/scripts/fulltcp_by_mac.sh` |
| `router-a/fulltcp_mac.list` | `/jffs/ShellCrash/configs/fulltcp_mac.list` |
| `router-a/task-afstart` | `/jffs/ShellCrash/task/afstart` |
| `router-a/wan-start` | `/jffs/scripts/wan-start` |
| `router-a/ip_filter` | `/jffs/ShellCrash/configs/ip_filter`（應為空） |
| `router-a/ShellCrash.cfg` | 僅對照；上機時手動合併 `dns_*` / `multiport`（檔內 auth／訂閱已 REDACTED） |

還原後：`/jffs/ShellCrash/start.sh restart`，再跑 `fulltcp_by_mac.sh`；確認 multiport 含 `10301`。

## 可安全上機還原（B）

| 快照檔 | 裝置路徑 |
|--------|----------|
| `router-b/openclash_custom_overwrite.sh` | `/etc/openclash/custom/openclash_custom_overwrite.sh`（還原後把 `REDACTED_PASSWORD` 改回 `via-RouterA` 真實密碼） |
| `router-b/openclash_custom_rules.list` | `/etc/openclash/custom/openclash_custom_rules.list` |

還原後：`/etc/init.d/openclash restart`。

## 僅供對比（勿整包覆蓋）

- `router-a/runtime-config.redacted.yaml` / `yamls-config.redacted.yaml`
- `router-b/runtime-ssLinks.redacted.yaml`
- `router-*/runtime-dns-hosts-rules.excerpt.yaml`
- `router-a/runtime-firewall-dns.txt`（DNS + iptables 摘要）
- `router-b/uci-openclash.redacted.txt`
- `manifest/sha256-*.txt`

## 當時關鍵狀態摘要

- A：`multiport` 含 `10301`；fulltcp MAC 三條；`ip_filter` 空；Firstrade DIRECT + LinkedIn 全球代理／`.cn` REJECT；DNS `direct-nameserver` 為 CF／DNSPod DoH（非 127.0.0.1）
- B：LinkedIn 規則僅在 `custom_rules.list`；Firstrade + gmail-out 在 overwrite；`china_ip_route=1`；雙 WAN `.180`/`.174`
- 公司 Mac LinkedIn／Zscaler：已擱置（見 `docs/changelog/2026-07-22-linkedin-keep-com.md`）
