# 2026-07-22 — 恢復 A 對 B WAN 的二次代理排除

## 確認

- 異常客戶端即 B 側 Mac `192.168.8.182`（此前回滾 `ip_filter` 時所稱「另機」）。
- 症狀：`www.linkedin.com` DNS → fake-ip `198.18.x.x`（正常），TCP 到 fake-ip 成功，**TLS handshake 超時** → OpenClash 出口/鏈路問題，而非 DNS 污染。
- 使用者觀察：路徑更依賴 Router A 時，更多網站連不上 → 與 **B 節點流量被 A 透明代理二次轉發** 一致。

## 處置

恢復 Router A `ip_filter`（blacklist）排除 B WAN：

| IP | 角色 |
|----|------|
| `192.168.50.180` | B WAN 有線（metric 1） |
| `192.168.50.174` | B WAN Wi‑Fi 備援（metric 2） |

ShellCrash 對這些 **源 IP** 下 `RETURN`，不再進 A 的透明代理鏈；B 的 OpenClash 節點連線只走一層代理。

Repo：`router-a-asus-merlin/custom/ip_filter`  
裝置：`/jffs/ShellCrash/configs/ip_filter`（改完需重載 ShellCrash 防火牆 / 重啟核心）

## 上機後驗證（在 `192.168.8.182`）

```bash
nslookup www.linkedin.com          # 仍可為 198.18.x.x
curl -vI --max-time 15 https://www.linkedin.com/
# 期望：TLS 完成並有 HTTP 響應；Dashboard 中 linkedin 鏈路不應再疊 A
```

若仍超時：再查 B 當前選中節點（換節點或暫設 `DOMAIN-SUFFIX,linkedin.com,DIRECT`），與二次代理分開處理。
