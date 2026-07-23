# 拓樸

```
Internet
   │
GreeNet CPE (192.168.71.1)
   │
Router A WAN 192.168.71.2
Router A LAN 192.168.50.1  ← ShellCrash (Mihomo) API :9999 / mixed :7890
   │
   ├─ 有線客戶端 / A Wi‑Fi
   │
   └─ Router B
        WAN  eth: 192.168.50.180 (metric 1)
        WAN  wifi backup: 192.168.50.174 (metric 2)
        LAN  192.168.8.1  ← OpenClash (Mihomo) API :9090 / mixed :7893
             └─ B 側客戶端
```

## Tailscale

兩台都在線、同 Tailnet（詳見 `docs/tailscale.md`）：

- A：`100.89.102.104`（USB 安裝）
- B：`100.101.186.25`（OpenWrt 套件）
- 未宣告家用 LAN、非 exit node；路由器 `CorpDNS=false`
- 客戶端若開 MagicDNS，本機 DNS 可能優先 `100.100.100.100`（與路由器設定獨立）

## 代理關係

- **A**：全域規則代理；mixed-port `7890`（LAN 需 auth）。
- **B**：獨立訂閱 + 與 A 對齊的訂製 RULE-SET；**不再**使用 `via-RouterA` / `gmail-out`（郵件 SMTP 走 DIRECT）。
- **雙重代理**：B 掛在 A 後時，B 節點流量可能再被 A 透明代理。對部分 B 側客戶端，**需要這層雙重代理才能上大部分網站**；故 A `ip_filter` **不排除** B WAN。少數站失敗應查 B 規則／節點。

## DNS 分工

| 路徑 | 解析器 | 備註 |
|------|--------|------|
| A 系統 / dnsmasq | 223.5.5.5、119.29.29.29 | `filter-AAAA`；Firstrade 等另有 hosts 釘選 |
| A Clash CN policy | 同上 | `rule-set:cn` |
| A/B Firstrade / LinkedIn policy | Cloudflare DoH 等 | 見 `user.yaml` / overwrite |
| B DIRECT + respect-rules | `direct-nameserver` = CF DoH（+ doh.pub） | 未設定時易落到污染系統 DNS |

## 訂製規則 vs 訂閱

- 訂閱更新 → 機場主規則（Netflix、預設 `AppleMedia→Apple` 等）會變。
- 本地 `rules.yaml`（A）/ `openclash_custom_rules.list`（B）+ hook → **每次仍插到最前**。
- 例：前置 `RULE-SET,AppleMedia,手动选择` 壓過訂閱的 `RULE-SET,AppleMedia,Apple`（同一規則集，不同出口）。
