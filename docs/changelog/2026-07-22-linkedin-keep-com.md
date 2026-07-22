# 2026-07-22 — LinkedIn 留在 .com（勿进 .cn）

## 原因

国内 DNS 会把 `www.linkedin.com` CNAME 到 `www.linkedin.cn`（Azure 中国 IP，落在 `cn_ip`），直连出口再 302 到中国站。

## 处理（A + B）

1. `nameserver-policy`：`+.linkedin.com` / `+.licdn.com` → Cloudflare DoH  
2. `hosts`：钉 `www.linkedin.com` / `linkedin.com` 国际 IP  
3. 顶层规则：`.com` / `licdn.com` → `全球代理`；`.cn` / `licdn.cn` → `REJECT`

验证：Clash DNS 不再指向 `.cn`；经代理 `https://www.linkedin.com/` 为 200 且无 `Location: …linkedin.cn`。
