# backups/

帶時間戳的**整機訂製快照**，方便升級／訂閱更新後對比或還原。

日常仍以各路由目錄下的 `custom/` 為準；快照多了 runtime 摘要與校驗雜湊。

```
backups/
  snapshot-YYYY-MM-DD-HHMM/
    README.md          # 該快照說明與還原表
    manifest/          # sha256
    router-a/          # A 訂製 + 脫敏 runtime
    router-b/          # B 訂製 + 脫敏 runtime
  local-raw/           # （可選）本機未入 git 的明文全量，見 .gitignore
```

新建快照時：從裝置 `scp` 訂製檔，脫敏後再 commit；完整含密碼的 runtime 勿入庫。
