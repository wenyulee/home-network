# 2026-07-23 — Firstrade 改走代理

App（api3x / CloudFront HKG）在家用 DIRECT 上 RTT ~250ms+、有丢包；经香港节点测速明显更好。

- A `rules.yaml`：`firstrade.com` / `firstrade.net` → `手动选择`（不再 DIRECT）
- B `custom_rules.list` + `overwrite.sh`：同上
- DNS hosts 钉选保留（干净 IP；经 HK 打 HKG CloudFront 仍合理）

若登录/风控异常，再改回 DIRECT。
