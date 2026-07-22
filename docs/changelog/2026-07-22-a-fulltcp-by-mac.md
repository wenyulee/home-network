# 2026-07-22 — A 上按 MAC 全 TCP 劫持（对齐 B）

## 目的

Router B 对几乎所有 TCP 做透明代理，会劫持本机企业隧道（如 Zscaler `*:10301`），使公司 proxy 失效。  
Router A 默认只劫持常用端口，企业隧道可直通。  

在 **A** 上对指定电脑补上与 B 等价的 **全 TCP → shellcrash**，用 **MAC** 识别（DHCP IP 会变）。

## 识别

| 项 | 值 |
|----|-----|
| 曾用 IP（B 侧） | `192.168.8.182`（动态，勿写死） |
| MAC | `2a:f6:ff:17:72:89` |
| DHCP hostname | `Mac` |

## 上机文件

| 路径 | 作用 |
|------|------|
| `/jffs/ShellCrash/configs/fulltcp_mac.list` | MAC 列表 |
| `/jffs/ShellCrash/scripts/fulltcp_by_mac.sh` | 安装 `shellcrash_fulltcp_mac` 链 |
| `/jffs/ShellCrash/task/afstart` | 启动后调用上述脚本 |

规则形态：

```text
PREROUTING -p tcp → shellcrash_fulltcp_mac
  └ mac 2A:F6:FF:17:72:89 → shellcrash（其后仍走 cn_ip RETURN 等）
  └ 其他 MAC → RETURN（再落到原来的 multiport 规则）
```

## 重要限制

- **仅当该机连在 A 的 Wi‑Fi／有线 LAN** 时，A 才能看到客户 MAC。  
- 若机子仍在 **B 后面**，A 上源 MAC 是 B 的 WAN，此规则**无效**；此时全 TCP 劫持本来就在 B 上完成。  
- 要在 A 上复现「打断企业 VPN」：请把该 Mac **改连 A 的 Wi‑Fi**，再测 `10301` 是否进 ShellCrash。

## 合规

此举会干扰企业 VPN／proxy，仅按用户要求配置；使用须自担合规风险。
