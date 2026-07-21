# 2026-07-22 — DNS / Firstrade / 二次代理

## 背景問題

1. 大陸側普通 DNS 對海外域名污染；AliDNS DoH 對 Firstrade / 部分 Google 仍可能污染。
2. Firstrade App 在家用 Wi‑Fi 常無法登入：解析到 Facebook/Twitter IP，或被丟到 HK 節點。
3. Router B 掛在 A 後時，B 的節點流量曾被 A 二次代理。

## 已落地（仍生效）

### Router A

- 系統 DNS → `223.5.5.5` / `119.29.29.29`（`wan-start`）
- Clash：加密 DoH；CN → 國內 DNS；**Firstrade nameserver-policy 僅 Cloudflare `https://1.1.1.1/dns-query`**
- 規則置頂：`DOMAIN-SUFFIX,firstrade.com|net,DIRECT`
- hosts 釘選：`api3x` / `streamingx` / `www` / `invest` / `rec`（CDN 備援）
- 持久化：`post_sub_clean.sh` section `2b` + `rules.yaml`

### Router B

- overwrite：`use-hosts`、`direct-nameserver`（CF DoH）、Firstrade policy 僅 CF、hosts pin、DIRECT 規則
- `respect-rules=true` 時 **必須** 有乾淨 `direct-nameserver`，否則 DIRECT 域名走污染系統 DNS
- custom rules list 同步 Firstrade DIRECT

### 驗證（修復後）

- A/B Clash DNS：Firstrade → AWS CloudFront / Vercel
- HTTPS 對解析 IP：HTTP 200、憑證校驗通過
- App 登入：使用者確認可用（同日稍晚）

## 曾做又回溯

### 排除 B 二次代理（已回滾）

- 曾在 A `/jffs/ShellCrash/configs/ip_filter` 加入 `192.168.50.180`、`192.168.50.174`，使 A 對 B WAN IP RETURN（不進代理鏈）
- **2026-07-22 06:26** 應使用者要求回溯：兩 IP 已刪除，防火牆 RETURN 已無；備份：`ip_filter.before-b-bypass-rollback-20260722-062624`
- 原因：另一台電腦異常，待檢查後再處理二次代理

### 回滾後副作用與修復

- A `start.sh restart` 讓 runtime `direct-nameserver` 一度回到 `127.0.0.1`，Firstrade 再污染
- 以 `yamls/config.yaml` force reload 恢復；並將 Firstrade policy **去掉 doh.pub 競速**（競速曾選到污染答案）
- `post_sub_clean.sh` 已改為與線上一致：Firstrade 僅 CF DoH

## 備份位置（裝置上）

- A：`/jffs/ShellCrash/yamls/backup-firstrade-20260722-061302/`
- B：`/etc/openclash/backup/firstrade-20260722-061303/`

## 待辦

- [x] 另機問題查清後，再決定是否恢復 A 對 B WAN 的 `ip_filter` 排除 → **否**（機為 `192.168.8.182`，雙層代理才能上大部分站；見 `2026-07-22-b-double-proxy-keep.md`）
- [ ] （可選）hosts CDN IP 定期用 CF DoH 刷新
- [ ] 訂閱 04:00 更新若 `-t` 失敗仍依 post_sub 還原 bak；觀察是否穩定
