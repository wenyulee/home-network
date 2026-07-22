# 2026-07-23 — LAN 侧停用 IPv6（DNS AAAA）

## 背景

路由 A 的 `ipv6_service` 早已是 `disabled`，但 dnsmasq 仍会返回污染/无用 **AAAA**，客户端 Happy Eyeballs 先试 IPv6 → 变慢（Firstrade 曾见 `2001::…`）。

## 做法

### Router A（Merlin）

- `/jffs/configs/dnsmasq.conf.add` 增加 **`filter-AAAA`**（LAN 解析不再下发 AAAA）。
- Clash `user.yaml`：`dns.ipv6: false`；**不要**写顶层 `ipv6: false`（会与 ShellCrash `set.yaml` 硬编码的 `ipv6: true` 冲突 → `-t` 失败 → 回退成无 DNS 配置）。
- Firstrade 继续 `local=` + IPv4 `address=` 钉选。

### Router B（OpenWrt）

- `dhcp.lan.ra/dhcpv6/ndp=disabled`（LAN 不再发 RA/DHCPv6）。
- `network.wan.ipv6=0`；去掉 `lan.ip6assign` 等。
- OpenClash 原本已 `ipv6_enable=0`；Tailscale 的 IPv6 地址可保留。

## 回滚

- A：从 `dnsmasq.conf.add` 去掉 `filter-AAAA`，`service restart_dnsmasq`；`user.yaml` 里 `dns.ipv6: true` 后 `start.sh restart`。
- B：`uci set dhcp.lan.ra=server; uci set dhcp.lan.dhcpv6=server; uci set network.wan.ipv6=1; uci commit; /etc/init.d/odhcpd restart; /etc/init.d/network reload`。
