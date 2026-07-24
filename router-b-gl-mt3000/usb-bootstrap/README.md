# Router B USB bootstrap — Zscaler only

新机只装 **Zscaler** 订制规则（classical 规则集 + `RULE-SET,Zscaler,手动选择`）。  
不包含 MailSMTP / Rebrickable / Japan / Firstrade / LinkedIn / Tailscale 等其它订制。

## 会装 / 不会装

| 会装 | 不会装 |
|------|--------|
| `Zscaler.yaml` → `/etc/openclash/rule_provider/` | 其它 RULE-SET / 策略组 |
| 仅含 Zscaler 的 `custom_rules.list` + 最小 overwrite | 完整 home-network 规则包 |
| `enable_custom_clash_rules` 等必要 UCI | Tailscale、IPv6 策略 |
| 可选：`SUB_URL` / 仪表盘密码（`secrets.env`） | OpenClash 本体（需先装好） |

完整 A/B 订制仍以 repo `custom/` 为准，需 SSH 手动同步。

## Mac 准备 U 盘

```bash
cd router-b-gl-mt3000/usb-bootstrap
# 可选：cp secrets.env.example secrets.env 再填 SUB_URL
chmod +x prepare-usb.sh install.sh
./prepare-usb.sh /Volumes/你的U盘名
```

得到：

```
…/router-b-bootstrap/
  install.sh
  README.md
  secrets.env.example
  payload/
    openclash_custom_rules.list   # Zscaler only
    openclash_custom_overwrite.sh # inject Zscaler provider
    Zscaler.yaml
```

## 在路由器上

1. 装好 OpenClash + ruby / ruby-yaml  
2. SSH 执行：`sh /tmp/mountd/disk1_part1/router-b-bootstrap/install.sh`  
3. Luci 更新订阅；确认 Rules 有 `RULE-SET,Zscaler → 手动选择`

日志：`/tmp/router-b-bootstrap.log`
