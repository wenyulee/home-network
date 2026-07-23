# 2026-07-23 — Zscaler 全量 IP 强制代理

## 能否识别？

可以。`165.225.116.23` 属 **AS53813 ZSCALER**，落在官方 Cloud Enforcement 聚合段 **`165.225.0.0/17`**。

官方机器可读来源（`config.zscaler.com`）：

- 各 cloud 的 **CENR**（enforcement nodes）
- **Hubs** required/recommended CIDR
- **ZPA** allow list

合并折叠后约 **800** 条 IPv4 CIDR（+少量 IPv6）。

## 实现

- Rule-provider：`behavior: ipcidr` → `ruleset/Zscaler.yaml`
- 规则：`RULE-SET,Zscaler,手动选择,no-resolve`
- 域名兜底：`zscaler.com` / `zscaler.net` / `zscloud.net` / `zscaler{one,two,three}.net` / `zpath.net`
- 订阅更新时 best-effort 刷新 IP 表（`update_zscaler_ruleset.sh`）

A：`post_sub_clean` 注入 `rule-providers.Zscaler`（勿用 `others.yaml`，会与订阅重复键）；B：overwrite 注册 + `rule_provider/Zscaler.yaml`。
