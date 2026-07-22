# Router B — GL-MT3000 / OpenClash

SSH: `root@192.168.8.1`  
Core: OpenClash Meta，API `:9090`  
`config_path` UCI: `/etc/openclash/config/ssLinks.yaml`；實際核心常載入 `/etc/openclash/ssLinks.yaml`

## 上機路徑對照

| Repo | 裝置 |
|------|------|
| `custom/openclash_custom_overwrite.sh` | `/etc/openclash/custom/openclash_custom_overwrite.sh` |
| `custom/openclash_custom_rules.list` | `/etc/openclash/custom/openclash_custom_rules.list` |
| `custom/tailscale/uci-tailscale` | `/etc/config/tailscale` |
| （不入库） | `/etc/tailscale/tailscaled.state` |

UCI 相關：`enable_custom_clash_rules=1`、`enable_respect_rules=1`、`enable_redirect_dns=1`、`core_type=Meta`

## 訂製說明

- **overwrite**：剝假節點；注入 `via-RouterA` socks5；`gmail-out` fallback；Firstrade DNS policy / hosts / DIRECT 規則；Gmail SMTP → `gmail-out`。
- **custom rules**：Firstrade DIRECT、郵件與 Rebrickable（與 overwrite 互補；overwrite 會去重後再 unshift）。

密碼在 repo 中為 `REDACTED_MIXED_AUTH`，上機需改回與 A mixed-port auth 一致。
