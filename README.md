# home-network

家用雙路由拓樸與 Clash / OpenClash **訂製設定**備份（不含訂閱節點全文與機密）。

| 裝置 | 角色 | LAN | 代理 |
|------|------|-----|------|
| **Router A** ASUS RT-AX86U Pro (Merlin) | 主路由 / WAN→GreeNet CPE | `192.168.50.1` | ShellCrash / Mihomo `:9999`，mixed `7890` |
| **Router B** GL-MT3000 (OpenWrt) | 二層 AP/路由 | `192.168.8.1` | OpenClash / Mihomo `:9090` |
| B WAN | 有線 + Wi‑Fi 備援掛在 A 後 | `192.168.50.180`（metric 1）、`192.168.50.174`（metric 2） | |

機密請用本機 `secrets.example` 對照裝置上的真實值；repo 內密碼已改為 `REDACTED_*`。

## 目錄

```
router-a-asus-merlin/custom/     # A 訂製腳本與規則（上機路徑見該目錄 README）
router-a-asus-merlin/snippets/   # 從 runtime 擷取的 DNS / hosts 片段
router-b-gl-mt3000/custom/       # B OpenClash custom overwrite / rules
router-b-gl-mt3000/snippets/     # B runtime DNS / hosts / 規則前綴
docs/topology.md
docs/changelog/                  # 變更紀錄
```

## 目前生效的關鍵策略（2026-07-22）

1. **系統 DNS（A）**：`223.5.5.5` / `119.29.29.29`（`wan-start` 持久化）
2. **Firstrade**：`DOMAIN-SUFFIX` → `DIRECT`；DNS 僅 `https://1.1.1.1/dns-query`；hosts 釘選主要 CDN IP（備援）
3. **B `respect-rules`**：需乾淨 `direct-nameserver`（CF DoH），否則 DIRECT 域名會吃到污染解析
4. **B 二次代理**：對 B 側 `192.168.8.182`，**雙層代理時大部分站才可連**；A `ip_filter` 保持清空（不排除 B WAN）。少數站（如 LinkedIn）另查 B 出口／規則，見 `docs/changelog/2026-07-22-b-double-proxy-keep.md`

## 還原提示

- **不要**把完整訂閱 `config.yaml` / `ssLinks.yaml` 直接覆蓋上機；只套用 `custom/` 內檔案，再重載/重啟代理核心。
- A：改 `yamls/*` 後優先 `PUT /configs?force=true` 載入 `/jffs/ShellCrash/yamls/config.yaml`；全量 `start.sh restart` 可能用訂閱管線覆寫 runtime。
- B：改 `custom/*` 後 `/etc/init.d/openclash restart`，由 overwrite 注入 runtime。
