# Router B USB bootstrap

把 **GL-MT3000（Router B）** 的 OpenClash 定制配置一键装到新机。

## 能装什么 / 不能装什么

| 会装 | 不会自动装 |
|------|------------|
| custom rules / overwrite | OpenClash 本体（需先在 GL Apps 装好） |
| rule-providers：`Zscaler` / `MailSMTP` / `Rebrickable` + `rebrickable_nodes.txt` | Tailscale **登录态**（需 `tailscale up`） |
| OpenClash 主要 UCI（Meta、fake-ip、custom rules、仪表盘密码等） | 机场节点本身（装完后要 Update 一次订阅） |
| 订阅地址（`secrets.env`） | 根密码 / Wi‑Fi SSID / LAN 网段 |
| LAN RA/DHCPv6、WAN IPv6 关闭；Tailscale UCI `enabled=1` | 插上自动执行（需手动跑 `install.sh`） |

## 在 Mac 上准备 U 盘

```bash
cd router-b-gl-mt3000/usb-bootstrap
cp secrets.env.example secrets.env
# 编辑：OPENCLASH_DASHBOARD_PASS、SUB_URL

chmod +x prepare-usb.sh install.sh
./prepare-usb.sh /Volumes/你的U盘名
```

得到：

```
/Volumes/…/router-b-bootstrap/
  install.sh
  secrets.env
  README.md
  payload/
    openclash_custom_overwrite.sh
    openclash_custom_rules.list
    rebrickable_nodes.txt
    Zscaler.yaml  MailSMTP.yaml  Rebrickable.yaml
    uci-tailscale
```

无 U 盘时：`./prepare-usb.sh` → 本目录 `dist/router-b-bootstrap/`。

## 在新 Router B 上执行

1. 装好 OpenClash（`luci-app-openclash`）与 **ruby / ruby-yaml**。
2. 插 U 盘，SSH（默认 `root@192.168.8.1`）。
3. 找挂载点：`ls /tmp/mountd/` 或 `mount | grep -E 'sd|mmc'`。
4. 执行：

```sh
sh /tmp/mountd/disk1_part1/router-b-bootstrap/install.sh
```

5. 装完后：Luci 更新订阅 → `手动选择`→`自动选择`、`Apple`→`DIRECT` → Tailscale 登录。

日志：`/tmp/router-b-bootstrap.log`

## 安全

- `secrets.env` 勿进 git；用完建议删掉或格式化 U 盘。
