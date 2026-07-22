# 2026-07-21〜22 — 排查結論摘要（歷史對話）

從同日對話整理、與設定變更對照。細節指令以各 custom 檔與 Firstrade changelog 為準。

## 拓樸認知

- **Router A** `192.168.50.1`：Merlin + ShellCrash；WAN `192.168.71.2` → GreeNet CPE `192.168.71.1`
- **Router B** `192.168.8.1`：OpenWrt + OpenClash；WAN 有線 `192.168.50.180`（主）、Wi‑Fi `192.168.50.174`（備援）
- Mac 有時在 **B** 網段，不能把 Mac 測速直接當成 A 的問題

## 速度慢（07-21）

| 結論 | 說明 |
|------|------|
| 非 ShellCrash / 非假節點 | 代理可選到真實 HK 節點，延遲正常 |
| **非 Tailscale（主因）** | 關 Mac Tailscale 後仍慢；主因是 A **上游國際直連**偏慢（測過約 1–4Mbps 級） |
| Tailscale 副作用 | Mac 開著時 DNS 可能優先 `100.100.100.100`，干擾本機解析排查 |
| B 體感較好 | 同晚 B 側下載約 ~99Mbps；Wi‑Fi 到 B 延遲也優於到 A |
| 次要 | Mac↔A Wi‑Fi 抖動偏大 |

## DNS（07-21〜22）

- A 曾：`direct-nameserver → 127.0.0.1` → dnsmasq → WAN `1.1.1.1/8.8.8.8` → 國內站解析成海外 IP → 直連極慢
- 已改：系統／dnsmasq 與 CN policy → `223.5.5.5` / `119.29.29.29`（`wan-start` 持久化）
- Merlin 真正生效的常是 `/tmp/resolv.dnsmasq`（`no-resolv` + servers-file），不是只看 `resolv.conf`
- **AliDNS DoH 在此網路仍可能污染 Firstrade**；Firstrade 最終只信 Cloudflare DoH `1.1.1.1`
- B `respect-rules` + DIRECT 必須配乾淨 `direct-nameserver`，否則吃污染系統 DNS

## Firstrade（07-22）

- 根因：域名污染 + 曾走 HK 代理；修法 DIRECT + CF DoH + hosts 釘選
- 見 `2026-07-22-firstrade-and-dns.md`

## 二次代理 B→A（07-22）

- 曾用 A `ip_filter` 排除 `192.168.50.180/174`
- **已回溯**（另一台電腦異常）；待查清後再處理

## Tailscale 現況快照

- 見 `docs/tailscale.md`：兩台在線、無 subnet / exit、路由器 CorpDNS=false

## 運維補遺

- Dashboard port、假節點、郵件／Rebrickable、A dnsmasq／reload／USB 等：見 `docs/ops-notes.md`
