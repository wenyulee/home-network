# 2026-07-22 — LinkedIn 留在 .com（勿进 .cn）

## 原因

国内 DNS 会把 `www.linkedin.com` CNAME 到 `www.linkedin.cn`（Azure 中国 IP，落在 `cn_ip`），直连出口再 302 到中国站。

## 处理（A + B）

1. `nameserver-policy`：`+.linkedin.com` / `+.licdn.com` → Cloudflare DoH  
2. `hosts`：钉 `www.linkedin.com` / `linkedin.com` 国际 IP  
3. 顶层规则：`.com` / `licdn.com` → `全球代理`；`.cn` / `licdn.cn` → `REJECT`

验证：Clash DNS 不再指向 `.cn`；经代理 `https://www.linkedin.com/` 为 200 且无 `Location: …linkedin.cn`。

## 已知限制（暂不处理）

- **仅公司 Mac**（硬体 MAC `84:94:37:d8:d0:36`，常出现 Private Address）上不了国际 LinkedIn。
- 根因：本机 **Zscaler 关不掉**；隧道被 A full-TCP／`10301` 劫持后半残（`*:10301` upload>0 download=0），浏览器对 `.com` 常 `ERR_TIMED_OUT`，随后落到可直连的 `.cn`。
- 路由器与同网其他设备走代理开 `.com` 正常；**不是** A/B 缺 LinkedIn 规则。
- 用户决定：Zscaler 无法关闭前先搁置，不为此再改路由。
