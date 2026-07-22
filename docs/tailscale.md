# Tailscale

兩台路由器都加入同一 Tailnet（帳號 `wenyulee51@`），**不是 exit node、未宣告 subnet routes、未開 Accept DNS（CorpDNS）**。版本均為 **1.98.9**。

| 節點 | Tailscale IPv4 | DNS 名稱 | 安裝方式 |
|------|----------------|----------|----------|
| Router A `rt-ax86u-pro-22b0` | `100.89.102.104` | `rt-ax86u-pro-22b0.tailb93280.ts.net` | USB `/tmp/mnt/sda1/tailscale` + `/jffs/tailscale/start.sh` |
| Router B `gl-mt3000` | `100.101.186.25` | （同 tailnet） | OpenWrt 套件 `/usr/sbin/tailscaled` |

其他曾見過的裝置：`iphone-14-pro-max`、`patagonia`（macOS）。

## 共同偏好（兩台 prefs）

- `WantRunning: true`
- `RouteAll: false`（不用別人當 exit）
- `AdvertiseRoutes: null`（不把家用 LAN 廣播進 Tailnet）
- `ExitNode*:` 空
- `CorpDNS: false`（**路由器本身不接受 MagicDNS**）
- `RunSSH: false`
- UDP port **41641**
- Control：`https://controlplane.tailscale.com`
- AutoUpdate：Check + Apply

state / node key **不入库**（A：`…/state/tailscaled.state`；B：`/etc/tailscale/tailscaled.state`）。

## Router A 啟動鏈

1. USB 掛載後跑 `/jffs/scripts/post-mount`
2. 呼叫 `/jffs/tailscale/start.sh`
3. 等待 USB 上的 `tailscaled`，再以  
   `--state=/tmp/mnt/sda1/tailscale/state/tailscaled.state`  
   `--socket=/var/run/tailscale/tailscaled.sock`  
   `--port=41641` 啟動

對應檔案：`router-a-asus-merlin/custom/tailscale/`。

**注意：** binary 與 state 在 USB。拔掉 `sda1` 或掛載失敗時 Tailscale 起不來；`start.sh` 最多等約 60 秒。

## Router B

- UCI：`/etc/config/tailscale`（repo：`router-b-gl-mt3000/custom/tailscale/uci-tailscale`）
- `enabled=1`，`state_file=/etc/tailscale/tailscaled.state`，`port=41641`
- 服務：`/etc/init.d/tailscale`

## 歷史對話重點（2026-07-21 排查）

排查「家裡變慢 / Apple 打不開」時與 Tailscale 相關的結論：

1. **Mac 開著 Tailscale 時，DNS 可能優先走 `100.100.100.100`（MagicDNS）**  
   當時懷疑這會讓部分站（如 Apple）解析異常；與路由器 `CorpDNS: false` 是兩件事——客戶端自己的 Tailscale 仍可能接管 DNS。
2. 使用者關閉 Mac Tailscale 後重測：閘道／DNS 回到區網路由器，**慢的主因仍在 A 上游國際直連（GreeNet CPE / ISP）**，不是 Tailscale，也不是 ShellCrash。
3. 因此：排障時若 DNS 怪異，先確認客戶端是否開著 Tailscale / MagicDNS，再查 Clash DNS。

## 與 Clash 的關係

- Tailscale 流量走各自 TUN；未設定成把 LAN 或全站導出 exit node。
- Clash fake-ip（A `28.0.0.0/8`，B `198.18.0.1/16`）與 Tailscale `100.x` 不同網段，一般不衝突。
- 遠端用 Tailscale 連回家管理路由器時，用上表 `100.x` 即可；Clash Dashboard 仍是各機 LAN / API port（A `:9999`，B `:9090`）。

## 還原／維護

- **不要**把 `tailscaled.state` 提交進 git。
- A 重裝後：放回 USB binary + state，確保 `post-mount` 會呼叫 `start.sh`，再 `tailscale up`（若 state 還在通常會自動登入）。
- B：`opkg`／GL 套件裝好後 `uci set tailscale.settings.enabled=1` 並保留 state，或重新 auth。
