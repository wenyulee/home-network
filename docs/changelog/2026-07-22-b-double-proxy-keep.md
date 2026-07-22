# 2026-07-22 — B 側客戶端與二次代理（更正）

## 確認（因果與先前假設相反）

- 異常／討論中的客戶端：B 側 Mac `192.168.8.182`。
- **雙層代理（A 未排除 B WAN，B 節點流量再經 A）時，此機才能連上大部分網站。**
- 因此：**不要**為了「消除二次代理」而恢復 A `ip_filter` 對 `192.168.50.180` / `.174` 的排除；那會讓此機大面積失敗（此即 2026-07-22 06:26 回滾 `ip_filter` 的真實原因）。

## LinkedIn 等少數站仍失敗（與二次代理分開）

在**目前雙層代理仍開啟**、大部分站可用的前提下：

```text
nslookup www.linkedin.com  →  198.18.x.x   (fake-ip，正常)
curl https://www.linkedin.com/  →  TCP 到 fake-ip OK，TLS handshake 超時
```

含義：Mac→OpenClash 劫持正常；**當前選中的出口／規則**到不了 LinkedIn（節點被攔、超時、或規則把流量丟到錯誤組），不是「缺 ip_filter」。

> **2026-07-22 更新**：公司 Mac 上 LinkedIn 實為 **Zscaler 關不掉**（timeout → `.cn`）；路由器與其他設備 `.com` 正常。**暫搁置**，見 `2026-07-22-linkedin-keep-com.md`。

### 建議下一步（Router B / 客戶端）

1. OpenClash Dashboard 打開 `linkedin.com` 連接，記下 **Rule + Proxy chain**。
2. 手動切 **DIRECT** 或換一個已知可用節點再 `curl -vI --max-time 15 https://www.linkedin.com/`。
3. 若 DIRECT 或特定地區節點可通：在 B `custom` 加頂部規則，例如  
   `DOMAIN-SUFFIX,linkedin.com,<可用策略>`（及 `licdn.com` 如需），與 Firstrade 訂製同層持久化。
4. **維持** A `ip_filter` 為空（或至少不要排除 B WAN），除非另有不依賴雙層代理的客戶端方案。

## 狀態

- A `ip_filter`：保持清空（回滾後狀態），**不恢復** B WAN 排除。
- 待辦「另機查清後是否恢復 ip_filter」：**結論為否（對 192.168.8.182）**。
