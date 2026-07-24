# Router B — GL-MT3000 / OpenClash

SSH: `root@192.168.8.1`  
Core: OpenClash Meta，API `:9090`，mixed `:7893`  
`config_path` UCI: `/etc/openclash/config/ssLinks.yaml`；執行期常載入 `/etc/openclash/ssLinks.yaml`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/openclash_custom_overwrite.sh` | `/etc/openclash/custom/openclash_custom_overwrite.sh` |
| `custom/openclash_custom_rules.list` | `/etc/openclash/custom/openclash_custom_rules.list` |
| `custom/update_zscaler_ruleset.sh` | `/etc/openclash/custom/update_zscaler_ruleset.sh`（cron `55 3 * * *`，獨立於 A，不依賴 A 是否在線） |
| `custom/rebrickable_nodes.txt` | `/etc/openclash/custom/rebrickable_nodes.txt` |
| `custom/japan_nodes.txt` | `/etc/openclash/custom/japan_nodes.txt` |
| （與 A 共用內容）`../router-a-asus-merlin/custom/ruleset/*.yaml` | `/etc/openclash/rule_provider/{Zscaler,Mail,Rebrickable,Japan,AI}.yaml` |
| `custom/tailscale/uci-tailscale` | `/etc/config/tailscale` |
| （不入库） | `/etc/tailscale/tailscaled.state` |

UCI：`enable_custom_clash_rules=1`、`enable_respect_rules=1`、`enable_redirect_dns=1`、`core_type=Meta`、fake-ip  
IPv6：`dhcp.lan.ra/dhcpv6=disabled`、`network.wan.ipv6=0`

## 訂製規則（`openclash_custom_rules.list`）

與 A 對齊：`Zscaler` / `AppleMedia`→手动选择；`Mail`→DIRECT（SMTP + Purelymail IMAP）；`Rebrickable`→Rebrickable 組；`Japan`→Japan 組；Firstrade 細分；LinkedIn；`AI`→Ai+（Claude/claudeusercontent、Cursor/cursorapi、Gemini 等，補訂閱 OpenAI.yaml/Google.yaml 沒涵蓋或分錯組的部分）。

> OpenClash 在組尚未存在時可能丟棄指向該組的 custom 規則；overwrite 會在注入 **Rebrickable**/**Japan** url-test 組後再確保對應的 `RULE-SET,Rebrickable,Rebrickable` / `RULE-SET,Japan,Japan`。

## 訂製說明

- **overwrite**：剝假節點與舊 `via-RouterA`/`gmail-out`；注入 classical rule-providers；注入 Rebrickable / Japan url-test 組（節點分別來自 `rebrickable_nodes.txt` / `japan_nodes.txt`）；Firstrade/LinkedIn DNS policy + hosts。
- **郵件**：SMTP + Purelymail IMAP 走 `Mail`→DIRECT（不再經 A mixed-port）。
- **AppleMedia**：與訂閱共用規則集檔；前置 `→手动选择` 覆蓋預設 `→Apple`。
- **Zscaler 刷新**：`update_zscaler_ruleset.sh` 獨立於 A 運作（direct fetch 優先，失敗才走 B 自己的 mixed-port；帳密用 `uci get` 動態讀，不寫死），B 帶出門時照常更新；`type: file` rule-provider 檔案本身會被 Mihomo 核心依 mtime 自動重讀，不需要 restart。

## 新機一鍵安裝（U 盤）

見 [`usb-bootstrap/README.md`](usb-bootstrap/README.md)。
