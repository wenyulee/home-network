# 運維備註（歷史對話補遺）

與拓樸／changelog 互補：對話裡反覆碰到、但容易忘的操作知識。

## Clash Dashboard ≠ 路由器 LAN IP

- LAN 閘道：A `192.168.50.1`、B `192.168.8.1`
- Clash External Controller：A `:9999`、B `:9090`（服務綁定位址，可與閘道同機但概念不同）
- 能開 `http://192.168.50.1:9999/ui/` 代表 **ShellCrash 跑在 A 上**，不是「後端必須等於 50.1」的特例

## 訂閱假節點

供應商常插入名稱含 `Expire:` / `Traffic:` / `Sync:` 的佔位節點，可能進「自动选择」害選路異常。

- A：`post_sub_clean.sh` awk 剔除
- B：`openclash_custom_overwrite.sh` 從 proxies／groups 剔除

排障「代理很慢／選到怪節點」時先確認沒被假節點污染。

## 郵件、Rebrickable 與 AI

| 流量 | 策略 | 原因（對話脈絡） |
|------|------|------------------|
| 多數 SMTP（587/465、iCloud／Purelymail／Gmail 等）+ Purelymail IMAP | `RULE-SET,Mail,DIRECT` | 避免代理干擾寄信收信；IMAP 是 2026-07-24 補的，之前只擋了 SMTP 587/465，`imap.purelymail.com` 一直漏到漏网之鱼 |
| Rebrickable | Rebrickable url-test 組 | 站點／區鎖需求 |
| Japan（`.jp` + taigatakahashi.com） | Japan url-test 組 | 見 README「目前生效的關鍵策略」 |
| Claude/claudeusercontent、Cursor/cursorapi、Gemini | `RULE-SET,AI,Ai+` | 訂閱 `OpenAI.yaml`/`Google.yaml` 沒涵蓋或分錯組；透過實測 B 的 `漏网之鱼` 連線統計抓出 `cursorapi.com`、A 即時連線抓出 `claudeusercontent.com` 這兩個當初漏掉的網域 |

規則在 A `rules.yaml`、B `openclash_custom_rules.list` + overwrite；改訂閱後靠腳本重插最前。`Mail`/`AI` 都是獨立的 classical rule-provider 檔案（`ruleset/Mail.yaml`、`ruleset/AI.yaml`），跟 Zscaler/Rebrickable/Japan 同一套模式，不是寫死在規則清單裡的 inline domain。

> 舊版 B 曾用 `gmail-out` → `via-RouterA`（經 A mixed-port 出站）處理 Gmail SMTP；已於 2026-07-23 移除，overwrite 現在會主動清掉任何殘留的 `gmail-out`/`via-RouterA`，郵件一律走上表的 `Mail` → DIRECT。

## 為何當初只有 A 有「國內 DNS 病」

A 問題鏈（已修）：

```text
rule-set:cn / DIRECT
  → direct-nameserver: 127.0.0.1
  → dnsmasq
  → WAN DNS 曾是 1.1.1.1 / 8.8.8.8
  → 百度等解析成海外 IP
  → 再走慢的國際直連
```

B 本來就沒把 `direct-nameserver` 指回這條污染鏈，所以沒表現出同一症狀。  
後來 B 在 `respect-rules` + Firstrade DIRECT 時另需乾淨 `direct-nameserver`（見 Firstrade changelog）。

## Router A 運維坑

1. **dnsmasq 上游**以 `/tmp/resolv.dnsmasq` 為準（常配合 `no-resolv`）；只改 `resolv.conf`／nvram 不夠時查這個檔。持久化靠 `wan-start`（國內 `223.5.5.5` / `119.29.29.29`）。
2. **Clash DNS 勿只靠 API reload**：`start.sh restart` 會用 `clash_modify.sh` 重拼配置；未設 `dns_nameserver` 且本機有 dnsmasq 時會把 `direct-nameserver` 寫成 `127.0.0.1`。持久化用 **`yamls/user.yaml`（含 `dns:`）+ `ShellCrash.cfg` 的 `dns_nameserver`**，見 `docs/changelog/2026-07-22-a-dns-persist.md`。
3. **改完 yamls 優先 API reload** 可立刻生效，但仍須有上面的 user.yaml／cfg，否則下次重啟又退回。
4. **USB `sda1`**  
   - Tailscale binary + state  
   - `shellcrash-usb-offload`（post-mount）  
   - `post_sub` 可選備份目錄 `/tmp/mnt/sda1/shellcrash-backup`  
   拔盤或掛載失敗會影響上述服務。
5. **LAN mixed-port auth**  
   B 的 `via-RouterA` socks5 依賴 A `7890` 帳密；腳本裡 repo 為 `REDACTED_*`，上機需與真值一致。

## Firstrade DIRECT 取捨（摘要）

- 優：出口＝家用公網 IP，較符合券商風控預期；避開污染 DNS + 亂跳代理節點  
- 劣：吃 ISP 國際直連品質；DoH／hosts 釘選需維護；CDN IP 輪換時 hosts 可能過期（DoH 仍可救）

## 仍待決策

- ~~是否恢復 A 對 B WAN（`.180` / `.174`）的二次代理排除~~ → **否**（`192.168.8.182` 需雙層代理；見 `docs/changelog/2026-07-22-b-double-proxy-keep.md`）
- hosts CDN 是否做定期刷新  
- 訂閱定時更新 `-t` 失敗 → 還原 bak 是否長期穩定  
- LinkedIn：路由器代理开 `.com` 正常；**仅公司 Mac** 因 Zscaler 关不掉而挂（timeout → `.cn`）→ **暂搁置**，见 `docs/changelog/2026-07-22-linkedin-keep-com.md`  
