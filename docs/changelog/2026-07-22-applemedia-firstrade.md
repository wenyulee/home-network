# 2026-07-22 — AppleMedia 走代理；Firstrade DNS 钉选

## Apple TV+

- **只需 `AppleMedia`**（含 `tv.apple.com`、`play-edge.itunes.apple.com`、Music/News 等），与 Netflix/Disney+ 同类。
- **不要**整组 `Apple`（含 iCloud / `apple.com` / App Store）长期走代理，内地服务易变差。
- 实现：自定义规则顶层 `RULE-SET,AppleMedia,手动选择`；策略组 `Apple` 保持 **DIRECT**（Firmware/Dev/Hardware/通用 Apple）。

## Firstrade 变慢

- 系统 dnsmasq 曾把 `www.firstrade.com` 解析成错误 IP（甚至 Facebook 段）；Clash hosts/DoH 正常。
- 已加 `/jffs/configs/dnsmasq.conf.add` 钉选主域名 IPv4。
- 仍保持 `DIRECT`（家用出口 IP）；若偶发 CloudFront 慢属 ISP 抖动，可再议是否改走代理。
