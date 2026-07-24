# home-network

家用雙路由拓樸與 Clash / OpenClash **訂製設定**備份（不含訂閱節點全文與機密）。

| 裝置 | 角色 | LAN | 代理 |
|------|------|-----|------|
| **Router A** ASUS RT-AX86U Pro (Merlin) | 主路由 / WAN→GreeNet CPE | `192.168.50.1` | ShellCrash / Mihomo `:9999`，mixed `7890` |
| **Router B** GL-MT3000 (OpenWrt) | 二層 AP/路由 | `192.168.8.1` | OpenClash / Mihomo `:9090`，mixed `7893` |
| B WAN | 有線 + Wi‑Fi 備援掛在 A 後 | `192.168.50.180`（metric 1）、`192.168.50.174`（metric 2） | |

機密請用本機 `secrets.example` 對照裝置上的真實值；repo 內密碼已改為 `REDACTED_*`。

## 目錄

```
router-a-asus-merlin/custom/          # A 訂製（上機路徑見該目錄 README）
  rules.yaml / ruleset/ / post_sub_clean.sh / …
router-b-gl-mt3000/custom/            # B OpenClash overwrite / rules / rebrickable_nodes
router-b-gl-mt3000/usb-bootstrap/     # 新機 U 盤：僅裝 Zscaler 訂製規則
docs/topology.md
docs/tailscale.md
docs/ops-notes.md
docs/changelog/
backups/snapshot-*
```

## 目前生效的關鍵策略（2026-07-23）

### 訂製規則（A/B 對齊；插在訂閱規則最前）

| RULE-SET / 規則 | 出口 | 說明 |
|-----------------|------|------|
| `Zscaler` | 手动选择 | 單一 classical：域名 + 官方 IP（`ruleset/Zscaler.yaml`） |
| `AppleMedia` | 手动选择 | **同一份**訂閱規則集；前置覆蓋預設的 `AppleMedia→Apple`（Apple 其餘仍可 DIRECT） |
| `MailSMTP` | DIRECT | Gmail / iCloud SMTP、587/465、Google SMTP IP |
| `Rebrickable` | **Rebrickable** 組 | url-test ≈30 個 CF 可用節點（非單一西班牙） |
| `Japan` | **Japan** 組 | `.jp` + `taigatakahashi.com` → 🇯🇵 url-test |
| Firstrade | api3x/streamingx/invest→手动选择；其餘 DIRECT | App CDN 走代理；官網回家寬 IP |
| LinkedIn | `.com`→全球代理；`.cn`→REJECT | hosts / DoH 在 overwrite／user |

訂閱更新會刷新機場主規則；**本地 `rules.yaml` / custom_rules + hook 會再插回最前**，不會被訂閱蓋掉。

### 其它

1. **系統 DNS（A）**：`223.5.5.5` / `119.29.29.29`（`wan-start`）；dnsmasq `filter-AAAA` + Firstrade IPv4 釘選  
2. **IPv6**：A `ipv6_service` 關；B LAN RA/DHCPv6 關、WAN IPv6=0；Clash `dns.ipv6: false`（A 勿在 `user.yaml` 寫頂層 `ipv6: false`）  
3. **Gmail SMTP**：A/B 皆 **DIRECT**（已移除 B 的 `via-RouterA` / `gmail-out`）  
4. **雙重代理**：B 掛 A 後；A `ip_filter` 保持清空。B 側部分客戶端依賴雙層代理，見 changelog  
5. **Tailscale**：A/B 同 Tailnet、無 exit／subnet；見 `docs/tailscale.md`  
6. **ShellCrash**：訂閱走 `update_sub_clean.sh`（104/204）；勿升 1.9.5**beta1**

## 還原提示

- **不要**把完整訂閱 `config.yaml` / `ssLinks.yaml` 直接覆蓋上機；只套用 `custom/`，再重載核心。
- 快照見 `backups/snapshot-*`；還原見該目錄 `README.md`。
- A：改 `yamls/*` 後 `start.sh restart`（會重合併 `rules.yaml`）；或 `PUT /configs?force=true`。
- B：改 `custom/*` 後 `/etc/init.d/openclash restart`（overwrite 注入 runtime）。
- 新 B：`router-b-gl-mt3000/usb-bootstrap/`（僅 Zscaler；完整訂製見 `custom/`）。
