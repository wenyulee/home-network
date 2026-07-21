# 拓樸

```
Internet
   │
GreeNet CPE (192.168.71.1)
   │
Router A WAN 192.168.71.2
Router A LAN 192.168.50.1  ← ShellCrash (Mihomo)
   │
   ├─ 有線客戶端 / A Wi‑Fi（例：Firstrade 裝置曾見 192.168.50.207）
   │
   └─ Router B
        WAN  eth: 192.168.50.180 (metric 1)
        WAN  wifi backup: 192.168.50.174 (metric 2)
        LAN  192.168.8.1  ← OpenClash (Mihomo)
             └─ B 側客戶端（例：Mac 192.168.8.242）
```

## 代理關係

- **A**：全域規則代理；mixed-port `7890`（LAN 需 auth，供 B `via-RouterA` socks5 使用）。
- **B**：獨立訂閱節點；另有 `via-RouterA` → A:7890，用於 `gmail-out` fallback。
- **雙重代理風險**：B 的節點連線源 IP 若再被 A 透明代理，會疊加延遲/異常。A `ip_filter` blacklist 排除 B WAN `192.168.50.180` / `.174`（`RETURN` 不進代理鏈）。曾短暫回滾，確認異常機為 `192.168.8.182` 後已恢復。

## DNS 分工

| 路徑 | 解析器 | 備註 |
|------|--------|------|
| A 系統 / dnsmasq | 223.5.5.5、119.29.29.29 | 避免路由器本機走 1.1.1.1/8.8.8.8 |
| A Clash CN policy | 同上 | `rule-set:cn` |
| A/B Firstrade policy | **僅** Cloudflare DoH `https://1.1.1.1/dns-query` | AliDNS / 部分 doh.pub 在此網路會污染 Firstrade |
| B DIRECT + respect-rules | `direct-nameserver` = CF DoH（+ doh.pub 備援） | 未設定時會落到污染系統 DNS |
