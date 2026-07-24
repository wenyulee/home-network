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
router-b-gl-mt3000/usb-bootstrap/     # 新機 U 盤一鍵安裝
docs/topology.md
docs/tailscale.md
docs/ops-notes.md
docs/changelog/
backups/snapshot-*
```

## 目前生效的關鍵策略（2026-07-24）

### 訂製規則（A/B 對齊；插在訂閱規則最前）

| RULE-SET / 規則 | 出口 | 說明 |
|-----------------|------|------|
| `Zscaler` | 手动选择 | 單一 classical：域名 + 官方 IP（`ruleset/Zscaler.yaml`） |
| `AppleMedia` | 手动选择 | **同一份**訂閱規則集；前置覆蓋預設的 `AppleMedia→Apple`（Apple 其餘仍可 DIRECT） |
| `Mail` | DIRECT | Gmail / iCloud / Purelymail SMTP（587/465）+ IMAP（`imap.purelymail.com`）、Google SMTP IP |
| `Rebrickable` | **Rebrickable** 組 | url-test ≈30 個 CF 可用節點（非單一西班牙） |
| `Japan` | **Japan** 組 | `.jp` + `taigatakahashi.com` → 🇯🇵 url-test |
| Firstrade | api3x/streamingx/invest→手动选择；其餘 DIRECT | App CDN 走代理；官網回家寬 IP |
| LinkedIn | `.com`→全球代理；`.cn`→REJECT | hosts / DoH 在 overwrite／user |
| `AI` | **Ai+** 組 | `ruleset/AI.yaml`：Claude/claudeusercontent、Cursor/cursorapi、Gemini 等訂閱 `OpenAI.yaml`/`Google.yaml` 沒涵蓋或分錯組的網域；ChatGPT/Codex 已靠訂閱 `OpenAI.yaml` 涵蓋，不用另加 |

訂閱更新會刷新機場主規則；**本地 `rules.yaml` / custom_rules + hook 會再插回最前**，不會被訂閱蓋掉。

### 其它

1. **系統 DNS（A）**：`223.5.5.5` / `119.29.29.29`（`wan-start`）；dnsmasq `filter-AAAA` + Firstrade IPv4 釘選  
2. **IPv6**：A `ipv6_service` 關；B LAN RA/DHCPv6 關、WAN IPv6=0；Clash `dns.ipv6: false`（A 勿在 `user.yaml` 寫頂層 `ipv6: false`）  
3. **Gmail SMTP**：A/B 皆 **DIRECT**（已移除 B 的 `via-RouterA` / `gmail-out`）  
4. **雙重代理**：B 掛 A 後；A `ip_filter` 保持清空。B 側部分客戶端依賴雙層代理，見 changelog  
5. **Tailscale**：A/B 同 Tailnet、無 exit／subnet；見 `docs/tailscale.md`  
6. **ShellCrash**：訂閱走 `update_sub_clean.sh`（104/204）；勿升 1.9.5**beta1**
7. **Zscaler IP 表**：A（隨每日訂閱更新）與 B（獨立 cron `55 3 * * *`，不依賴 A 在線，適合 B 帶出門）各自更新；IPv4 CIDR 經 containment dedup 壓縮（~2500→~800 條，覆蓋範圍不變）
8. **A 連線紀錄**：ShellCrash 原廠啟動腳本把 CrashCore 的 log 導去 `/dev/null`；`custom/log_capture.sh`（掛在 `task-afstart`，接 Mihomo `/logs` API）另外把它存到 `/tmp/ShellCrash/traffic.log`，讓 A 也能像 B 的 `/tmp/openclash.log` 一樣查歷史連線

## 還原提示

- **不要**把完整訂閱 `config.yaml` / `ssLinks.yaml` 直接覆蓋上機；只套用 `custom/`，再重載核心。
- 快照見 `backups/snapshot-*`；還原見該目錄 `README.md`。
- 改「規則清單」（A `rules.yaml` / B `openclash_custom_rules.list`）**只能**靠重啟才會重新合併——A `start.sh restart`、B `/etc/init.d/openclash restart`。A 的 `PUT /configs?force=true` 只是叫核心重讀當下的 runtime config，**不會**觸發 `rules.yaml` 合併，對規則清單改動沒用（2026-07-24 實測確認）。
- A／B 皆同：`ruleset/*.yaml` 這類 **rule-provider 檔案**（Zscaler/Mail/Rebrickable/Japan/AI）改了**不用重啟**，Mihomo 核心會依檔案 mtime 自動重讀，兩邊都實測驗證過。
- 新 B：`router-b-gl-mt3000/usb-bootstrap/`。
