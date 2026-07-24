# Router B — GL-MT3000 / OpenClash

SSH: `root@192.168.8.1`  
Core: OpenClash Meta，API `:9090`，mixed `:7893`  
`config_path` UCI: `/etc/openclash/config/ssLinks.yaml`；執行期常載入 `/etc/openclash/ssLinks.yaml`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/openclash_custom_overwrite.sh` | `/etc/openclash/custom/openclash_custom_overwrite.sh` |
| `custom/openclash_custom_rules.list` | `/etc/openclash/custom/openclash_custom_rules.list` |
| `custom/rebrickable_nodes.txt` | `/etc/openclash/custom/rebrickable_nodes.txt` |
| （與 A 共用內容）`../router-a-asus-merlin/custom/ruleset/*.yaml` | `/etc/openclash/rule_provider/{Zscaler,MailSMTP,Rebrickable}.yaml` |
| `custom/tailscale/uci-tailscale` | `/etc/config/tailscale` |
| （不入库） | `/etc/tailscale/tailscaled.state` |

UCI：`enable_custom_clash_rules=1`、`enable_respect_rules=1`、`enable_redirect_dns=1`、`core_type=Meta`、fake-ip  
IPv6：`dhcp.lan.ra/dhcpv6=disabled`、`network.wan.ipv6=0`

## 訂製規則（`openclash_custom_rules.list`）

與 A 對齊：`Zscaler` / `AppleMedia`→手动选择；`MailSMTP`→DIRECT；`Rebrickable`→Rebrickable 組；Firstrade 細分；LinkedIn。

> OpenClash 在組尚未存在時可能丟棄指向該組的 custom 規則；overwrite 會在注入 **Rebrickable** url-test 組後再確保 `RULE-SET,Rebrickable,Rebrickable`。

## 訂製說明

- **overwrite**：剝假節點與舊 `via-RouterA`/`gmail-out`；注入 classical rule-providers；注入 Rebrickable url-test（節點來自 `rebrickable_nodes.txt`）；Firstrade/LinkedIn DNS policy + hosts。
- **郵件**：SMTP 走 `MailSMTP`→DIRECT（不再經 A mixed-port）。
- **AppleMedia**：與訂閱共用規則集檔；前置 `→手动选择` 覆蓋預設 `→Apple`。

## 新機一鍵安裝（U 盤）

見 [`usb-bootstrap/README.md`](usb-bootstrap/README.md)：**僅裝 Zscaler** 訂製規則；其餘訂製仍用本目錄 `custom/` 手動同步。
