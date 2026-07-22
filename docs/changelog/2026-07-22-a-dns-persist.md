# 2026-07-22 — A runtime DNS 持久化

## 根因

ShellCrash `mix` 模式在每次 `start`／`restart` 时由 `starts/clash_modify.sh` 生成 `dns.yaml`：

1. `libs/get_config.sh`：若 `dns_nameserver` **未配置**，且本机 `127.0.0.1:53`（dnsmasq）在听 → 自动设为 `127.0.0.1`
2. 于是 `direct-nameserver` / `nameserver-policy: rule-set:cn` 被写成 `127.0.0.1`
3. 只改 `yamls/config.yaml` 或 API reload **挡不住下次 restart**（会重新拼装配置）

## 持久化做法（两层）

### 1. `ShellCrash.cfg`（兜底，阻止回落到 127.0.0.1）

```sh
dns_nameserver='223.5.5.5, 119.29.29.29'
dns_fallback='https://1.1.1.1/dns-query, https://doh.pub/dns-query'
dns_resolver='223.5.5.5, 2400:3200::1'
```

有显式 `dns_nameserver` 时，`get_config.sh` **不会**再因 dnsmasq 改成 `127.0.0.1`。

### 2. `yamls/user.yaml`（官方覆盖，推荐）

`clash_modify.sh`：若 `user.yaml` 含顶层 `dns:`，**跳过**自动生成的 `dns.yaml`。  
同理有 `hosts:` 则跳过自动 hosts。

当前 `user.yaml` 含：

- Firstrade hosts 钉选
- `direct-nameserver` / `nameserver` → Cloudflare DoH（+ doh.pub 备援）
- CN policy → `223.5.5.5` / `119.29.29.29`
- Firstrade policy → **仅** `https://1.1.1.1/dns-query`
- 完整 `fake-ip-filter`（来自 `configs/fake_ip_filter.list`）+ `rule-set:cn`

## 验证

连续两次 `start.sh restart` 后 runtime 仍为 CF DoH / 国内 CN policy，**无** `direct-nameserver: [ 127.0.0.1 ]`；百度与 Firstrade 解析正常。

## 注意

- 升级 ShellCrash 后检查 `user.yaml` 是否仍在；`fake_ip_filter.list` 若大变，可按 list 重生成 `user.yaml` 的 filter 段。
- `post_sub_clean.sh` 仍 harden **订阅** `yamls/config.yaml`；真正防 restart 回退靠 **user.yaml + cfg**。
